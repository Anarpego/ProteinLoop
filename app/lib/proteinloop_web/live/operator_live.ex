defmodule ProteinLoopWeb.OperatorLive do
  use ProteinLoopWeb, :live_view

  alias ProteinLoop.Agent.ApprovalQueue
  alias ProteinLoop.Agent.DemoCascade
  alias ProteinLoop.Agent.Harness
  alias ProteinLoop.Agent.HordeRuntime
  alias ProteinLoop.Agent.Mesh
  alias ProteinLoop.Agent.ModelStatus
  alias ProteinLoop.Agent.SagentsRuntime
  alias ProteinLoop.Agent.Topology
  alias ProteinLoop.Agent.TraceStore
  alias ProteinLoop.SimulatorClient
  alias ProteinLoop.SimulatorPoller

  @agentic_missions [
    %{
      id: "recover-water",
      title: "Recover water quality",
      objective:
        "Reduce ammonia and restore dissolved oxygen while protecting fish and prawn survival."
    },
    %{
      id: "protect-protein",
      title: "Protect protein yield",
      objective:
        "Protect fish, prawns, and daily protein yield while keeping water chemistry inside safe bounds."
    },
    %{
      id: "balance-24h",
      title: "Balance next 24h",
      objective:
        "Balance feed, aeration, water exchange, plant uptake, and duckweed reserve for the next 24 hours."
    }
  ]

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      SimulatorPoller.subscribe()
      ApprovalQueue.subscribe()
    end

    snapshot = SimulatorPoller.snapshot_now("mount")
    rlvr_evaluation = rlvr_evaluation()
    rlvr_training = rlvr_training()
    anomaly_forecast = anomaly_forecast()

    socket =
      socket
      |> assign(:page_title, "Operator")
      |> assign(:snapshot, snapshot)
      |> assign(:state, snapshot.state)
      |> assign(:topology, Topology.from_state(snapshot.state))
      |> assign(:agent_result, nil)
      |> assign(:demo_result, nil)
      |> assign(:loop_result, nil)
      |> assign(:sagents_status, sagents_runtime().status())
      |> assign(:sagents_running?, false)
      |> assign(:agentic_missions, @agentic_missions)
      |> assign(:selected_mission, hd(@agentic_missions))
      |> assign(:mission_phase, :ready)
      |> assign(:hitl_running?, false)
      |> assign(:agent_provider, :stub_safe)
      |> assign(:horde_status, horde_runtime().cluster_status())
      |> assign(:nrf9151_evidence, nrf9151_evidence().snapshot())
      |> assign(:mesh, Mesh.initial())
      |> assign(:approval_queue, ApprovalQueue.snapshot())
      |> assign(:model_status, ModelStatus.snapshot())
      |> assign(:rlvr_evaluation, rlvr_evaluation)
      |> assign(:rlvr_training, rlvr_training)
      |> assign(:anomaly_forecast, anomaly_forecast)
      |> assign(:trace_status, TraceStore.status())
      |> assign(:trace_entries, trace_entries())
      |> assign(:action_log, ["dashboard mounted"])

    {:ok, socket}
  end

  @impl true
  def handle_info({:simulator_snapshot, snapshot}, socket) do
    {:noreply, assign_snapshot(socket, snapshot, "telemetry update")}
  end

  def handle_info({:approval_queue, approval_queue}, socket) do
    {:noreply, assign(socket, :approval_queue, approval_queue)}
  end

  @impl true
  def handle_event("refresh", _params, socket) do
    snapshot = SimulatorPoller.broadcast_snapshot("refresh")

    {:noreply,
     socket
     |> assign(:rlvr_evaluation, rlvr_evaluation())
     |> assign(:rlvr_training, rlvr_training())
     |> assign(:anomaly_forecast, anomaly_forecast())
     |> assign(:horde_status, horde_runtime().cluster_status())
     |> assign_snapshot(snapshot, "manual refresh")}
  end

  def handle_event("refresh-horde", _params, socket) do
    {:noreply,
     socket
     |> assign(:horde_status, horde_runtime().cluster_status())
     |> update(:action_log, fn log -> Enum.take(["Horde cluster status refreshed" | log], 6) end)}
  end

  def handle_event("refresh-dect", _params, socket) do
    {:noreply,
     socket
     |> assign(:nrf9151_evidence, nrf9151_evidence().snapshot())
     |> update(:action_log, fn log -> Enum.take(["DECT evidence refreshed" | log], 6) end)}
  end

  def handle_event("replay-dect-sensor", _params, socket) do
    evidence = socket.assigns.nrf9151_evidence

    socket =
      cond do
        not evidence.available? ->
          put_flash(socket, :error, "A physical DECT capture is required for replay")

        true ->
          case dect_simulator_client().trigger_ammonia_spike() do
            {:ok, %{"state" => state}} ->
              snapshot = %{
                connected?: true,
                source: "dect-replay",
                state: state,
                reward: nil,
                error: nil
              }

              assign_snapshot(
                socket,
                snapshot,
                "DECT capture ##{evidence.sequence} replayed as simulated sensor alert"
              )

            {:error, reason} ->
              put_flash(socket, :error, "Simulator error: #{inspect(reason)}")
          end
      end

    {:noreply, socket}
  end

  def handle_event("spike", _params, socket) do
    socket =
      case SimulatorClient.trigger_ammonia_spike() do
        {:ok, %{"state" => state}} ->
          snapshot = %{connected?: true, source: "spike", state: state, reward: nil, error: nil}
          assign_snapshot(socket, snapshot, "ammonia spike injected")

        {:error, reason} ->
          put_flash(socket, :error, "Simulator error: #{inspect(reason)}")
      end

    {:noreply, socket}
  end

  def handle_event("safety-step", _params, socket) do
    socket =
      case SimulatorClient.safety_step() do
        {:ok, %{"state" => state, "reward" => reward}} ->
          snapshot = %{
            connected?: true,
            source: "safety",
            state: state,
            reward: reward,
            error: nil
          }

          assign_snapshot(socket, snapshot, "safety action applied")

        {:error, reason} ->
          put_flash(socket, :error, "Simulator error: #{inspect(reason)}")
      end

    {:noreply, socket}
  end

  def handle_event("reset", _params, socket) do
    socket =
      case SimulatorClient.reset() do
        {:ok, %{"state" => state}} ->
          snapshot = %{connected?: true, source: "reset", state: state, reward: nil, error: nil}
          assign_snapshot(socket, snapshot, "scenario reset")

        {:error, reason} ->
          put_flash(socket, :error, "Simulator error: #{inspect(reason)}")
      end

    {:noreply, socket}
  end

  def handle_event("agent-safe", _params, socket) do
    {:noreply, run_agent(socket, :stub_safe)}
  end

  def handle_event("agent-unsafe", _params, socket) do
    {:noreply, run_agent(socket, :stub_unsafe)}
  end

  def handle_event("select-provider", %{"provider" => provider}, socket) do
    provider = parse_provider(provider)

    {:noreply,
     socket
     |> assign(:agent_provider, provider)
     |> update(:action_log, fn log -> Enum.take(["provider selected: #{provider}" | log], 6) end)}
  end

  def handle_event("agent-selected", _params, socket) do
    {:noreply, run_agent(socket, socket.assigns.agent_provider)}
  end

  def handle_event("check-model", _params, socket) do
    {:noreply,
     socket
     |> assign(:model_status, ModelStatus.check())
     |> update(:action_log, fn log -> Enum.take(["model endpoint checked" | log], 6) end)}
  end

  def handle_event("mesh-fail-node", _params, socket) do
    {:noreply,
     socket
     |> assign(:mesh, Mesh.fail_edge_node(socket.assigns.mesh))
     |> update(:action_log, fn log -> Enum.take(["mesh node failed over" | log], 6) end)}
  end

  def handle_event("mesh-recover-node", _params, socket) do
    {:noreply,
     socket
     |> assign(:mesh, Mesh.recover_node(socket.assigns.mesh))
     |> update(:action_log, fn log -> Enum.take(["mesh node recovered" | log], 6) end)}
  end

  def handle_event("mesh-reset", _params, socket) do
    {:noreply,
     socket
     |> assign(:mesh, Mesh.reset())
     |> update(:action_log, fn log -> Enum.take(["mesh reset" | log], 6) end)}
  end

  def handle_event("request-hitl", _params, socket) do
    cond do
      socket.assigns.hitl_running? ->
        {:noreply, socket}

      socket.assigns.approval_queue.pending != nil ->
        {:noreply,
         update(socket, :action_log, fn log ->
           Enum.take(["producer approval already pending" | log], 6)
         end)}

      not socket.assigns.sagents_status.endpoint_configured? ->
        {:noreply, put_flash(socket, :error, "GEMMA_ENDPOINT is required for Sagents HITL")}

      true ->
        state = socket.assigns.state
        runtime = sagents_runtime()

        {:noreply,
         socket
         |> assign(:hitl_running?, true)
         |> start_async(:sagents_hitl, fn -> runtime.request_irreversible(state) end)}
    end
  end

  def handle_event("run-verified-loop", _params, socket) do
    {:noreply, start_sagents_cycle(socket)}
  end

  def handle_event("select-agentic-mission", %{"mission" => mission_id}, socket) do
    mission = Enum.find(@agentic_missions, hd(@agentic_missions), &(&1.id == mission_id))

    socket =
      if socket.assigns.sagents_running? do
        socket
      else
        socket
        |> assign(:selected_mission, mission)
        |> assign(:loop_result, nil)
        |> assign(:mission_phase, :ready)
        |> update(:action_log, fn log ->
          Enum.take(["agentic mission selected: #{mission.title}" | log], 6)
        end)
      end

    {:noreply, socket}
  end

  def handle_event("run-agentic-mission", _params, socket) do
    {:noreply, start_sagents_cycle(socket)}
  end

  def handle_event("dect-run-gemma", _params, socket) do
    {:noreply, start_sagents_cycle(socket)}
  end

  def handle_event("demo-cascade", _params, socket) do
    socket =
      case DemoCascade.run() do
        {:ok, result} ->
          snapshot = %{
            connected?: true,
            source: "demo:cascade",
            state: result.final_state,
            reward: result.safe_result.reward,
            error: nil
          }

          socket
          |> assign(:demo_result, result)
          |> assign(:agent_result, result.safe_result)
          |> assign(:trace_status, TraceStore.status())
          |> assign(:trace_entries, trace_entries())
          |> assign_snapshot(snapshot, "demo cascade completed")

        {:error, reason} ->
          put_flash(socket, :error, "Demo cascade error: #{inspect(reason)}")
      end

    {:noreply, socket}
  end

  @impl true
  def handle_async(:sagents_cycle, {:ok, {:ok, result}}, socket) do
    snapshot = %{
      connected?: true,
      source: "sagents:gemma",
      state: result.state,
      reward: result.reward,
      error: nil
    }

    {:noreply,
     socket
     |> assign(:sagents_running?, false)
     |> assign(:mission_phase, :completed)
     |> assign(:loop_result, result)
     |> assign_snapshot(snapshot, "real Sagents cycle completed")}
  end

  def handle_async(:sagents_cycle, {:ok, {:error, reason}}, socket) do
    {:noreply,
     socket
     |> assign(:sagents_running?, false)
     |> assign(:mission_phase, :failed)
     |> put_flash(:error, "Sagents error: #{inspect(reason)}")}
  end

  def handle_async(:sagents_cycle, {:exit, reason}, socket) do
    {:noreply,
     socket
     |> assign(:sagents_running?, false)
     |> assign(:mission_phase, :failed)
     |> put_flash(:error, "Sagents task exited: #{inspect(reason)}")}
  end

  def handle_async(:sagents_hitl, {:ok, {:interrupt, pending}}, socket) do
    [action_request | _rest] = pending.interrupt_data.action_requests

    queue_result =
      ApprovalQueue.request(action_request.arguments,
        rationale: "Sagents HumanInTheLoop pauso la accion antes de mutar el simulador",
        requested_by: "sagents-supervisor",
        source: "sagents_hitl",
        allowed_decisions: pending.allowed_decisions,
        tool_call_id: action_request.tool_call_id,
        runtime_context: pending
      )

    case queue_result do
      {:ok, _request, approval_queue} ->
        {:noreply,
         socket
         |> assign(:hitl_running?, false)
         |> assign(:approval_queue, approval_queue)
         |> update(:action_log, fn log ->
           Enum.take(["Sagents HITL requested producer approval" | log], 6)
         end)}

      {:pending, _request, approval_queue} ->
        {:noreply,
         socket
         |> assign(:hitl_running?, false)
         |> assign(:approval_queue, approval_queue)}
    end
  end

  def handle_async(:sagents_hitl, {:ok, other}, socket) do
    {:noreply,
     socket
     |> assign(:hitl_running?, false)
     |> put_flash(:error, "Sagents HITL did not interrupt: #{inspect(other)}")}
  end

  def handle_async(:sagents_hitl, {:exit, reason}, socket) do
    {:noreply,
     socket
     |> assign(:hitl_running?, false)
     |> put_flash(:error, "Sagents HITL task exited: #{inspect(reason)}")}
  end

  defp start_sagents_cycle(socket) do
    cond do
      socket.assigns.sagents_running? ->
        socket

      socket.assigns.sagents_status.endpoint_configured? ->
        runtime = sagents_runtime()
        mission = socket.assigns.selected_mission

        socket
        |> assign(:sagents_running?, true)
        |> assign(:mission_phase, :deliberating)
        |> update(:action_log, fn log ->
          Enum.take(["agentic mission started: #{mission.title}" | log], 6)
        end)
        |> start_async(:sagents_cycle, fn -> runtime.run(mission: mission.objective) end)

      true ->
        put_flash(socket, :error, "GEMMA_ENDPOINT is required for Sagents")
    end
  end

  defp assign_snapshot(socket, snapshot, log_entry) do
    socket
    |> assign(:snapshot, snapshot)
    |> assign(:state, snapshot.state)
    |> assign(:topology, Topology.from_state(snapshot.state))
    |> update(:action_log, fn log -> Enum.take([log_entry | log], 6) end)
  end

  defp sagents_runtime do
    Application.get_env(:proteinloop, :sagents_runtime, SagentsRuntime)
  end

  defp horde_runtime do
    Application.get_env(:proteinloop, :horde_runtime, HordeRuntime)
  end

  defp nrf9151_evidence do
    Application.get_env(:proteinloop, :nrf9151_evidence, ProteinLoop.NRF9151Evidence)
  end

  defp dect_simulator_client do
    Application.get_env(:proteinloop, :dect_simulator_client, SimulatorClient)
  end

  defp run_agent(socket, provider) do
    case Harness.run(provider: provider) do
      {:ok, result} ->
        snapshot = %{
          connected?: true,
          source: "agent:#{provider}",
          state: result.state,
          reward: result.reward,
          error: nil
        }

        socket
        |> assign(:agent_result, result)
        |> assign(:trace_status, TraceStore.status())
        |> assign(:trace_entries, trace_entries())
        |> assign_snapshot(snapshot, "agent proposal accepted")

      {:rejected, result} ->
        socket
        |> assign(:agent_result, result)
        |> assign(:trace_status, TraceStore.status())
        |> assign(:trace_entries, trace_entries())
        |> update(:action_log, fn log -> Enum.take(["agent proposal rejected" | log], 6) end)

      {:error, reason} ->
        put_flash(socket, :error, "Agent harness error: #{inspect(reason)}")
    end
  end

  defp metric(state, key), do: Map.get(state, key, 0)

  defp trace_entries do
    case TraceStore.recent(5) do
      {:ok, entries} -> entries
      {:error, _reason} -> []
    end
  end

  defp rlvr_evaluation do
    case SimulatorClient.rlvr_evaluation() do
      {:ok, %{"rlvr" => evaluation}} -> Map.put(evaluation, "available", true)
      {:error, reason} -> SimulatorClient.fallback_rlvr_evaluation(reason)
    end
  end

  defp rlvr_training do
    case SimulatorClient.rlvr_training() do
      {:ok, %{"training" => training}} -> Map.put(training, "available", true)
      {:error, reason} -> SimulatorClient.fallback_rlvr_training(reason)
    end
  end

  defp anomaly_forecast do
    case SimulatorClient.anomaly_forecast() do
      {:ok, %{"forecast" => forecast}} -> Map.put(forecast, "available", true)
      {:error, reason} -> SimulatorClient.fallback_anomaly_forecast(reason)
    end
  end

  defp parse_provider("stub_unsafe"), do: :stub_unsafe
  defp parse_provider("openai_compatible"), do: :openai_compatible
  defp parse_provider(_provider), do: :stub_safe

  defp specialist_name("fish-tank"), do: "Fish tank"
  defp specialist_name("freshwater-prawn"), do: "Freshwater prawn"
  defp specialist_name("hydroponia"), do: "Hydroponia"
  defp specialist_name("duckweed-chickens"), do: "Duckweed + chickens"
  defp specialist_name(name), do: name

  defp specialist_status_badge("critical"), do: "badge-error"
  defp specialist_status_badge("warning"), do: "badge-warning"
  defp specialist_status_badge(_status), do: "badge-success"

  defp verification_count(verification, key) do
    verification
    |> verification_messages(key)
    |> length()
  end

  defp verification_messages(verification, key) do
    case Map.get(verification, key, []) do
      messages when is_list(messages) -> messages
      _other -> []
    end
  end

  defp rounded(value, precision \\ 2)
  defp rounded(value, precision) when is_float(value), do: Float.round(value, precision)
  defp rounded(value, _precision), do: value

  defp status_badge(%{connected?: false}), do: {"badge-error", "sim offline"}
  defp status_badge(%{state: %{"collapsed" => true}}), do: {"badge-error", "collapsed"}

  defp status_badge(%{state: %{"ammonia_mg_l" => ammonia}}) when ammonia >= 3.0,
    do: {"badge-warning", "critical"}

  defp status_badge(_snapshot), do: {"badge-success", "stable"}

  defp risk_class(value, _warning, critical) when value >= critical, do: "text-error"
  defp risk_class(value, warning, _critical) when value >= warning, do: "text-warning"
  defp risk_class(_value, _warning, _critical), do: "text-success"

  defp oxygen_class(value) when value < 3.5, do: "text-error"
  defp oxygen_class(value) when value < 5.0, do: "text-warning"
  defp oxygen_class(_value), do: "text-success"

  @impl true
  def render(assigns) do
    {badge_class, badge_text} = status_badge(assigns.snapshot)
    assigns = assign(assigns, :badge_class, badge_class) |> assign(:badge_text, badge_text)

    ~H"""
    <main class="min-h-screen bg-base-200 text-base-content">
      <section class="mx-auto flex max-w-7xl flex-col gap-4 px-4 py-4 sm:px-6 lg:px-8">
        <header class="flex flex-col gap-3 border-b border-base-300 pb-4 lg:flex-row lg:items-center lg:justify-between">
          <div>
            <p class="text-sm font-semibold uppercase tracking-wide text-secondary">ProteinLoop</p>
            <h1 class="text-2xl font-semibold tracking-normal">Operator dashboard</h1>
          </div>
          <div class="flex flex-wrap items-center gap-2">
            <span class={["badge", @badge_class]}>{@badge_text}</span>
            <.link navigate={~p"/producer"} class="btn btn-sm btn-outline">
              <.icon name="hero-language" /> Producer
            </.link>
            <button class="btn btn-sm btn-outline" phx-click="refresh">
              <.icon name="hero-arrow-path" /> Refresh
            </button>
          </div>
        </header>

        <section class="grid gap-3 md:grid-cols-2 xl:grid-cols-4">
          <.metric_card
            label="Day"
            value={metric(@state, "day")}
            detail={metric(@state, "last_event")}
          />
          <.metric_card
            label="Ammonia"
            value={"#{rounded(metric(@state, "ammonia_mg_l"))} mg/L"}
            detail="safe target < 1.5"
            value_class={risk_class(metric(@state, "ammonia_mg_l"), 1.5, 3.0)}
          />
          <.metric_card
            label="Dissolved oxygen"
            value={"#{rounded(metric(@state, "dissolved_oxygen_mg_l"))} mg/L"}
            detail="safe target > 5.0"
            value_class={
              if metric(@state, "dissolved_oxygen_mg_l") < 3.5, do: "text-error", else: "text-success"
            }
          />
          <.metric_card
            label="Reward"
            value={@snapshot.reward || "pending"}
            detail={@snapshot.source}
          />
        </section>

        <section id="dect-live-evidence" class="rounded-box border border-base-300 bg-base-100 p-4">
          <div class="flex flex-col gap-3 md:flex-row md:items-start md:justify-between">
            <div>
              <div class="flex flex-wrap items-center gap-2">
                <h2 class="text-lg font-semibold">Physical DECT NR+ link</h2>
                <span :if={@nrf9151_evidence.available?} class="badge badge-success">
                  real radio capture
                </span>
                <span :if={!@nrf9151_evidence.available?} class="badge badge-error">unavailable</span>
              </div>
              <p class="mt-1 text-sm text-base-content/60">
                Latest read-only exchange from the two connected nRF9151 boards.
              </p>
            </div>
            <div class="flex flex-wrap gap-2">
              <button
                class="btn btn-sm btn-outline"
                phx-click="refresh-dect"
                title="Reload DECT evidence"
              >
                <.icon name="hero-arrow-path" /> Refresh
              </button>
              <button
                id="replay-dect-sensor"
                class="btn btn-sm btn-warning"
                phx-click="replay-dect-sensor"
                disabled={!@nrf9151_evidence.available?}
              >
                <.icon name="hero-signal" /> Replay sensor alert
              </button>
              <button
                id="dect-run-gemma"
                class="btn btn-sm btn-primary"
                phx-click="dect-run-gemma"
                disabled={
                  !@nrf9151_evidence.available? || @sagents_running? ||
                    !@sagents_status.endpoint_configured?
                }
              >
                <.icon
                  name={if @sagents_running?, do: "hero-arrow-path", else: "hero-play"}
                  class={if @sagents_running?, do: "animate-spin", else: nil}
                />
                {if @sagents_running?, do: "Running agents", else: "Run selected mission"}
              </button>
            </div>
          </div>

          <div
            :if={@nrf9151_evidence.available?}
            class="mt-4 grid border-y border-base-300 md:grid-cols-[1fr_auto_1fr]"
          >
            <dl class="py-3 md:pr-4">
              <div class="flex items-center justify-between gap-3">
                <dt class="font-semibold">FT gateway</dt>
                <dd class="badge badge-outline">sent + received</dd>
              </div>
              <div class="mt-2 grid grid-cols-[auto_1fr] gap-x-3 gap-y-1 text-sm">
                <dt class="text-base-content/60">J-Link</dt>
                <dd class="break-all font-mono">{@nrf9151_evidence.ft.jlink_id}</dd>
                <dt class="text-base-content/60">Serial</dt>
                <dd class="break-all font-mono text-xs">{@nrf9151_evidence.ft.serial_port}</dd>
              </div>
            </dl>

            <div class="flex items-center justify-center border-base-300 px-5 py-3 md:border-x">
              <div class="text-center">
                <.icon name="hero-arrows-right-left" class="mx-auto size-5 text-info" />
                <p class="mt-1 whitespace-nowrap font-semibold">
                  Sequence #{@nrf9151_evidence.sequence}
                </p>
                <p class="text-xs text-base-content/60">FT / PT bidirectional</p>
              </div>
            </div>

            <dl class="py-3 md:pl-4">
              <div class="flex items-center justify-between gap-3">
                <dt class="font-semibold">PT tank edge</dt>
                <dd class="badge badge-outline">sent + received</dd>
              </div>
              <div class="mt-2 grid grid-cols-[auto_1fr] gap-x-3 gap-y-1 text-sm">
                <dt class="text-base-content/60">J-Link</dt>
                <dd class="break-all font-mono">{@nrf9151_evidence.pt.jlink_id}</dd>
                <dt class="text-base-content/60">Serial</dt>
                <dd class="break-all font-mono text-xs">{@nrf9151_evidence.pt.serial_port}</dd>
              </div>
            </dl>
          </div>

          <p :if={@nrf9151_evidence.available?} class="mt-3 text-sm text-base-content/70">
            Nordic hello_dect proves the physical radio link. Replaying it creates a simulated sensor
            alert in the deterministic water-quality scenario; it is not chemical sensor telemetry.
          </p>
          <p :if={!@nrf9151_evidence.available?} class="mt-3 text-sm text-error">
            Could not load the latest capture: {@nrf9151_evidence.error}
          </p>
        </section>

        <section class="grid gap-4 lg:grid-cols-[1.3fr_0.7fr]">
          <div class="rounded-box border border-base-300 bg-base-100 p-4">
            <div class="mb-3 flex items-center justify-between gap-3">
              <h2 class="text-lg font-semibold">Closed-loop state</h2>
              <div class="join">
                <button class="btn join-item btn-sm btn-error" phx-click="spike">
                  <.icon name="hero-bolt" /> Spike
                </button>
                <button class="btn join-item btn-sm btn-success" phx-click="safety-step">
                  <.icon name="hero-shield-check" /> Stabilize
                </button>
                <button class="btn join-item btn-sm" phx-click="reset">
                  <.icon name="hero-arrow-uturn-left" /> Reset
                </button>
                <button class="btn join-item btn-sm btn-primary" phx-click="demo-cascade">
                  <.icon name="hero-play" /> Run demo cascade
                </button>
              </div>
            </div>

            <div class="grid gap-3 md:grid-cols-3">
              <.organism name="Fish" value={metric(@state, "fish_biomass_kg")} unit="kg" />
              <.organism name="Prawn" value={metric(@state, "prawn_biomass_kg")} unit="kg" />
              <.organism name="Plants" value={metric(@state, "plant_biomass_kg")} unit="kg" />
              <.organism name="Duckweed" value={metric(@state, "duckweed_kg")} unit="kg" />
              <.organism name="Eggs" value={metric(@state, "eggs_count")} unit="count" />
              <.organism name="pH" value={metric(@state, "ph")} unit="" />
            </div>
          </div>

          <aside class="rounded-box border border-base-300 bg-base-100 p-4">
            <h2 class="mb-3 text-lg font-semibold">Event stream</h2>
            <ol class="space-y-2">
              <li :for={entry <- @action_log} class="flex items-start gap-2 text-sm">
                <.icon name="hero-signal" class="mt-0.5 size-4 text-info" />
                <span>{entry}</span>
              </li>
            </ol>
            <p :if={!@snapshot.connected?} class="mt-4 rounded-box bg-error/10 p-3 text-sm text-error">
              Simulator API unavailable: {@snapshot.error}
            </p>
          </aside>
        </section>

        <section class="rounded-box border border-base-300 bg-base-100 p-4">
          <div class="mb-3 flex items-center justify-between gap-3">
            <h2 class="text-lg font-semibold">Subsystem agent topology</h2>
            <span class="badge badge-outline">{length(@topology)} agents</span>
          </div>
          <div class="grid gap-3 md:grid-cols-2 xl:grid-cols-4">
            <.topology_agent :for={agent <- @topology} agent={agent} />
          </div>
        </section>

        <section class="rounded-box border border-base-300 bg-base-100 p-4">
          <div class="mb-3 flex items-center justify-between gap-3">
            <h2 class="text-lg font-semibold">Self-healing mesh</h2>
            <span class={[
              "badge badge-sm",
              if(horde_cluster_online?(@horde_status), do: "badge-success", else: "badge-warning")
            ]}>
              {if horde_cluster_online?(@horde_status), do: "Horde online", else: "local mode"}
            </span>
          </div>

          <.horde_panel status={@horde_status} />

          <div class="mb-3 mt-4 flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
            <div>
              <h3 class="text-sm font-semibold">Deterministic failover rehearsal</h3>
              <p class="text-sm text-base-content/60">migration_count={@mesh.migration_count}</p>
            </div>
            <div class="flex flex-wrap gap-2">
              <button class="btn btn-sm btn-error" phx-click="mesh-fail-node">
                <.icon name="hero-no-symbol" /> Simulate node loss
              </button>
              <button class="btn btn-sm btn-success" phx-click="mesh-recover-node">
                <.icon name="hero-arrow-path" /> Recover node
              </button>
              <button class="btn btn-sm btn-outline" phx-click="mesh-reset">
                <.icon name="hero-arrow-uturn-left" /> Reset mesh
              </button>
            </div>
          </div>
          <.mesh_panel mesh={@mesh} />
        </section>

        <section class="rounded-box border border-base-300 bg-base-100 p-4">
          <div class="mb-3 flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
            <div>
              <h2 class="text-lg font-semibold">Spanish HITL approval</h2>
              <p class="text-sm text-base-content/60">
                Risky water and harvest actions wait for producer decision.
              </p>
            </div>
            <button
              class="btn btn-sm btn-warning"
              phx-click="request-hitl"
              disabled={@hitl_running? || !@sagents_status.endpoint_configured?}
            >
              <.icon
                name={if @hitl_running?, do: "hero-arrow-path", else: "hero-hand-raised"}
                class={if @hitl_running?, do: "animate-spin", else: nil}
              />
              {if @hitl_running?, do: "Waiting for Gemma", else: "Request producer approval"}
            </button>
          </div>
          <.approval_queue queue={@approval_queue} />
        </section>

        <section
          id="agentic-mission"
          class="rounded-box border border-base-300 bg-base-100 p-4"
        >
          <div class="flex flex-col gap-3 lg:flex-row lg:items-start lg:justify-between">
            <div>
              <div class="flex flex-wrap items-center gap-2">
                <h2 class="text-lg font-semibold">Agentic intervention mission</h2>
                <span class="badge badge-success">real Gemma</span>
                <span class="badge badge-outline">{@sagents_status.agent_count} agents</span>
              </div>
              <p class="mt-1 max-w-3xl text-sm text-base-content/60">
                Set an operational objective. Four specialists recommend bounded actions, a supervisor
                resolves resource conflicts, and the deterministic verifier controls mutation.
              </p>
            </div>
            <div class="text-sm text-base-content/60 lg:text-right">
              <p>
                Sagents {@sagents_status.framework_version} / LangChain {@sagents_status.langchain_version}
              </p>
              <p>{@sagents_status.termination}</p>
            </div>
          </div>

          <div class="mt-4 grid gap-4 xl:grid-cols-[0.85fr_1.15fr]">
            <div>
              <div class="join flex w-full" aria-label="Agentic mission">
                <button
                  :for={mission <- @agentic_missions}
                  id={"mission-#{mission.id}"}
                  type="button"
                  class={[
                    "btn join-item min-h-11 h-auto flex-1 whitespace-normal px-3 py-2 text-xs sm:text-sm",
                    if(@selected_mission.id == mission.id, do: "btn-primary", else: "btn-outline")
                  ]}
                  phx-click="select-agentic-mission"
                  phx-value-mission={mission.id}
                  disabled={@sagents_running?}
                >
                  {mission.title}
                </button>
              </div>

              <div class="mt-3 border-y border-base-300 py-3">
                <p class="text-xs font-semibold uppercase tracking-wide text-secondary">
                  Selected objective
                </p>
                <p class="mt-1 font-semibold">{@selected_mission.title}</p>
                <p class="mt-1 text-sm text-base-content/70">{@selected_mission.objective}</p>
              </div>

              <button
                id="run-agentic-mission"
                class="btn btn-primary mt-3 w-full"
                phx-click="run-agentic-mission"
                disabled={@sagents_running? || !@sagents_status.endpoint_configured?}
              >
                <.icon
                  name={if @sagents_running?, do: "hero-arrow-path", else: "hero-sparkles"}
                  class={if @sagents_running?, do: "animate-spin", else: nil}
                />
                {if @sagents_running?,
                  do: "Specialists deliberating",
                  else: "Run verified intervention"}
              </button>

              <p
                :if={@mission_phase == :deliberating}
                id="mission-deliberating"
                class="mt-2 text-center text-sm font-semibold text-primary"
              >
                Specialists deliberating
              </p>
              <p
                :if={!@sagents_status.endpoint_configured?}
                class="mt-2 text-sm text-error"
              >
                GEMMA_ENDPOINT is not configured.
              </p>
            </div>

            <div>
              <ol class="grid grid-cols-2 border-y border-base-300 sm:grid-cols-4">
                <li class="border-base-300 p-3 sm:border-r">
                  <p class="text-xs text-base-content/50">01</p>
                  <p class="text-sm font-semibold">Observe</p>
                </li>
                <li class="border-l border-base-300 p-3 sm:border-l-0 sm:border-r">
                  <p class="text-xs text-base-content/50">02</p>
                  <p class="text-sm font-semibold">Specialize</p>
                </li>
                <li class="border-t border-base-300 p-3 sm:border-r sm:border-t-0">
                  <p class="text-xs text-base-content/50">03</p>
                  <p class="text-sm font-semibold">Supervise</p>
                </li>
                <li class="border-l border-t border-base-300 p-3 sm:border-l-0 sm:border-t-0">
                  <p class="text-xs text-base-content/50">04</p>
                  <p class="text-sm font-semibold">Verify + act</p>
                </li>
              </ol>
              <dl class="mt-3 grid gap-3 sm:grid-cols-3">
                <div>
                  <dt class="text-xs text-base-content/60">Execution</dt>
                  <dd class="mt-1 font-mono text-xs">verify_ecosystem_safety</dd>
                </div>
                <div>
                  <dt class="text-xs text-base-content/60">Distribution</dt>
                  <dd class="mt-1 text-sm font-semibold">{@sagents_status.distribution}</dd>
                </div>
                <div>
                  <dt class="text-xs text-base-content/60">Gemma endpoint</dt>
                  <dd class="mt-1 text-sm font-semibold">
                    {if @sagents_status.endpoint_configured?, do: "ready", else: "not configured"}
                  </dd>
                </div>
              </dl>
            </div>
          </div>

          <div class="mt-4">
            <.loop_result result={@loop_result} />
          </div>
        </section>

        <section class="rounded-box border border-base-300 bg-base-100 p-4">
          <div class="mb-3 flex items-center justify-between gap-3">
            <h2 class="text-lg font-semibold">Anomaly forecast</h2>
            <span class={["badge", forecast_badge(@anomaly_forecast["risk_level"])]}>
              {@anomaly_forecast["risk_level"]}
            </span>
          </div>
          <.anomaly_forecast forecast={@anomaly_forecast} />
        </section>

        <section class="rounded-box border border-base-300 bg-base-100 p-4">
          <div class="mb-3 flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
            <div>
              <h2 class="text-lg font-semibold">Agent harness</h2>
              <p class="text-sm text-base-content/60">
                Proposals mutate state only after simulator verifier acceptance.
              </p>
            </div>
            <div class="flex flex-wrap items-center gap-2">
              <form id="agent-provider-form" phx-change="select-provider">
                <select name="provider" class="select select-sm" aria-label="Agent provider">
                  <option value="stub_safe" selected={@agent_provider == :stub_safe}>
                    safe stub
                  </option>
                  <option value="stub_unsafe" selected={@agent_provider == :stub_unsafe}>
                    unsafe stub
                  </option>
                  <option value="openai_compatible" selected={@agent_provider == :openai_compatible}>
                    OpenAI-compatible
                  </option>
                </select>
              </form>
              <button class="btn btn-sm btn-success" phx-click="agent-selected">
                <.icon name="hero-cpu-chip" /> Run selected
              </button>
              <button class="btn btn-sm btn-outline" phx-click="check-model">
                <.icon name="hero-signal" /> Check model
              </button>
              <button class="btn join-item btn-sm btn-error" phx-click="agent-unsafe">
                <.icon name="hero-no-symbol" /> Unsafe proposal
              </button>
            </div>
          </div>

          <div class="grid gap-3 xl:grid-cols-[1.2fr_0.55fr_0.65fr]">
            <.agent_result result={@agent_result} />
            <.trace_status status={@trace_status} />
            <.model_status status={@model_status} />
          </div>
          <.demo_result result={@demo_result} />
        </section>

        <section class="rounded-box border border-base-300 bg-base-100 p-4">
          <div class="mb-3 flex items-center justify-between gap-3">
            <h2 class="text-lg font-semibold">RLVR reward verifier</h2>
            <span class={[
              "badge",
              if(@rlvr_evaluation["available"], do: "badge-success", else: "badge-error")
            ]}>
              {if @rlvr_evaluation["available"], do: "online", else: "offline"}
            </span>
          </div>
          <.rlvr_panel evaluation={@rlvr_evaluation} training={@rlvr_training} />
        </section>

        <section class="rounded-box border border-base-300 bg-base-100 p-4">
          <div class="mb-3 flex items-center justify-between gap-3">
            <h2 class="text-lg font-semibold">Trace timeline</h2>
            <span class="badge badge-outline">{length(@trace_entries)} recent</span>
          </div>
          <.trace_timeline entries={@trace_entries} />
        </section>
      </section>
    </main>
    """
  end

  attr :label, :string, required: true
  attr :value, :any, required: true
  attr :detail, :any, default: nil
  attr :value_class, :string, default: "text-base-content"

  def metric_card(assigns) do
    ~H"""
    <article class="rounded-box border border-base-300 bg-base-100 p-4">
      <p class="text-sm text-base-content/60">{@label}</p>
      <p class={["mt-1 text-2xl font-semibold", @value_class]}>{@value}</p>
      <p class="mt-1 truncate text-sm text-base-content/60">{@detail}</p>
    </article>
    """
  end

  attr :name, :string, required: true
  attr :value, :any, required: true
  attr :unit, :string, required: true

  def organism(assigns) do
    ~H"""
    <div class="rounded-box bg-base-200 p-3">
      <p class="text-sm text-base-content/60">{@name}</p>
      <p class="text-xl font-semibold">
        {rounded(@value)} <span class="text-sm font-normal">{@unit}</span>
      </p>
    </div>
    """
  end

  attr :agent, :map, required: true

  def topology_agent(assigns) do
    assigns = assign(assigns, :badge_class, topology_badge_class(assigns.agent.status))

    ~H"""
    <article class="rounded-box bg-base-200 p-3">
      <div class="flex items-start justify-between gap-2">
        <div>
          <p class="font-semibold">{@agent.name}</p>
          <p class="text-sm text-base-content/60">{@agent.focus}</p>
        </div>
        <span class={["badge badge-sm", @badge_class]}>{@agent.status}</span>
      </div>
      <p class="mt-3 text-sm">{@agent.recommendation}</p>
      <div class="mt-3">
        <div class="mb-1 flex justify-between text-xs text-base-content/60">
          <span>tension</span>
          <span>{round(@agent.tension * 100)}%</span>
        </div>
        <progress class="progress progress-secondary h-2" value={@agent.tension * 100} max="100"></progress>
      </div>
    </article>
    """
  end

  defp topology_badge_class(:critical), do: "badge-error"
  defp topology_badge_class(:warning), do: "badge-warning"
  defp topology_badge_class(_status), do: "badge-success"

  attr :status, :map, required: true

  def horde_panel(assigns) do
    assigns =
      assigns
      |> assign(:distribution, display_value(assigns.status.distribution))
      |> assign(:membership, horde_membership(assigns.status))
      |> assign(:node_count, length(assigns.status.connected_nodes))
      |> assign(:agent_count, length(assigns.status.managed_agents))

    ~H"""
    <div id="horde-cluster-status" class="border-y border-base-300 py-3">
      <div class="mb-3 flex items-center justify-between gap-3">
        <h3 class="text-sm font-semibold">Real Sagents/Horde cluster</h3>
        <button class="btn btn-ghost btn-sm" phx-click="refresh-horde" title="Refresh Horde status">
          <.icon name="hero-arrow-path" /> Refresh
        </button>
      </div>
      <dl class="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
        <div>
          <dt class="text-xs text-base-content/60">Distribution</dt>
          <dd class="mt-1 text-sm font-semibold">{@distribution}</dd>
        </div>
        <div>
          <dt class="text-xs text-base-content/60">Membership</dt>
          <dd class="mt-1 text-sm font-semibold">{@membership}</dd>
        </div>
        <div>
          <dt class="text-xs text-base-content/60">BEAM nodes</dt>
          <dd class="mt-1 text-sm font-semibold">{@node_count} connected</dd>
        </div>
        <div>
          <dt class="text-xs text-base-content/60">Managed agents</dt>
          <dd class="mt-1 text-sm font-semibold">{@agent_count} managed</dd>
        </div>
      </dl>
      <div class="mt-3 flex flex-wrap gap-2">
        <span
          :for={node_name <- @status.connected_nodes}
          class="badge badge-outline max-w-full break-all font-mono"
        >
          {node_name}
        </span>
      </div>
    </div>
    """
  end

  defp horde_cluster_online?(status) do
    status.distribution in [:horde, "horde"] and length(status.connected_nodes) >= 2
  end

  defp horde_membership(status) do
    status.horde
    |> Map.get(:members, Map.get(status.horde, "members", :unconfigured))
    |> display_value()
  end

  defp display_value(value) when is_atom(value), do: Atom.to_string(value)
  defp display_value(value), do: to_string(value)

  attr :queue, :map, required: true

  def approval_queue(%{queue: %{pending: nil, decisions: []}} = assigns) do
    ~H"""
    <div class="rounded-box bg-base-200 p-3 text-sm text-base-content/60">
      No producer approval is pending.
    </div>
    """
  end

  def approval_queue(%{queue: %{pending: nil, decisions: [latest | _]}} = assigns) do
    assigns = assign(assigns, :latest, latest)

    ~H"""
    <div class="rounded-box bg-base-200 p-3">
      <p class="text-sm text-base-content/60">Latest producer decision</p>
      <p class="mt-1 text-lg font-semibold">{@latest.status}</p>
      <p class="mt-1 font-mono text-sm">
        water={@latest.action["water_exchange_fraction"] * 100}% harvest={@latest.action[
          "duckweed_harvest_kg"
        ]}kg
      </p>
    </div>
    """
  end

  def approval_queue(assigns) do
    ~H"""
    <div class="grid gap-3 md:grid-cols-[1.1fr_0.9fr]">
      <div class="rounded-box bg-warning/10 p-3">
        <p class="text-sm text-warning">Producer decision pending</p>
        <p class="mt-1 font-semibold">{@queue.pending.prompt}</p>
        <p class="mt-2 text-sm text-base-content/70">{@queue.pending.rationale}</p>
      </div>
      <div class="rounded-box bg-base-200 p-3">
        <p class="text-sm text-base-content/60">Queued action</p>
        <p class="mt-1 font-mono text-sm">
          water={@queue.pending.action["water_exchange_fraction"] * 100}% harvest={@queue.pending.action[
            "duckweed_harvest_kg"
          ]}kg
        </p>
        <.link navigate={~p"/producer"} class="btn btn-sm btn-outline mt-3">
          <.icon name="hero-language" /> Open producer view
        </.link>
      </div>
    </div>
    """
  end

  attr :result, :any, required: true

  def loop_result(%{result: nil} = assigns) do
    ~H"""
    <div class="border-t border-base-300 pt-3 text-sm text-base-content/60">
      No intelligence receipt yet. Run the selected mission to produce a verified intervention.
    </div>
    """
  end

  def loop_result(%{result: %{framework: "sagents"} = result} = assigns) do
    verification = Map.get(result, :verification, %{})

    assigns =
      assigns
      |> assign(:before_state, Map.get(result, :before_state, %{}))
      |> assign(:mission, Map.get(result, :mission, "Operator-directed ecosystem recovery"))
      |> assign(:verification, verification)
      |> assign(:verified?, Map.get(verification, "ok", false))
      |> assign(:violations, verification_messages(verification, "violations"))
      |> assign(:warnings, verification_messages(verification, "warnings"))

    ~H"""
    <div id="intelligence-receipt" class="border-t border-base-300 pt-4">
      <div class="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <div class="flex flex-wrap items-center gap-2">
            <h3 class="text-lg font-semibold">Intelligence receipt</h3>
            <span class={[
              "badge",
              if(@verified?, do: "badge-success", else: "badge-error")
            ]}>
              {if @verified?, do: "Verifier accepted", else: "Verifier rejected"}
            </span>
            <span class="badge badge-outline">{@result.tool}</span>
          </div>
          <p class="mt-1 max-w-3xl text-sm text-base-content/70">{@mission}</p>
        </div>
        <p class="whitespace-nowrap text-sm font-semibold">
          Day {@result.state["day"]} / reward {@result.reward}
        </p>
      </div>

      <section class="mt-4 border-y border-base-300 py-3" aria-label="State change">
        <div class="mb-3 flex items-center justify-between gap-3">
          <h4 class="text-sm font-semibold">Observed outcome</h4>
          <span class="text-xs text-base-content/60">before / after</span>
        </div>
        <dl class="grid gap-3 sm:grid-cols-3">
          <div class="grid grid-cols-[1fr_auto] gap-x-3">
            <dt class="col-span-2 text-xs text-base-content/60">Ammonia</dt>
            <dd class="mt-1 text-sm line-through opacity-60">
              {rounded(metric(@before_state, "ammonia_mg_l"))} mg/L
            </dd>
            <dd class={[
              "mt-1 text-right font-semibold",
              risk_class(metric(@result.state, "ammonia_mg_l"), 1.5, 3.0)
            ]}>
              {rounded(metric(@result.state, "ammonia_mg_l"))} mg/L
            </dd>
          </div>
          <div class="grid grid-cols-[1fr_auto] gap-x-3">
            <dt class="col-span-2 text-xs text-base-content/60">Dissolved oxygen</dt>
            <dd class="mt-1 text-sm line-through opacity-60">
              {rounded(metric(@before_state, "dissolved_oxygen_mg_l"))} mg/L
            </dd>
            <dd class={[
              "mt-1 text-right font-semibold",
              oxygen_class(metric(@result.state, "dissolved_oxygen_mg_l"))
            ]}>
              {rounded(metric(@result.state, "dissolved_oxygen_mg_l"))} mg/L
            </dd>
          </div>
          <div class="grid grid-cols-[1fr_auto] gap-x-3">
            <dt class="col-span-2 text-xs text-base-content/60">Simulation day</dt>
            <dd class="mt-1 text-sm line-through opacity-60">
              Day {metric(@before_state, "day")}
            </dd>
            <dd class="mt-1 text-right font-semibold">Day {metric(@result.state, "day")}</dd>
          </div>
        </dl>
      </section>

      <section class="mt-4" aria-label="Specialist recommendations">
        <div class="mb-2 flex items-center justify-between gap-3">
          <h4 class="text-sm font-semibold">4 specialist briefs</h4>
          <span class="text-xs text-base-content/60">parallel recommendations</span>
        </div>
        <ol class="divide-y divide-base-300 border-y border-base-300">
          <li
            :for={subagent <- @result.subagents}
            class="grid gap-2 py-3 md:grid-cols-[0.55fr_1.45fr_0.75fr] md:items-start md:gap-4"
          >
            <div class="flex items-center gap-2">
              <span class={[
                "badge badge-sm",
                specialist_status_badge(subagent.report["status"])
              ]}>
                {subagent.report["status"]}
              </span>
              <div>
                <p class="text-sm font-semibold">{specialist_name(subagent.name)}</p>
                <p class="font-mono text-xs text-base-content/50">{subagent.name}</p>
              </div>
            </div>
            <div>
              <p class="text-xs text-base-content/60">Recommendation</p>
              <p class="mt-1 text-sm font-medium">{subagent.report["recommendation"]}</p>
            </div>
            <div>
              <p class="text-xs text-base-content/60">Resource request</p>
              <p class="mt-1 text-sm">{subagent.report["resource_request"]}</p>
            </div>
          </li>
        </ol>
      </section>

      <div class="mt-4 grid gap-4 lg:grid-cols-[1.25fr_0.75fr]">
        <section class="border-l-4 border-primary pl-4" aria-label="Supervisor plan">
          <h4 class="text-sm font-semibold">Supervisor plan</h4>
          <p class="mt-1 text-base font-semibold">{@result.action["note"]}</p>
          <dl class="mt-3 grid grid-cols-2 gap-x-4 gap-y-2 sm:grid-cols-4">
            <div>
              <dt class="text-xs text-base-content/60">Feed</dt>
              <dd class="font-mono text-sm">{@result.action["feed_kg"]} kg</dd>
            </div>
            <div>
              <dt class="text-xs text-base-content/60">Aeration</dt>
              <dd class="font-mono text-sm">{@result.action["aeration_hours"]} h</dd>
            </div>
            <div>
              <dt class="text-xs text-base-content/60">Water exchange</dt>
              <dd class="font-mono text-sm">
                {@result.action["water_exchange_fraction"] * 100}%
              </dd>
            </div>
            <div>
              <dt class="text-xs text-base-content/60">Duckweed harvest</dt>
              <dd class="font-mono text-sm">{@result.action["duckweed_harvest_kg"]} kg</dd>
            </div>
          </dl>
        </section>

        <section class="border-l border-base-300 pl-4" aria-label="Verifier receipt">
          <div class="flex items-center gap-2">
            <.icon
              name={if @verified?, do: "hero-shield-check", else: "hero-x-circle"}
              class={["size-5", if(@verified?, do: "text-success", else: "text-error")]}
            />
            <h4 class="text-sm font-semibold">
              {if @verified?, do: "Verifier accepted", else: "Verifier rejected"}
            </h4>
          </div>
          <dl class="mt-2 grid grid-cols-3 gap-2 text-sm">
            <div>
              <dt class="text-xs text-base-content/60">Violations</dt>
              <dd class="font-semibold">{verification_count(@verification, "violations")}</dd>
            </div>
            <div>
              <dt class="text-xs text-base-content/60">Warnings</dt>
              <dd class="font-semibold">{verification_count(@verification, "warnings")}</dd>
            </div>
            <div>
              <dt class="text-xs text-base-content/60">Reward</dt>
              <dd class="font-semibold">{@result.reward}</dd>
            </div>
          </dl>
          <ul :if={@violations != []} class="mt-3 space-y-1 text-xs text-error">
            <li :for={violation <- @violations} class="flex items-start gap-1.5">
              <.icon name="hero-x-circle" class="mt-0.5 size-3.5 shrink-0" />
              <span>{violation}</span>
            </li>
          </ul>
          <ul :if={@warnings != []} class="mt-3 space-y-1 text-xs text-warning">
            <li :for={warning <- @warnings} class="flex items-start gap-1.5">
              <.icon name="hero-exclamation-triangle" class="mt-0.5 size-3.5 shrink-0" />
              <span>{warning}</span>
            </li>
          </ul>
          <p class="mt-2 font-mono text-xs text-base-content/60">{@result.tool}</p>
        </section>
      </div>
    </div>
    """
  end

  def loop_result(%{result: %{tool_result: tool_result}} = assigns) when is_map(tool_result) do
    ~H"""
    <div class="grid gap-3 xl:grid-cols-[0.7fr_1.3fr]">
      <div class="rounded-box bg-base-200 p-3">
        <p class="text-sm text-base-content/60">until_tool</p>
        <p class="mt-1 text-lg font-semibold">{@result.tool_result["tool"]}</p>
        <p class="mt-1 text-sm">
          day={@result.tool_result["content"]["final_day"]} reward={@result.tool_result["content"][
            "latest_reward"
          ]}
        </p>
      </div>
      <.loop_steps steps={@result.steps} />
    </div>
    """
  end

  def loop_result(assigns) do
    ~H"""
    <div class="grid gap-3 xl:grid-cols-[0.7fr_1.3fr]">
      <div class="rounded-box bg-error/10 p-3">
        <p class="text-sm text-error">Loop stopped</p>
        <p class="mt-1 text-lg font-semibold">
          {Map.get(@result, :reason) || Map.get(@result, :error, %{})["error"] || "rejected"}
        </p>
      </div>
      <.loop_steps steps={@result.steps || []} />
    </div>
    """
  end

  attr :steps, :list, required: true

  def loop_steps(assigns) do
    ~H"""
    <ol class="rounded-box bg-base-200 p-3">
      <li :for={step <- @steps} class="flex flex-wrap items-center justify-between gap-2 py-1 text-sm">
        <span class="font-mono">{step.name}</span>
        <span class={[
          "badge badge-sm",
          if(step.status in ["accepted", "mutated", "completed"],
            do: "badge-success",
            else: "badge-warning"
          )
        ]}>
          {step.status}
        </span>
      </li>
    </ol>
    """
  end

  attr :mesh, :map, required: true

  def mesh_panel(assigns) do
    ~H"""
    <div class="grid gap-3 xl:grid-cols-[0.9fr_1.1fr_0.7fr]">
      <div class="rounded-box bg-base-200 p-3">
        <p class="mb-2 text-sm font-semibold text-base-content/60">Nodes</p>
        <div class="space-y-2">
          <div
            :for={node <- @mesh.nodes}
            class="flex items-center justify-between gap-2 rounded-box bg-base-100 p-2"
          >
            <div>
              <p class="font-semibold">{node.label}</p>
              <p class="text-xs text-base-content/60">{node.role}</p>
            </div>
            <span class={[
              "badge badge-sm",
              if(node.online?, do: "badge-success", else: "badge-error")
            ]}>
              {if node.online?, do: "online", else: "offline"}
            </span>
          </div>
        </div>
      </div>

      <div class="rounded-box bg-base-200 p-3">
        <p class="mb-2 text-sm font-semibold text-base-content/60">Agent placement</p>
        <div class="grid gap-2 md:grid-cols-2">
          <div :for={agent <- @mesh.agents} class="rounded-box bg-base-100 p-2">
            <div class="flex items-center justify-between gap-2">
              <p class="font-semibold">{agent.label}</p>
              <span class="badge badge-sm badge-info">m{agent.migrations}</span>
            </div>
            <p class="mt-1 font-mono text-xs text-base-content/60">{agent.node_id}</p>
            <p class="mt-1 truncate font-mono text-xs text-base-content/50">{agent.state_token}</p>
          </div>
        </div>
      </div>

      <div class="rounded-box bg-base-200 p-3">
        <p class="mb-2 text-sm font-semibold text-base-content/60">Mesh events</p>
        <ol class="space-y-2">
          <li :for={event <- @mesh.events} class="flex items-start gap-2 text-sm">
            <.icon name="hero-signal" class="mt-0.5 size-4 text-info" />
            <span>{event}</span>
          </li>
        </ol>
      </div>
    </div>
    """
  end

  attr :result, :any, required: true

  def agent_result(%{result: nil} = assigns) do
    ~H"""
    <div class="rounded-box bg-base-200 p-3 text-sm text-base-content/60">
      No agent proposal has been submitted yet.
    </div>
    """
  end

  def agent_result(assigns) do
    ~H"""
    <div class="grid gap-3 md:grid-cols-2">
      <div class="rounded-box bg-base-200 p-3">
        <p class="text-sm text-base-content/60">Proposal</p>
        <p class="mt-1 font-mono text-sm">
          feed={@result.action["feed_kg"]}kg aeration={@result.action["aeration_hours"]}h water={@result.action[
            "water_exchange_fraction"
          ] * 100}%
        </p>
        <p class="mt-2 text-sm">{@result.metadata.rationale}</p>
      </div>
      <div class="rounded-box bg-base-200 p-3">
        <p class="text-sm text-base-content/60">Verifier result</p>
        <p class={[
          "mt-1 text-lg font-semibold",
          if(@result.accepted?, do: "text-success", else: "text-error")
        ]}>
          {if @result.accepted?, do: "accepted", else: "rejected"}
        </p>
        <p :if={!@result.accepted?} class="mt-2 text-sm">
          {Enum.join(@result.verification["violations"], "; ")}
        </p>
        <p :if={@result.accepted?} class="mt-2 text-sm">
          reward={@result.reward}
        </p>
      </div>
    </div>
    """
  end

  attr :status, :map, required: true

  def trace_status(assigns) do
    ~H"""
    <div class="rounded-box bg-base-200 p-3">
      <p class="text-sm text-base-content/60">RLVR trace artifact</p>
      <p class="mt-1 text-2xl font-semibold">{@status.count}</p>
      <p class="mt-1 break-all font-mono text-xs text-base-content/60">{@status.path}</p>
    </div>
    """
  end

  attr :status, :map, required: true

  def model_status(assigns) do
    assigns = assign(assigns, :badge_class, model_badge_class(assigns.status.status))

    ~H"""
    <div class="rounded-box bg-base-200 p-3">
      <div class="flex items-center justify-between gap-2">
        <p class="text-sm text-base-content/60">Model endpoint</p>
        <span class={["badge badge-sm", @badge_class]}>{@status.label}</span>
      </div>
      <p class="mt-1 font-mono text-sm">{@status.model}</p>
      <p class="mt-1 break-all text-xs text-base-content/60">
        {@status.endpoint || "GEMMA_ENDPOINT unset"}
      </p>
      <p class="mt-2 text-xs text-base-content/70">{@status.detail}</p>
      <p :if={@status.model_count} class="mt-1 text-xs text-base-content/60">
        models={@status.model_count}
      </p>
    </div>
    """
  end

  defp model_badge_class(:ok), do: "badge-success"
  defp model_badge_class(:auth_required), do: "badge-warning"
  defp model_badge_class(:not_checked), do: "badge-info"
  defp model_badge_class(_status), do: "badge-error"

  defp forecast_badge("stable"), do: "badge-success"
  defp forecast_badge("warning"), do: "badge-warning"
  defp forecast_badge("critical"), do: "badge-error"
  defp forecast_badge(_risk), do: "badge-ghost"

  attr :forecast, :map, required: true

  def anomaly_forecast(assigns) do
    ~H"""
    <div class="grid gap-3 xl:grid-cols-[0.7fr_1.3fr]">
      <div class="rounded-box bg-base-200 p-3">
        <p class="text-sm text-base-content/60">Near-term risk</p>
        <p class="mt-1 text-2xl font-semibold">{@forecast["risk_level"]}</p>
        <p class="mt-2 text-sm">{@forecast["recommendation"]}</p>
        <p :if={@forecast["first_critical_day"]} class="mt-2 text-sm text-error">
          first critical day={@forecast["first_critical_day"]}
        </p>
      </div>
      <div class="grid gap-3 md:grid-cols-3">
        <div class="rounded-box bg-base-200 p-3">
          <p class="text-sm text-base-content/60">Max ammonia</p>
          <p class="mt-1 text-xl font-semibold">
            {forecast_value(@forecast["max_ammonia_mg_l"])} mg/L
          </p>
        </div>
        <div class="rounded-box bg-base-200 p-3">
          <p class="text-sm text-base-content/60">Min oxygen</p>
          <p class="mt-1 text-xl font-semibold">
            {forecast_value(@forecast["min_oxygen_mg_l"])} mg/L
          </p>
        </div>
        <div class="rounded-box bg-base-200 p-3">
          <p class="text-sm text-base-content/60">Horizon</p>
          <p class="mt-1 text-xl font-semibold">{@forecast["horizon_days"] || 0} days</p>
        </div>
      </div>
    </div>
    """
  end

  defp forecast_value(nil), do: "n/a"
  defp forecast_value(value), do: value

  attr :evaluation, :map, required: true
  attr :training, :map, required: true

  def rlvr_panel(assigns) do
    ~H"""
    <div class="grid gap-3 md:grid-cols-4">
      <div class="rounded-box bg-base-200 p-3">
        <p class="text-sm text-base-content/60">Reward delta</p>
        <p class="text-2xl font-semibold text-success">
          {rlvr_value(@evaluation["average_reward_delta"])}
        </p>
      </div>
      <div class="rounded-box bg-base-200 p-3">
        <p class="text-sm text-base-content/60">Recovered</p>
        <p class="text-2xl font-semibold">
          {@evaluation["recovered_scenarios"] || 0}/{@evaluation["scenario_count"] || 0}
        </p>
      </div>
      <div class="rounded-box bg-base-200 p-3">
        <p class="text-sm text-base-content/60">Collapse avoidance</p>
        <p class="text-2xl font-semibold">
          {rlvr_percent(@evaluation["collapse_avoidance_rate"])}
        </p>
      </div>
      <div class="rounded-box bg-base-200 p-3">
        <p class="text-sm text-base-content/60">Policy comparison</p>
        <p class="mt-1 font-mono text-sm">
          {@evaluation["baseline_policy"]} -> {@evaluation["candidate_policy"]}
        </p>
      </div>
    </div>

    <div class="mt-4 grid gap-3 md:grid-cols-3">
      <div class="rounded-box bg-base-200 p-3">
        <p class="text-sm text-base-content/60">Policy search improvement</p>
        <p class="text-2xl font-semibold text-success">
          {rlvr_value(@training["improvement"])}
        </p>
      </div>
      <div class="rounded-box bg-base-200 p-3">
        <p class="text-sm text-base-content/60">Best policy</p>
        <p class="mt-1 font-mono text-sm">
          {get_in(@training, ["best_policy", "name"]) || "pending"}
        </p>
      </div>
      <div class="rounded-box bg-base-200 p-3">
        <p class="text-sm text-base-content/60">Search method</p>
        <p class="mt-1 font-mono text-sm">
          {@training["method"] || "pending"}
        </p>
      </div>
    </div>

    <div class="mt-3 overflow-x-auto">
      <table class="table table-sm">
        <thead>
          <tr>
            <th>Scenario</th>
            <th>Baseline</th>
            <th>Candidate</th>
            <th>Delta</th>
          </tr>
        </thead>
        <tbody>
          <tr :for={scenario <- @evaluation["scenarios"] || []}>
            <td>{scenario["name"]}</td>
            <td>
              reward={scenario["baseline"]["reward"]}
              <span :if={scenario["baseline"]["collapsed"]} class="badge badge-xs badge-error">collapsed</span>
            </td>
            <td>
              reward={scenario["candidate"]["reward"]}
              <span :if={!scenario["candidate"]["collapsed"]} class="badge badge-xs badge-success">stable</span>
            </td>
            <td class="font-semibold text-success">{scenario["reward_delta"]}</td>
          </tr>
        </tbody>
      </table>
      <p :if={!@evaluation["available"]} class="mt-2 text-sm text-error">
        RLVR evaluation unavailable: {@evaluation["error"]}
      </p>
    </div>

    <div class="mt-4 overflow-x-auto">
      <table class="table table-sm">
        <thead>
          <tr>
            <th>Iteration</th>
            <th>Policy</th>
            <th>Reward</th>
            <th>Best so far</th>
          </tr>
        </thead>
        <tbody>
          <tr :for={iteration <- @training["iterations"] || []}>
            <td>{iteration["iteration"]}</td>
            <td>{get_in(iteration, ["policy", "name"])}</td>
            <td>{iteration["average_reward"]}</td>
            <td class="font-semibold text-success">{iteration["best_so_far_reward"]}</td>
          </tr>
        </tbody>
      </table>
      <p :if={!@training["available"]} class="mt-2 text-sm text-error">
        RLVR policy search unavailable: {@training["error"]}
      </p>
    </div>
    """
  end

  defp rlvr_value(nil), do: "pending"
  defp rlvr_value(value), do: value

  defp rlvr_percent(nil), do: "pending"
  defp rlvr_percent(value) when is_float(value), do: "#{round(value * 100)}%"
  defp rlvr_percent(value) when is_integer(value), do: "#{value * 100}%"
  defp rlvr_percent(value), do: value

  attr :result, :any, required: true

  def demo_result(%{result: nil} = assigns) do
    ~H"""
    <div class="mt-3 rounded-box bg-base-200 p-3 text-sm text-base-content/60">
      Demo cascade has not run yet.
    </div>
    """
  end

  def demo_result(assigns) do
    ~H"""
    <div class="mt-3 grid gap-3 md:grid-cols-3">
      <div class="rounded-box bg-base-200 p-3">
        <p class="text-sm text-base-content/60">Spike</p>
        <p class="text-xl font-semibold text-warning">
          {@result.spike_state["ammonia_mg_l"]} mg/L
        </p>
      </div>
      <div class="rounded-box bg-base-200 p-3">
        <p class="text-sm text-base-content/60">Unsafe proposal</p>
        <p class="text-xl font-semibold text-error">
          rejected
        </p>
      </div>
      <div class="rounded-box bg-base-200 p-3">
        <p class="text-sm text-base-content/60">Safe recovery</p>
        <p class="text-xl font-semibold text-success">
          reward={@result.safe_result.reward}
        </p>
      </div>
    </div>
    """
  end

  attr :entries, :list, required: true

  def trace_timeline(%{entries: []} = assigns) do
    ~H"""
    <div class="rounded-box bg-base-200 p-3 text-sm text-base-content/60">
      No verifier traces recorded yet.
    </div>
    """
  end

  def trace_timeline(assigns) do
    ~H"""
    <ol class="space-y-2">
      <li :for={entry <- @entries} class="rounded-box bg-base-200 p-3">
        <div class="flex flex-wrap items-center justify-between gap-2">
          <div class="flex items-center gap-2">
            <span class={[
              "badge",
              if(entry["accepted"], do: "badge-success", else: "badge-error")
            ]}>
              {if entry["accepted"], do: "accepted", else: "rejected"}
            </span>
            <span class="font-semibold">{entry["provider"]}</span>
          </div>
          <span class="text-xs text-base-content/60">{entry["timestamp"]}</span>
        </div>
        <p class="mt-2 font-mono text-sm">
          feed={entry["action"]["feed_kg"]}kg aeration={entry["action"]["aeration_hours"]}h water={entry[
            "action"
          ]["water_exchange_fraction"] * 100}%
        </p>
        <p :if={entry["accepted"]} class="mt-1 text-sm text-success">
          reward={entry["reward"]}
        </p>
        <p :if={!entry["accepted"]} class="mt-1 text-sm text-error">
          {entry["verification"]["violations"] |> Enum.join("; ")}
        </p>
      </li>
    </ol>
    """
  end
end
