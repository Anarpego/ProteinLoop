defmodule ProteinLoopWeb.ProducerLive do
  use ProteinLoopWeb, :live_view

  alias ProteinLoop.Agent.ApprovalQueue
  alias ProteinLoop.Offline.EmergencyRules
  alias ProteinLoop.ProducerMessage
  alias ProteinLoop.SimulatorClient
  alias ProteinLoop.SimulatorPoller

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      SimulatorPoller.subscribe()
      ApprovalQueue.subscribe()
    end

    snapshot = SimulatorPoller.snapshot_now("producer_mount")
    approval_queue = ApprovalQueue.snapshot()
    action = producer_action(approval_queue, snapshot.state)

    socket =
      socket
      |> assign(:page_title, "Productor")
      |> assign(:snapshot, snapshot)
      |> assign(:state, snapshot.state)
      |> assign(:approval_queue, approval_queue)
      |> assign(:action, action)
      |> assign(:offline_guidance, EmergencyRules.evaluate(snapshot.state))
      |> assign(:producer_message, ProducerMessage.build(snapshot.state, action, approval_queue))
      |> assign(:decision, nil)

    {:ok, socket}
  end

  @impl true
  def handle_info({:simulator_snapshot, snapshot}, socket) do
    {:noreply, assign_snapshot(socket, snapshot)}
  end

  def handle_info({:approval_queue, approval_queue}, socket) do
    {:noreply,
     socket
     |> assign(:approval_queue, approval_queue)
     |> assign(:action, producer_action(approval_queue, socket.assigns.state))}
  end

  @impl true
  def handle_event("approve", _params, socket) do
    socket =
      case socket.assigns.approval_queue.pending do
        nil ->
          apply_routine_action(socket)

        pending ->
          apply_pending_action(socket, pending, pending.action, :approved, "Accion aprobada")
      end

    {:noreply, socket}
  end

  def handle_event("reject", _params, socket) do
    socket =
      case socket.assigns.approval_queue.pending do
        nil ->
          assign(socket, :decision, "Accion rechazada")

        pending ->
          reject_pending_action(socket, pending)
      end

    {:noreply, socket}
  end

  def handle_event("half", _params, socket) do
    socket =
      case socket.assigns.approval_queue.pending do
        nil ->
          edited =
            socket.assigns.action
            |> Map.update!("feed_kg", &(&1 / 2))
            |> Map.put("note", "producer_half_feed")

          apply_step(socket, edited, "Accion editada", "producer_edit")

        pending ->
          edited = ApprovalQueue.half_action(pending.action)
          apply_pending_action(socket, pending, edited, :edited, "Accion editada")
      end

    {:noreply, socket}
  end

  defp apply_routine_action(socket) do
    case SimulatorClient.safety_step() do
      {:ok, %{"state" => state, "reward" => reward}} ->
        snapshot = %{
          connected?: true,
          source: "producer_approval",
          state: state,
          reward: reward,
          error: nil
        }

        socket
        |> assign_snapshot(snapshot)
        |> assign(:decision, "Accion aprobada")

      {:error, reason} ->
        socket
        |> put_flash(:error, "No se pudo aplicar: #{inspect(reason)}")
        |> assign(:decision, "Pendiente")
    end
  end

  defp apply_pending_action(socket, pending, action, decision, message) do
    with {:ok, claimed, socket} <- claim_pending(socket, pending) do
      case execute_pending_action(claimed, action, decision) do
        {:ok, result} ->
          state = result_value(result, :state)
          reward = result_value(result, :reward)
          applied_action = result_value(result, :action, action)

          case ApprovalQueue.resolve(claimed.id, decision, %{
                 reward: reward,
                 action: applied_action,
                 verification: result_value(result, :verification),
                 message: Atom.to_string(decision)
               }) do
            {:ok, _entry, approval_queue} ->
              snapshot = %{
                connected?: true,
                source: "producer_#{decision}",
                state: state,
                reward: reward,
                error: nil
              }

              socket
              |> assign(:approval_queue, approval_queue)
              |> assign_snapshot(snapshot)
              |> assign(:decision, message)

            {:error, reason, approval_queue} ->
              resolution_error(socket, approval_queue, reason)
          end

        {:error, reason} ->
          release_pending(socket, claimed.id, "No se pudo aplicar", reason)
      end
    else
      {:error, socket} -> socket
    end
  end

  defp execute_pending_action(
         %{source: "sagents_hitl", runtime_context: runtime_context},
         action,
         decision
       )
       when is_map(runtime_context) do
    case decision do
      :approved -> sagents_runtime().resume_irreversible(runtime_context, :approve)
      :edited -> sagents_runtime().resume_irreversible(runtime_context, :edit, action)
    end
  end

  defp execute_pending_action(_pending, action, _decision) do
    SimulatorClient.step(action)
  end

  defp reject_pending_action(socket, pending) do
    with {:ok, claimed, socket} <- claim_pending(socket, pending) do
      result =
        case claimed do
          %{source: "sagents_hitl", runtime_context: runtime_context}
          when is_map(runtime_context) ->
            sagents_runtime().resume_irreversible(runtime_context, :reject)

          _other ->
            {:ok, %{decision: :rejected, mutated: false}}
        end

      case result do
        {:ok, resume_result} ->
          case ApprovalQueue.resolve(claimed.id, :rejected, %{
                 message: "producer_rejected",
                 sagents: resume_result
               }) do
            {:ok, _entry, approval_queue} ->
              socket
              |> assign(:approval_queue, approval_queue)
              |> assign(:action, producer_action(approval_queue, socket.assigns.state))
              |> assign(:decision, "Accion rechazada")

            {:error, reason, approval_queue} ->
              resolution_error(socket, approval_queue, reason)
          end

        {:error, reason} ->
          release_pending(socket, claimed.id, "No se pudo rechazar", reason)
      end
    else
      {:error, socket} -> socket
    end
  end

  defp claim_pending(socket, pending) do
    case ApprovalQueue.claim(pending.id) do
      {:ok, claimed, approval_queue} ->
        {:ok, claimed, assign(socket, :approval_queue, approval_queue)}

      {:error, reason, approval_queue} ->
        {:error, resolution_error(socket, approval_queue, reason)}
    end
  end

  defp release_pending(socket, id, message, reason) do
    approval_queue =
      case ApprovalQueue.release(id) do
        {:ok, _released, approval_queue} -> approval_queue
        {:error, _release_reason, approval_queue} -> approval_queue
      end

    socket
    |> assign(:approval_queue, approval_queue)
    |> put_flash(:error, "#{message}: #{inspect(reason)}")
    |> assign(:decision, "Pendiente")
  end

  defp resolution_error(socket, approval_queue, reason) do
    message =
      case reason do
        :already_processing -> "Esta accion ya se esta procesando"
        :not_pending -> "Esta accion ya fue resuelta"
        :not_processing -> "La accion no esta lista para resolverse"
        _other -> "No se pudo resolver: #{inspect(reason)}"
      end

    socket
    |> assign(:approval_queue, approval_queue)
    |> put_flash(:error, message)
    |> assign(:decision, "Pendiente")
  end

  defp apply_step(socket, action, message, source) do
    case SimulatorClient.step(action) do
      {:ok, %{"state" => state, "reward" => reward}} ->
        snapshot = %{
          connected?: true,
          source: source,
          state: state,
          reward: reward,
          error: nil
        }

        socket
        |> assign_snapshot(snapshot)
        |> assign(:decision, message)

      {:error, reason} ->
        socket
        |> put_flash(:error, "No se pudo aplicar: #{inspect(reason)}")
        |> assign(:decision, "Pendiente")
    end
  end

  defp result_value(result, key, default \\ nil) do
    Map.get(result, key, Map.get(result, Atom.to_string(key), default))
  end

  defp sagents_runtime do
    Application.get_env(:proteinloop, :sagents_runtime, ProteinLoop.Agent.SagentsRuntime)
  end

  defp assign_snapshot(socket, snapshot) do
    approval_queue = socket.assigns.approval_queue

    socket
    |> assign(:snapshot, snapshot)
    |> assign(:state, snapshot.state)
    |> assign(:action, producer_action(approval_queue, snapshot.state))
    |> assign(:offline_guidance, EmergencyRules.evaluate(snapshot.state))
    |> assign(
      :producer_message,
      ProducerMessage.build(
        snapshot.state,
        producer_action(approval_queue, snapshot.state),
        approval_queue
      )
    )
  end

  defp producer_action(%{pending: %{action: action}}, _state), do: action
  defp producer_action(_approval_queue, state), do: SimulatorClient.proposed_action(state)

  defp metric(state, key), do: Map.get(state, key, 0)
  defp rounded(value) when is_float(value), do: Float.round(value, 2)
  defp rounded(value), do: value

  defp instruction(%{"note" => "critical_ammonia_recovery"}) do
    "El tanque necesita aireacion fuerte y cambio parcial de agua."
  end

  defp instruction(%{"note" => "ammonia_stabilization"}) do
    "El tanque necesita menos alimento y mas aireacion."
  end

  defp instruction(%{"note" => "oxygen_recovery"}) do
    "El tanque necesita mas aireacion antes de alimentar normal."
  end

  defp instruction(_action), do: "El sistema esta listo para rutina normal."

  defp pending_prompt(%{pending: %{prompt: prompt}}), do: prompt
  defp pending_prompt(_approval_queue), do: nil

  defp processing?(%{pending: %{status: "processing"}}), do: true
  defp processing?(_approval_queue), do: false

  @impl true
  def render(assigns) do
    ~H"""
    <main class="min-h-screen bg-base-200 text-base-content">
      <section class="mx-auto flex min-h-screen max-w-3xl flex-col justify-center gap-4 px-4 py-6">
        <header class="flex items-center justify-between gap-3 border-b border-base-300 pb-4">
          <div>
            <p class="text-sm font-semibold uppercase tracking-wide text-secondary">ProteinLoop</p>
            <h1 class="text-2xl font-semibold">Productor</h1>
          </div>
          <.link navigate={~p"/"} class="btn btn-sm btn-outline">
            <.icon name="hero-chart-bar-square" /> Panel
          </.link>
        </header>

        <section class="rounded-box border border-base-300 bg-base-100 p-5">
          <div class="mb-4 flex items-start justify-between gap-4">
            <div>
              <p class="text-sm text-base-content/60">Tanque principal</p>
              <p class="text-2xl font-semibold">
                {pending_prompt(@approval_queue) || instruction(@action)}
              </p>
            </div>
            <span class={[
              "badge",
              cond do
                processing?(@approval_queue) -> "badge-info"
                @approval_queue.pending -> "badge-warning"
                @snapshot.connected? -> "badge-success"
                true -> "badge-warning"
              end
            ]}>
              {cond do
                processing?(@approval_queue) -> "procesando"
                @approval_queue.pending -> "aprobacion pendiente"
                @snapshot.connected? -> "en linea"
                true -> "modo local"
              end}
            </span>
          </div>

          <dl class="grid gap-3 sm:grid-cols-3">
            <div class="rounded-box bg-base-200 p-3">
              <dt class="text-sm text-base-content/60">Amonio</dt>
              <dd class="text-xl font-semibold">{rounded(metric(@state, "ammonia_mg_l"))} mg/L</dd>
            </div>
            <div class="rounded-box bg-base-200 p-3">
              <dt class="text-sm text-base-content/60">Oxigeno</dt>
              <dd class="text-xl font-semibold">
                {rounded(metric(@state, "dissolved_oxygen_mg_l"))} mg/L
              </dd>
            </div>
            <div class="rounded-box bg-base-200 p-3">
              <dt class="text-sm text-base-content/60">Dia</dt>
              <dd class="text-xl font-semibold">{metric(@state, "day")}</dd>
            </div>
          </dl>

          <div class="mt-5 rounded-box bg-base-200 p-4">
            <p class="font-semibold">Accion propuesta</p>
            <p class="mt-1 text-sm">
              Alimento {@action["feed_kg"]} kg · Aireacion {@action["aeration_hours"]} h · Agua {@action[
                "water_exchange_fraction"
              ] * 100}% · Cosecha {@action["duckweed_harvest_kg"]} kg
            </p>
          </div>

          <div class="mt-5 rounded-box border border-base-300 bg-base-200 p-4">
            <div class="flex items-start justify-between gap-3">
              <div>
                <p class="font-semibold">Respaldo offline</p>
                <p class="mt-1 text-sm">{@offline_guidance.message}</p>
              </div>
              <span class={["badge", offline_badge(@offline_guidance.severity)]}>
                {@offline_guidance.label}
              </span>
            </div>
            <p class="mt-2 text-sm text-base-content/60">
              Accion local: {@offline_guidance.action}
            </p>
          </div>

          <div class="mt-5 rounded-box border border-base-300 bg-base-200 p-4">
            <div class="flex items-start justify-between gap-3">
              <div>
                <p class="font-semibold">Mensaje WhatsApp/SMS</p>
                <p class="mt-1 text-sm text-base-content/60">
                  Texto corto para enviar cuando el productor no usa el panel.
                </p>
              </div>
              <span class={[
                "badge",
                if(@producer_message.approval_required, do: "badge-warning", else: "badge-success")
              ]}>
                {if @producer_message.approval_required, do: "requiere aprobacion", else: "listo"}
              </span>
            </div>
            <pre class="mt-3 whitespace-pre-wrap rounded-box bg-base-100 p-3 text-sm leading-relaxed"><%= @producer_message.text %></pre>
          </div>

          <div class="mt-5 grid gap-2 sm:grid-cols-3">
            <button
              class="btn btn-success"
              phx-click="approve"
              disabled={processing?(@approval_queue)}
            >
              <.icon name="hero-check" /> Aprobar
            </button>
            <button class="btn btn-warning" phx-click="half" disabled={processing?(@approval_queue)}>
              <.icon name="hero-adjustments-horizontal" /> Solo mitad
            </button>
            <button class="btn btn-outline" phx-click="reject" disabled={processing?(@approval_queue)}>
              <.icon name="hero-x-mark" /> Rechazar
            </button>
          </div>

          <p :if={@decision} class="mt-4 rounded-box bg-info/10 p-3 text-sm text-info">
            {@decision}
          </p>
        </section>
      </section>
    </main>
    """
  end

  defp offline_badge(:critical), do: "badge-error"
  defp offline_badge(:warning), do: "badge-warning"
  defp offline_badge(_severity), do: "badge-success"
end
