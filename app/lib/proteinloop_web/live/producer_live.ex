defmodule ProteinLoopWeb.ProducerLive do
  use ProteinLoopWeb, :live_view

  import ProteinLoopWeb.SystemScene

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
      |> assign(:page_title, "Producer")
      |> assign(:snapshot, snapshot)
      |> assign(:state, snapshot.state)
      |> assign(:nrf9151_evidence, nrf9151_evidence().snapshot())
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
          apply_pending_action(socket, pending, pending.action, :approved, "Action approved")
      end

    {:noreply, socket}
  end

  def handle_event("reject", _params, socket) do
    socket =
      case socket.assigns.approval_queue.pending do
        nil ->
          assign(socket, :decision, "Action rejected")

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

          apply_step(socket, edited, "Action reduced and approved", "producer_edit")

        pending ->
          edited = ApprovalQueue.half_action(pending.action)
          apply_pending_action(socket, pending, edited, :edited, "Action reduced and approved")
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
        |> assign(:decision, "Action approved")

      {:error, reason} ->
        socket
        |> put_flash(:error, "Could not apply the action: #{inspect(reason)}")
        |> assign(:decision, "Pending")
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
          release_pending(socket, claimed.id, "Could not apply the action", reason)
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
              |> assign(:decision, "Action rejected")

            {:error, reason, approval_queue} ->
              resolution_error(socket, approval_queue, reason)
          end

        {:error, reason} ->
          release_pending(socket, claimed.id, "Could not reject the action", reason)
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
    |> assign(:decision, "Pending")
  end

  defp resolution_error(socket, approval_queue, reason) do
    message =
      case reason do
        :already_processing -> "This action is already processing"
        :not_pending -> "This action was already resolved"
        :not_processing -> "This action is not ready to be resolved"
        _other -> "Could not resolve the action: #{inspect(reason)}"
      end

    socket
    |> assign(:approval_queue, approval_queue)
    |> put_flash(:error, message)
    |> assign(:decision, "Pending")
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
        |> put_flash(:error, "Could not apply the action: #{inspect(reason)}")
        |> assign(:decision, "Pending")
    end
  end

  defp result_value(result, key, default \\ nil) do
    Map.get(result, key, Map.get(result, Atom.to_string(key), default))
  end

  defp sagents_runtime do
    Application.get_env(:proteinloop, :sagents_runtime, ProteinLoop.Agent.SagentsRuntime)
  end

  defp nrf9151_evidence do
    Application.get_env(:proteinloop, :nrf9151_evidence, ProteinLoop.NRF9151Evidence)
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

  defp instruction(%{"note" => "critical_ammonia_recovery"}) do
    "The main tank needs maximum aeration and a verified partial water change."
  end

  defp instruction(%{"note" => "ammonia_stabilization"}) do
    "The main tank needs less feed and more aeration."
  end

  defp instruction(%{"note" => "oxygen_recovery"}) do
    "The main tank needs more aeration before normal feeding resumes."
  end

  defp instruction(_action), do: "The system is ready for the normal routine."

  defp pending_prompt(%{pending: %{prompt: prompt}}), do: prompt
  defp pending_prompt(_approval_queue), do: nil

  defp processing?(%{pending: %{status: "processing"}}), do: true
  defp processing?(_approval_queue), do: false

  @impl true
  def render(assigns) do
    ~H"""
    <main class="min-h-screen bg-base-200 text-base-content">
      <section class="mx-auto flex max-w-5xl flex-col gap-4 px-4 py-4 sm:px-6 lg:px-8">
        <header class="flex items-center justify-between gap-3 border-b border-base-300 pb-4">
          <div>
            <p class="text-sm font-semibold uppercase tracking-wide text-secondary">ProteinLoop</p>
            <h1 class="text-2xl font-semibold">Producer decisions</h1>
          </div>
          <.link navigate={~p"/"} class="btn btn-sm btn-outline">
            <.icon name="hero-arrow-left" /> Operator view
          </.link>
        </header>

        <section class="rounded-box border border-base-300 bg-base-100 px-4 py-4 sm:px-5">
          <div class="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
            <div>
              <p class="text-xs font-semibold uppercase tracking-wide text-secondary">
                Current decision
              </p>
              <h2 class="mt-1 max-w-3xl text-xl font-semibold">
                {pending_prompt(@approval_queue) || instruction(@action)}
              </h2>
            </div>
            <span class={[
              "badge whitespace-nowrap",
              cond do
                processing?(@approval_queue) -> "badge-info"
                @approval_queue.pending -> "badge-warning"
                @snapshot.connected? -> "badge-success"
                true -> "badge-warning"
              end
            ]}>
              {cond do
                processing?(@approval_queue) -> "processing"
                @approval_queue.pending -> "approval pending"
                @snapshot.connected? -> "online"
                true -> "local fallback"
              end}
            </span>
          </div>
        </section>

        <.system_scene id="producer-system-scene" state={@state} />

        <section class="grid gap-4 lg:grid-cols-[1.2fr_0.8fr]">
          <div class="rounded-box border border-base-300 bg-base-100 p-4 sm:p-5">
            <div class="flex items-center gap-2">
              <.icon name="hero-clipboard-document-check" class="size-5 text-primary" />
              <h2 class="font-semibold">Proposed action</h2>
            </div>
            <dl class="mt-4 grid grid-cols-2 border-y border-base-300 sm:grid-cols-4">
              <div class="border-base-300 p-3 sm:border-r">
                <dt class="text-xs text-base-content/60">Feed</dt>
                <dd class="mt-1 font-mono text-sm font-semibold">{@action["feed_kg"]} kg</dd>
              </div>
              <div class="border-l border-base-300 p-3 sm:border-l-0 sm:border-r">
                <dt class="text-xs text-base-content/60">Extra air</dt>
                <dd class="mt-1 font-mono text-sm font-semibold">{@action["aeration_hours"]} h</dd>
              </div>
              <div class="border-t border-base-300 p-3 sm:border-r sm:border-t-0">
                <dt class="text-xs text-base-content/60">Replace water</dt>
                <dd class="mt-1 font-mono text-sm font-semibold">
                  {@action["water_exchange_fraction"] * 100}%
                </dd>
              </div>
              <div class="border-l border-t border-base-300 p-3 sm:border-l-0 sm:border-t-0">
                <dt class="text-xs text-base-content/60">Harvest duckweed</dt>
                <dd class="mt-1 font-mono text-sm font-semibold">
                  {@action["duckweed_harvest_kg"]} kg
                </dd>
              </div>
            </dl>
            <p class="mt-3 text-sm text-base-content/65">
              Approve the full action, reduce the irreversible water and harvest amounts by half, or
              reject it without changing the simulator.
            </p>
          </div>

          <div class="rounded-box border border-base-300 bg-base-100 p-4 sm:p-5">
            <div class="flex items-start justify-between gap-3">
              <div>
                <div class="flex items-center gap-2">
                  <.icon name="hero-shield-check" class="size-5 text-secondary" />
                  <h2 class="font-semibold">Offline fallback</h2>
                </div>
                <p class="mt-2 text-sm">{@offline_guidance.message}</p>
              </div>
              <span class={["badge", offline_badge(@offline_guidance.severity)]}>
                {@offline_guidance.label}
              </span>
            </div>
            <p class="mt-3 border-t border-base-300 pt-3 text-sm text-base-content/65">
              Local action: <strong>{@offline_guidance.action}</strong>
            </p>
          </div>
        </section>

        <section
          id="producer-dect-status"
          class="rounded-box border border-base-300 bg-base-100 p-4 sm:p-5"
        >
          <div class="flex flex-wrap items-start justify-between gap-3">
            <div>
              <div class="flex items-center gap-2">
                <.icon name="hero-signal" class="size-5 text-info" />
                <h2 class="font-semibold">Latest DECT NR+ link</h2>
              </div>
              <p :if={@nrf9151_evidence.available?} class="mt-1 text-sm text-base-content/60">
                Sequence #{@nrf9151_evidence.sequence} received in both directions
              </p>
              <p :if={!@nrf9151_evidence.available?} class="mt-1 text-sm text-error">
                Capture unavailable
              </p>
            </div>
            <span class={[
              "badge",
              if(@nrf9151_evidence.available?, do: "badge-success", else: "badge-error")
            ]}>
              {if @nrf9151_evidence.available?, do: "real radio", else: "no evidence"}
            </span>
          </div>

          <dl :if={@nrf9151_evidence.available?} class="mt-3 grid gap-3 text-sm sm:grid-cols-2">
            <div>
              <dt class="text-base-content/60">FT gateway</dt>
              <dd class="mt-1 break-all font-mono">{@nrf9151_evidence.ft.jlink_id}</dd>
            </div>
            <div>
              <dt class="text-base-content/60">PT tank node</dt>
              <dd class="mt-1 break-all font-mono">{@nrf9151_evidence.pt.jlink_id}</dd>
            </div>
          </dl>

          <p :if={@nrf9151_evidence.available?} class="mt-3 text-sm text-base-content/70">
            Water chemistry remains simulated. Nordic hello_dect proves the radio transport, not a
            chemical sensor reading.
          </p>
        </section>

        <section class="rounded-box border border-base-300 bg-base-100 p-4 sm:p-5">
          <div class="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
            <div class="flex flex-wrap items-start justify-between gap-3">
              <div>
                <div class="flex items-center gap-2">
                  <.icon name="hero-chat-bubble-left-right" class="size-5 text-secondary" />
                  <h2 class="font-semibold">WhatsApp/SMS message</h2>
                </div>
                <p class="mt-1 text-sm text-base-content/60">
                  Short handoff text for a producer without access to this screen.
                </p>
              </div>
            </div>
            <span class={[
              "badge",
              if(@producer_message.approval_required, do: "badge-warning", else: "badge-success")
            ]}>
              {if @producer_message.approval_required, do: "approval required", else: "ready"}
            </span>
          </div>
          <pre class="mt-3 whitespace-pre-wrap border-t border-base-300 pt-3 text-sm leading-relaxed"><%= @producer_message.text %></pre>
        </section>

        <div class="sticky bottom-0 grid gap-2 border-t border-base-300 bg-base-200/95 py-3 backdrop-blur sm:grid-cols-3">
          <button
            class="btn btn-success"
            phx-click="approve"
            disabled={processing?(@approval_queue)}
          >
            <.icon name="hero-check" /> Approve
          </button>
          <button class="btn btn-warning" phx-click="half" disabled={processing?(@approval_queue)}>
            <.icon name="hero-adjustments-horizontal" /> Apply half
          </button>
          <button class="btn btn-outline" phx-click="reject" disabled={processing?(@approval_queue)}>
            <.icon name="hero-x-mark" /> Reject
          </button>
        </div>

        <p :if={@decision} class="rounded-box bg-info/10 p-3 text-sm font-semibold text-info">
          {@decision}
        </p>
      </section>
    </main>
    """
  end

  defp offline_badge(:critical), do: "badge-error"
  defp offline_badge(:warning), do: "badge-warning"
  defp offline_badge(_severity), do: "badge-success"
end
