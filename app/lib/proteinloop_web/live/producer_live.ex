defmodule ProteinLoopWeb.ProducerLive do
  use ProteinLoopWeb, :live_view

  import ProteinLoopWeb.RealtimeTankScene

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
    decision = latest_decision_receipt(approval_queue)

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
      |> assign(:decision, decision)

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
     |> assign(:action, producer_action(approval_queue, socket.assigns.state))
     |> maybe_clear_decision(approval_queue)}
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
          assign_decision(socket, :rejected, "Action rejected", %{action: socket.assigns.action})

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

          apply_step(socket, edited, :edited, "Action reduced and approved", "producer_edit")

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
        |> assign_decision(:approved, "Action approved", %{
          action: socket.assigns.action,
          reward: reward
        })

      {:error, reason} ->
        socket
        |> put_flash(:error, "Could not apply the action: #{inspect(reason)}")
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
              |> assign_decision(decision, message, %{
                request_id: claimed.id,
                action: applied_action,
                reward: reward
              })

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
              |> assign_decision(:rejected, "Action rejected", %{
                request_id: claimed.id,
                action: claimed.action
              })

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
  end

  defp apply_step(socket, action, decision, message, source) do
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
        |> assign_decision(decision, message, %{action: action, reward: reward})

      {:error, reason} ->
        socket
        |> put_flash(:error, "Could not apply the action: #{inspect(reason)}")
    end
  end

  defp assign_decision(socket, kind, message, metadata) do
    assign(socket, :decision, decision_receipt(kind, message, metadata))
  end

  defp decision_receipt(kind, message, metadata) do
    Map.merge(
      %{kind: kind, message: message, request_id: nil, action: nil, reward: nil},
      metadata
    )
  end

  defp maybe_clear_decision(
         %{assigns: %{decision: %{request_id: request_id}}} = socket,
         %{pending: %{id: request_id}}
       )
       when not is_nil(request_id),
       do: socket

  defp maybe_clear_decision(socket, %{pending: pending}) when not is_nil(pending) do
    assign(socket, :decision, nil)
  end

  defp maybe_clear_decision(%{assigns: %{decision: nil}} = socket, approval_queue) do
    assign(socket, :decision, latest_decision_receipt(approval_queue))
  end

  defp maybe_clear_decision(socket, _approval_queue), do: socket

  defp latest_decision_receipt(%{pending: nil, decisions: [latest | _]}) do
    with kind when kind in [:approved, :edited, :rejected] <- decision_kind(latest.status) do
      result = Map.get(latest, :result, %{})

      decision_receipt(kind, decision_message(kind), %{
        request_id: latest.id,
        action: result_value(result, :action, latest.action),
        reward: result_value(result, :reward)
      })
    else
      _other -> nil
    end
  end

  defp latest_decision_receipt(_approval_queue), do: nil

  defp decision_kind("approved"), do: :approved
  defp decision_kind("edited"), do: :edited
  defp decision_kind("rejected"), do: :rejected
  defp decision_kind(_status), do: nil

  defp decision_message(:approved), do: "Action approved"
  defp decision_message(:edited), do: "Action reduced and approved"
  defp decision_message(:rejected), do: "Action rejected"

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

  defp decision_heading(%{kind: :approved}), do: "Decision applied safely"
  defp decision_heading(%{kind: :edited}), do: "Reduced action applied safely"

  defp decision_heading(%{kind: :rejected}),
    do: "Decision recorded without changing the system"

  defp decision_badge(%{kind: :approved}), do: "Approved"
  defp decision_badge(%{kind: :edited}), do: "Reduced + approved"
  defp decision_badge(%{kind: :rejected}), do: "Rejected"

  defp decision_badge_class(%{kind: :rejected}), do: "badge-error"
  defp decision_badge_class(_decision), do: "badge-success"

  defp decision_mutation(%{kind: :rejected}), do: "No simulator mutation"
  defp decision_mutation(_decision), do: "Applied after verification"

  defp decision_return_label(%{kind: :rejected}), do: "Return to operator"
  defp decision_return_label(_decision), do: "See recovered tank"

  defp state_metric(state, key), do: Map.get(state, key, Map.get(state, String.to_atom(key), 0))

  defp display_number(value) when is_float(value) do
    value
    |> Float.round(2)
    |> :erlang.float_to_binary([:compact, decimals: 2])
  end

  defp display_number(value), do: to_string(value)

  defp reward_label(nil), do: "Reward not applicable"
  defp reward_label(reward), do: "Reward #{display_number(reward)}"

  defp displayed_action(%{action: action}, _current_action) when is_map(action), do: action
  defp displayed_action(_decision, current_action), do: current_action

  @impl true
  def render(assigns) do
    assigns =
      assign(assigns, :displayed_action, displayed_action(assigns.decision, assigns.action))

    ~H"""
    <main class="min-h-screen bg-base-200 text-base-content">
      <section class="mx-auto flex max-w-7xl flex-col gap-4 px-4 py-4 sm:px-6 lg:px-8">
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
                {if @decision,
                  do: decision_heading(@decision),
                  else: pending_prompt(@approval_queue) || instruction(@action)}
              </h2>
            </div>
            <span class={[
              "badge whitespace-nowrap",
              cond do
                @decision -> decision_badge_class(@decision)
                processing?(@approval_queue) -> "badge-info"
                @approval_queue.pending -> "badge-warning"
                @snapshot.connected? -> "badge-success"
                true -> "badge-warning"
              end
            ]}>
              {cond do
                @decision -> decision_badge(@decision)
                processing?(@approval_queue) -> "processing"
                @approval_queue.pending -> "approval pending"
                @snapshot.connected? -> "online"
                true -> "local fallback"
              end}
            </span>
          </div>
        </section>

        <section
          id="producer-decision-workspace"
          class="producer-decision-workspace"
          aria-label="Producer decision workspace"
        >
          <div class="producer-decision-workspace__proposal">
            <div class="flex items-center gap-2">
              <.icon name="hero-clipboard-document-check" class="size-5 text-primary" />
              <h2 class="font-semibold">Proposed action</h2>
            </div>
            <dl class="mt-4 grid grid-cols-2 border-y border-base-300 sm:grid-cols-4">
              <div class="border-base-300 p-3 sm:border-r">
                <dt class="text-xs text-base-content/60">Feed</dt>
                <dd class="mt-1 font-mono text-sm font-semibold">
                  {@displayed_action["feed_kg"]} kg
                </dd>
              </div>
              <div class="border-l border-base-300 p-3 sm:border-l-0 sm:border-r">
                <dt class="text-xs text-base-content/60">Extra air</dt>
                <dd class="mt-1 font-mono text-sm font-semibold">
                  {@displayed_action["aeration_hours"]} h
                </dd>
              </div>
              <div class="border-t border-base-300 p-3 sm:border-r sm:border-t-0">
                <dt class="text-xs text-base-content/60">Replace water</dt>
                <dd class="mt-1 font-mono text-sm font-semibold">
                  {@displayed_action["water_exchange_fraction"] * 100}%
                </dd>
              </div>
              <div class="border-l border-t border-base-300 p-3 sm:border-l-0 sm:border-t-0">
                <dt class="text-xs text-base-content/60">Harvest duckweed</dt>
                <dd class="mt-1 font-mono text-sm font-semibold">
                  {@displayed_action["duckweed_harvest_kg"]} kg
                </dd>
              </div>
            </dl>
            <p class="mt-3 text-sm text-base-content/65">
              This plan was checked against deterministic ecosystem safety rules before reaching
              you. You keep the final decision over water exchange and harvest.
            </p>
          </div>

          <div class="producer-decision-workspace__control" aria-busy={processing?(@approval_queue)}>
            <div :if={!@decision}>
              <p class="text-xs font-semibold uppercase tracking-wide text-secondary">
                Producer choice
              </p>
              <h2 class="mt-1 text-xl font-semibold">Make the final call</h2>
              <p class="mt-2 text-sm leading-6 text-base-content/65">
                Approve the verified plan, reduce irreversible amounts by half, or reject it with
                no simulator mutation.
              </p>
              <p :if={processing?(@approval_queue)} class="mt-3 text-sm font-semibold text-info">
                The decision is processing. Controls remain locked until the receipt is ready.
              </p>
              <div class="producer-decision-workspace__actions">
                <button
                  id="producer-approve"
                  class="btn btn-success"
                  phx-click="approve"
                  phx-disable-with="Applying verified plan..."
                  disabled={processing?(@approval_queue)}
                >
                  <.icon name="hero-check" /> Approve
                </button>
                <button
                  id="producer-half"
                  class="btn btn-warning"
                  phx-click="half"
                  phx-disable-with="Applying reduced plan..."
                  disabled={processing?(@approval_queue)}
                >
                  <.icon name="hero-adjustments-horizontal" /> Apply half
                </button>
                <button
                  id="producer-reject"
                  class="btn btn-outline"
                  phx-click="reject"
                  phx-disable-with="Recording rejection..."
                  disabled={processing?(@approval_queue)}
                >
                  <.icon name="hero-x-mark" /> Reject
                </button>
              </div>
            </div>

            <section
              :if={@decision}
              id="producer-decision-result"
              class="producer-decision-result"
              data-decision-kind={@decision.kind}
              role="status"
              aria-live="polite"
              aria-atomic="true"
            >
              <div class="flex flex-wrap items-start justify-between gap-3">
                <div>
                  <p class="text-xs font-semibold uppercase tracking-wide text-secondary">
                    Decision receipt
                  </p>
                  <h2 class="mt-1 text-xl font-semibold">{decision_heading(@decision)}</h2>
                  <p class="mt-1 text-sm text-base-content/65">{@decision.message}</p>
                </div>
                <span class={["badge", decision_badge_class(@decision)]}>
                  {decision_badge(@decision)}
                </span>
              </div>

              <dl class="producer-decision-result__facts">
                <div>
                  <dt>Simulator mutation</dt>
                  <dd>{decision_mutation(@decision)}</dd>
                </div>
                <div>
                  <dt>Current ammonia</dt>
                  <dd>{display_number(state_metric(@state, "ammonia_mg_l"))} mg/L</dd>
                </div>
                <div>
                  <dt>Current oxygen</dt>
                  <dd>{display_number(state_metric(@state, "dissolved_oxygen_mg_l"))} mg/L</dd>
                </div>
                <div>
                  <dt>Verifier result</dt>
                  <dd>{reward_label(@decision.reward)}</dd>
                </div>
              </dl>

              <.link navigate={~p"/"} class="btn btn-primary mt-4 w-full sm:w-auto">
                <.icon name="hero-arrow-right" /> {decision_return_label(@decision)}
              </.link>
            </section>
          </div>
        </section>

        <.realtime_tank_scene id="producer-system-scene" state={@state} />

        <section class="rounded-box border border-base-300 bg-base-100 p-4 sm:p-5">
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
      </section>
    </main>
    """
  end

  defp offline_badge(:critical), do: "badge-error"
  defp offline_badge(:warning), do: "badge-warning"
  defp offline_badge(_severity), do: "badge-success"
end
