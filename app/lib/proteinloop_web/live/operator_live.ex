defmodule ProteinLoopWeb.OperatorLive do
  use ProteinLoopWeb, :live_view

  import ProteinLoopWeb.RealtimeTankScene

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

  @activity_specialists [
    %{
      id: "fish-tank",
      label: "Fish",
      focus: "oxygen and feed",
      icon: "hero-heart"
    },
    %{
      id: "freshwater-prawn",
      label: "Prawns",
      focus: "oxygen and shelter",
      icon: "hero-sparkles"
    },
    %{
      id: "hydroponia",
      label: "Plants",
      focus: "nutrient uptake",
      icon: "hero-sun"
    },
    %{
      id: "duckweed-chickens",
      label: "Feed loop",
      focus: "duckweed and eggs",
      icon: "hero-arrow-path"
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
      |> assign(:agent_run_id, nil)
      |> assign(:agent_activity, ready_agent_activity())
      |> assign(:hitl_running?, false)
      |> assign(:agent_provider, :stub_safe)
      |> assign(:horde_status, horde_runtime().cluster_status())
      |> assign(:nrf9151_evidence, nrf9151_evidence().snapshot())
      |> assign(:amd_experiment, amd_experiment_evidence().snapshot())
      |> assign(:mesh, Mesh.initial())
      |> assign(:approval_queue, ApprovalQueue.snapshot())
      |> assign(:model_status, ModelStatus.snapshot())
      |> assign(:rlvr_evaluation, rlvr_evaluation)
      |> assign(:rlvr_training, rlvr_training)
      |> assign(:anomaly_forecast, anomaly_forecast)
      |> assign(:trace_status, TraceStore.status())
      |> assign(:trace_entries, trace_entries())
      |> assign(:advanced_evidence_open?, false)
      |> assign(:action_log, ["dashboard mounted"])

    {:ok, socket}
  end

  @impl true
  def handle_info({:sagents_progress, run_id, event}, socket) do
    if socket.assigns.sagents_running? && socket.assigns.agent_run_id == run_id do
      {:noreply,
       assign(
         socket,
         :agent_activity,
         update_agent_activity(socket.assigns.agent_activity, event)
       )}
    else
      {:noreply, socket}
    end
  end

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

  def handle_event("toggle-advanced-evidence", _params, socket) do
    {:noreply,
     assign(
       socket,
       :advanced_evidence_open?,
       !socket.assigns.advanced_evidence_open?
     )}
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

              socket
              |> clear_recovery_receipts()
              |> assign_snapshot(
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

          socket
          |> clear_recovery_receipts()
          |> assign_snapshot(snapshot, "ammonia spike injected")

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

          socket
          |> clear_recovery_receipts()
          |> assign_snapshot(snapshot, "safety action applied")

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

          socket
          |> clear_recovery_receipts()
          |> assign_snapshot(snapshot, "scenario reset")

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
        |> assign(:demo_result, nil)
        |> assign(:mission_phase, :ready)
        |> assign(:agent_run_id, nil)
        |> assign(:agent_activity, ready_agent_activity())
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
      case demo_cascade().run() do
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
          |> assign(:loop_result, nil)
          |> assign(:mission_phase, :ready)
          |> assign(:agent_run_id, nil)
          |> assign(:agent_activity, ready_agent_activity())
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
     |> assign(:agent_activity, completed_agent_activity(socket.assigns.agent_activity, result))
     |> assign(:loop_result, result)
     |> assign_snapshot(snapshot, "real Sagents cycle completed")}
  end

  def handle_async(:sagents_cycle, {:ok, {:error, reason}}, socket) do
    {:noreply,
     socket
     |> assign(:sagents_running?, false)
     |> assign(:mission_phase, :failed)
     |> assign(:agent_activity, failed_agent_activity(socket.assigns.agent_activity))
     |> put_flash(:error, "Sagents error: #{inspect(reason)}")}
  end

  def handle_async(:sagents_cycle, {:exit, reason}, socket) do
    {:noreply,
     socket
     |> assign(:sagents_running?, false)
     |> assign(:mission_phase, :failed)
     |> assign(:agent_activity, failed_agent_activity(socket.assigns.agent_activity))
     |> put_flash(:error, "Sagents task exited: #{inspect(reason)}")}
  end

  def handle_async(:sagents_hitl, {:ok, {:interrupt, pending}}, socket) do
    [action_request | _rest] = pending.interrupt_data.action_requests

    queue_result =
      ApprovalQueue.request(action_request.arguments,
        rationale: "Sagents HumanInTheLoop paused the action before simulator mutation",
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
        run_id = make_ref()
        live_view = self()
        progress_fun = fn event -> send(live_view, {:sagents_progress, run_id, event}) end

        socket
        |> assign(:sagents_running?, true)
        |> assign(:demo_result, nil)
        |> assign(:loop_result, nil)
        |> assign(:mission_phase, :deliberating)
        |> assign(:agent_run_id, run_id)
        |> assign(:agent_activity, observing_agent_activity(mission, socket.assigns.state))
        |> update(:action_log, fn log ->
          Enum.take(["agentic mission started: #{mission.title}" | log], 6)
        end)
        |> start_async(:sagents_cycle, fn ->
          runtime.run(mission: mission.objective, progress_fun: progress_fun)
        end)

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

  defp clear_recovery_receipts(socket) do
    socket
    |> assign(:demo_result, nil)
    |> assign(:loop_result, nil)
    |> assign(:mission_phase, :ready)
    |> assign(:agent_run_id, nil)
    |> assign(:agent_activity, ready_agent_activity())
  end

  defp ready_agent_activity do
    %{
      phase: :ready,
      title: "5-agent team standing by",
      detail: "Choose a recovery goal to start live Gemma planning.",
      specialists: activity_specialists(),
      events: []
    }
  end

  defp observing_agent_activity(mission, state) do
    %{
      phase: :observing,
      title: "Reading live tank telemetry",
      detail:
        "#{activity_metric(state, "ammonia_mg_l")} mg/L ammonia · #{activity_metric(state, "dissolved_oxygen_mg_l")} mg/L oxygen",
      specialists: activity_specialists(),
      events: [
        %{
          title: "Mission accepted",
          detail: mission.title,
          status: :running
        }
      ]
    }
  end

  defp completed_agent_activity(activity, result) do
    reports = Map.new(result.subagents, &{&1.name, &1.report})

    specialists =
      Enum.map(activity.specialists, fn specialist ->
        case Map.get(reports, specialist.id) do
          nil -> specialist
          report -> Map.merge(specialist, %{status: :completed, report: report})
        end
      end)

    activity
    |> Map.merge(%{
      phase: :completed,
      title: "Verified recovery completed",
      detail:
        "Ammonia #{activity_metric(result.state, "ammonia_mg_l")} mg/L · oxygen #{activity_metric(result.state, "dissolved_oxygen_mg_l")} mg/L · reward #{result.reward}",
      specialists: specialists
    })
    |> add_activity_event(%{
      title: "Measured outcome received",
      detail: "Simulator state changed only after verifier acceptance.",
      status: :completed
    })
  end

  defp failed_agent_activity(activity) do
    specialists =
      Enum.map(activity.specialists, fn
        %{status: :running} = specialist -> Map.put(specialist, :status, :failed)
        specialist -> specialist
      end)

    activity
    |> Map.merge(%{
      phase: :failed,
      title: "Mission stopped safely",
      detail: "No rejected or failed proposal was applied to the ecosystem.",
      specialists: specialists
    })
    |> add_activity_event(%{
      title: "Run stopped",
      detail: "Simulator mutation remained blocked.",
      status: :failed
    })
  end

  defp update_agent_activity(activity, {:state_observed, state}) do
    activity
    |> Map.merge(%{
      phase: :observing,
      title: "Reading live tank telemetry",
      detail:
        "#{activity_metric(state, :ammonia_mg_l)} mg/L ammonia · #{activity_metric(state, :dissolved_oxygen_mg_l)} mg/L oxygen · day #{activity_metric(state, :day)}"
    })
    |> add_activity_event(%{
      title: "Live ecosystem state captured",
      detail: "Gemma specialists received the same current tank snapshot.",
      status: :completed
    })
  end

  defp update_agent_activity(activity, {:specialist_started, id}) do
    specialist = activity_specialist(id)

    activity
    |> Map.merge(%{
      phase: :specialists,
      title: "#{specialist.label} specialist is evaluating #{specialist.focus}",
      detail: "Four Gemma specialists are producing structured briefs in parallel."
    })
    |> update_activity_specialist(id, %{status: :running})
    |> add_activity_event(%{
      title: "#{specialist.label} specialist started",
      detail: specialist.focus,
      status: :running
    })
  end

  defp update_agent_activity(activity, {:specialist_completed, id, report}) do
    specialist = activity_specialist(id)

    activity
    |> Map.merge(%{
      phase: :specialists,
      title: "#{specialist.label} structured brief received",
      detail: Map.get(report, "recommendation", "Structured recommendation received.")
    })
    |> update_activity_specialist(id, %{status: :completed, report: report})
    |> add_activity_event(%{
      title: "#{specialist.label} brief received",
      detail: Map.get(report, "recommendation", "Structured recommendation received."),
      status: :completed
    })
  end

  defp update_agent_activity(activity, {:specialist_failed, id}) do
    specialist = activity_specialist(id)

    activity
    |> Map.merge(%{
      phase: :failed,
      title: "#{specialist.label} specialist stopped",
      detail: "The mission will not apply an incomplete proposal."
    })
    |> update_activity_specialist(id, %{status: :failed})
    |> add_activity_event(%{
      title: "#{specialist.label} specialist failed",
      detail: "No ecosystem action applied.",
      status: :failed
    })
  end

  defp update_agent_activity(activity, {:supervisor_started, %{specialist_count: count}}) do
    activity
    |> Map.merge(%{
      phase: :supervising,
      title: "Supervisor comparing four specialist briefs",
      detail: "#{count} structured recommendations are being combined into one bounded action."
    })
    |> add_activity_event(%{
      title: "Supervisor synthesis started",
      detail: "Gemma is selecting one conservative action proposal.",
      status: :running
    })
  end

  defp update_agent_activity(activity, {:verification_started, _action}) do
    activity
    |> Map.merge(%{
      phase: :verifying,
      title: "Deterministic safety rules checking the proposal",
      detail:
        "Python verifies feed, aeration, water exchange, and duckweed limits before mutation."
    })
    |> add_activity_event(%{
      title: "Verifier preflight started",
      detail: "The model cannot bypass these ecosystem rules.",
      status: :running
    })
  end

  defp update_agent_activity(activity, {:verification_completed, verification}) do
    accepted? = Map.get(verification, :ok, false)

    activity
    |> Map.merge(%{
      phase: if(accepted?, do: :verified, else: :failed),
      title:
        if(accepted?,
          do: "Safety verifier accepted the proposal",
          else: "Safety verifier blocked the proposal"
        ),
      detail:
        if(accepted?,
          do: "No deterministic safety violations were found.",
          else: "No rejected proposal will reach the simulator."
        )
    })
    |> add_activity_event(%{
      title: if(accepted?, do: "Verifier accepted", else: "Verifier rejected"),
      detail:
        "#{length(Map.get(verification, :violations, []))} violations · #{length(Map.get(verification, :warnings, []))} warnings",
      status: if(accepted?, do: :completed, else: :failed)
    })
  end

  defp update_agent_activity(activity, {:action_application_started, _action}) do
    activity
    |> Map.merge(%{
      phase: :applying,
      title: "Applying the verified intervention",
      detail: "The simulator is executing only the action admitted by the safety verifier."
    })
    |> add_activity_event(%{
      title: "Verified action admitted",
      detail: "Simulator mutation started.",
      status: :running
    })
  end

  defp update_agent_activity(activity, {:action_application_completed, result}) do
    activity
    |> Map.merge(%{
      phase: :measuring,
      title: "Measuring the ecosystem response",
      detail:
        "Day #{activity_metric(result, :day)} · ammonia #{activity_metric(result, :ammonia_mg_l)} mg/L · oxygen #{activity_metric(result, :dissolved_oxygen_mg_l)} mg/L"
    })
    |> add_activity_event(%{
      title: "New simulator state received",
      detail: "Reward #{activity_metric(result, :reward)}",
      status: :completed
    })
  end

  defp update_agent_activity(activity, _event), do: activity

  defp activity_specialists do
    Enum.map(@activity_specialists, &Map.merge(&1, %{status: :waiting, report: nil}))
  end

  defp activity_specialist(id) do
    Enum.find(@activity_specialists, hd(@activity_specialists), &(&1.id == id))
  end

  defp update_activity_specialist(activity, id, changes) do
    specialists =
      Enum.map(activity.specialists, fn specialist ->
        if specialist.id == id, do: Map.merge(specialist, changes), else: specialist
      end)

    Map.put(activity, :specialists, specialists)
  end

  defp add_activity_event(activity, event) do
    Map.update(activity, :events, [event], &Enum.take([event | &1], 6))
  end

  defp activity_metric(state, key) do
    value = Map.get(state, key) || Map.get(state, to_string(key))

    case value do
      number when is_float(number) -> Float.round(number, 2)
      nil -> "—"
      other -> to_string(other)
    end
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

  defp amd_experiment_evidence do
    Application.get_env(
      :proteinloop,
      :amd_experiment_evidence,
      ProteinLoop.AMDExperimentEvidence
    )
  end

  defp dect_simulator_client do
    Application.get_env(:proteinloop, :dect_simulator_client, SimulatorClient)
  end

  defp demo_cascade do
    Application.get_env(:proteinloop, :demo_cascade, DemoCascade)
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

  defp judge_story(state, mission_phase, loop_result, demo_result, aquatic_biomass) do
    ammonia = rounded(metric(state, "ammonia_mg_l"))
    oxygen = rounded(metric(state, "dissolved_oxygen_mg_l"))

    cond do
      ammonia >= 3.0 or oxygen < 3.5 ->
        %{
          phase: "risk",
          eyebrow: "Protein at risk",
          headline: "#{aquatic_biomass} kg fish + prawn stock depend on recovery",
          summary:
            "Ammonia is #{ammonia} mg/L and breathing oxygen is #{oxygen} mg/L. The connected food loop is under immediate stress."
        }

      ammonia >= 1.5 or oxygen < 5.0 ->
        %{
          phase: "risk",
          eyebrow: "Early warning",
          headline: "#{aquatic_biomass} kg fish + prawn stock need protection",
          summary:
            "Water chemistry is leaving the comfortable range before downstream feed and egg output are interrupted."
        }

      mission_phase == :completed and is_map(loop_result) and
          get_in(loop_result, [:verification, "ok"]) ->
        %{
          phase: "recovered",
          eyebrow: "Recovery verified",
          headline: "#{aquatic_biomass} kg fish + prawn stock protected",
          summary:
            "Ammonia #{rounded(loop_result.before_state["ammonia_mg_l"])} → #{rounded(loop_result.state["ammonia_mg_l"])} mg/L; oxygen #{rounded(loop_result.before_state["dissolved_oxygen_mg_l"])} → #{rounded(loop_result.state["dissolved_oxygen_mg_l"])} mg/L; 0 unsafe actions executed."
        }

      is_map(demo_result) ->
        %{
          phase: "recovered",
          eyebrow: "Verifier proof complete",
          headline: "Unsafe proposal blocked; safe recovery admitted",
          summary:
            "Emergency ammonia #{rounded(demo_result.spike_state["ammonia_mg_l"])} mg/L recovered to #{rounded(demo_result.final_state["ammonia_mg_l"])} mg/L with 0 unsafe actions executed."
        }

      true ->
        %{
          phase: "stable",
          eyebrow: "Loop protected",
          headline: "#{aquatic_biomass} kg fish + prawn stock are stable",
          summary:
            "Plants clean the water, duckweed stores feed, and the same loop supports chickens and eggs."
        }
    end
  end

  defp producer_link_state(%{pending: %{status: "processing"}}) do
    %{
      label: "Producer decision processing",
      class: "btn-info",
      aria_label: "Producer decision processing",
      count: nil
    }
  end

  defp producer_link_state(%{pending: pending}) when not is_nil(pending) do
    %{
      label: "Producer decision waiting",
      class: "btn-warning",
      aria_label: "Producer decision waiting, 1 request",
      count: 1
    }
  end

  defp producer_link_state(%{decisions: [%{status: "approved"} | _]}) do
    %{
      label: "Producer approved",
      class: "btn-success",
      aria_label: "Latest producer decision approved",
      count: nil
    }
  end

  defp producer_link_state(%{decisions: [%{status: "edited"} | _]}) do
    %{
      label: "Producer reduced",
      class: "btn-info",
      aria_label: "Latest producer decision reduced and approved",
      count: nil
    }
  end

  defp producer_link_state(%{decisions: [%{status: "rejected"} | _]}) do
    %{
      label: "Producer rejected",
      class: "btn-error",
      aria_label: "Latest producer decision rejected",
      count: nil
    }
  end

  defp producer_link_state(_approval_queue) do
    %{
      label: "Producer view",
      class: "btn-outline",
      aria_label: "Open producer view",
      count: nil
    }
  end

  @impl true
  def render(assigns) do
    {badge_class, badge_text} = status_badge(assigns.snapshot)
    fish_biomass = rounded(metric(assigns.state, "fish_biomass_kg"))
    prawn_biomass = rounded(metric(assigns.state, "prawn_biomass_kg"))

    aquatic_biomass = rounded(fish_biomass + prawn_biomass)

    assigns =
      assigns
      |> assign(:badge_class, badge_class)
      |> assign(:badge_text, badge_text)
      |> assign(:fish_biomass, fish_biomass)
      |> assign(:prawn_biomass, prawn_biomass)
      |> assign(:aquatic_biomass, aquatic_biomass)
      |> assign(:producer_link, producer_link_state(assigns.approval_queue))
      |> assign(:plant_biomass, rounded(metric(assigns.state, "plant_biomass_kg")))
      |> assign(:duckweed, rounded(metric(assigns.state, "duckweed_kg")))
      |> assign(:chickens, metric(assigns.state, "chicken_count"))
      |> assign(:eggs, rounded(metric(assigns.state, "eggs_count")))
      |> assign(
        :judge_story,
        judge_story(
          assigns.state,
          assigns.mission_phase,
          assigns.loop_result,
          assigns.demo_result,
          aquatic_biomass
        )
      )

    ~H"""
    <main class="min-h-screen bg-base-200 text-base-content">
      <section class="mx-auto flex max-w-7xl flex-col gap-4 px-4 py-4 sm:px-6 lg:px-8">
        <header class="flex flex-col gap-4 border-b border-base-300 pb-4 lg:flex-row lg:items-start lg:justify-between">
          <div class="max-w-4xl">
            <p class="text-xs font-semibold uppercase tracking-wide text-secondary">
              ProteinLoop · verified circular food production
            </p>
            <h1 class="mt-1 text-2xl font-semibold tracking-normal sm:text-3xl">
              Protect every protein output in the loop
            </h1>
            <p class="mt-2 max-w-3xl text-sm leading-6 text-base-content/70">
              Aquaponics already links fish and plants. ProteinLoop makes its animal-protein outcome
              measurable and recoverable, then extends the loop to freshwater prawns, duckweed feed,
              and eggs.
            </p>
          </div>
          <div class="flex shrink-0 flex-wrap items-center gap-2">
            <span class={["badge", @badge_class]}>{@badge_text}</span>
            <span id="judge-proof-description" class="sr-only">
              Runs a deterministic unsafe-versus-safe verifier rehearsal. The live Gemma recovery is
              a separate workflow below.
            </span>
            <button
              id="run-judge-proof"
              type="button"
              class="btn btn-sm btn-primary"
              phx-click="demo-cascade"
              phx-disable-with="Running verifier proof..."
              aria-describedby="judge-proof-description"
            >
              <.icon name="hero-play" /> Run one-click verifier proof
            </button>
            <.link
              id="producer-decision-link"
              navigate={~p"/producer"}
              class={["btn btn-sm", @producer_link.class]}
              aria-label={@producer_link.aria_label}
            >
              <.icon name="hero-hand-raised" />
              {@producer_link.label}
              <span
                :if={@producer_link.count}
                data-approval-count
                class="badge badge-sm border-warning-content/20 bg-warning-content text-warning"
              >
                {@producer_link.count}
              </span>
            </.link>
            <button class="btn btn-sm btn-outline" phx-click="refresh">
              <.icon name="hero-arrow-path" /> Refresh
            </button>
          </div>
        </header>

        <section
          id="protein-loop-story"
          class="protein-loop-story"
          data-story-phase={@judge_story.phase}
          aria-labelledby="protein-loop-title"
        >
          <div
            id="protein-loop-impact"
            class="protein-loop-story__intro"
            role="status"
            aria-live="polite"
            aria-atomic="true"
          >
            <p class="text-xs font-semibold uppercase tracking-wide text-primary">
              {@judge_story.eyebrow}
            </p>
            <h2 id="protein-loop-title" class="mt-1 text-base font-semibold">
              {@judge_story.headline}
            </h2>
            <p class="mt-1 text-xs leading-5 text-base-content/65">
              {@judge_story.summary}
            </p>
          </div>
          <ol class="protein-loop-story__steps" aria-label="Connected protein loop">
            <li>
              <.icon name="hero-scale" />
              <div>
                <p>Fish + prawns</p>
                <strong>{@aquatic_biomass} kg live biomass</strong>
              </div>
            </li>
            <li>
              <.icon name="hero-arrow-path" />
              <div>
                <p>Plants clean the water</p>
                <strong>{@plant_biomass} kg growing</strong>
              </div>
            </li>
            <li>
              <.icon name="hero-sparkles" />
              <div>
                <p>Duckweed becomes feed</p>
                <strong>{@duckweed} kg reserve</strong>
              </div>
            </li>
            <li>
              <.icon name="hero-home-modern" />
              <div>
                <p>Chickens + eggs</p>
                <strong>{@chickens} hens · {@eggs} eggs tracked</strong>
              </div>
            </li>
          </ol>
        </section>

        <section
          id="judge-proof-ribbon"
          class="judge-proof-ribbon"
          aria-label="Executable competition proof"
        >
          <h2 class="sr-only">Executable competition proof</h2>
          <ul class="judge-proof-ribbon__items">
            <li>
              <.icon name="hero-sparkles" />
              <span>
                <strong>
                  {if @sagents_status.endpoint_configured?,
                    do: "Gemma 4 endpoint configured",
                    else: "Gemma 4 endpoint unavailable"}
                </strong>
                <small>Live model path</small>
              </span>
            </li>
            <li>
              <.icon name="hero-user-group" />
              <span>
                <strong>{@sagents_status.agent_count}-agent recovery team</strong>
                <small>4 specialists + supervisor</small>
              </span>
            </li>
            <li>
              <.icon name="hero-shield-check" />
              <span>
                <strong>Deterministic verifier</strong>
                <small>Only mutation authority</small>
              </span>
            </li>
            <li>
              <.icon name="hero-signal" />
              <span>
                <strong>
                  {if @nrf9151_evidence.available?,
                    do: "2-board DECT NR+ capture",
                    else: "DECT NR+ capture unavailable"}
                </strong>
                <small>Private field link · no Wi-Fi</small>
              </span>
            </li>
            <li>
              <.icon name="hero-hand-raised" />
              <span>
                <strong>Producer approval</strong>
                <small>Risky actions pause</small>
              </span>
            </li>
            <li
              :if={@amd_experiment.available?}
              title="Captured on the Act-II AMD notebook; the public application remains on its durable CPU fallback."
            >
              <.icon name="hero-cpu-chip" />
              <span>
                <strong>AMD-hosted Gemma captured</strong>
                <small>Public app remains on CPU fallback</small>
              </span>
            </li>
            <li
              :if={!@amd_experiment.available?}
              title="Portable deployment profile included; the current local demo is not AMD-hosted."
            >
              <.icon name="hero-cpu-chip" />
              <span>
                <strong>AMD ROCm + vLLM profile</strong>
                <small>Portable path · current demo is local</small>
              </span>
            </li>
          </ul>
        </section>

        <.amd_experiment_replay
          :if={@amd_experiment.available?}
          evidence={@amd_experiment}
        />

        <details
          id="off-grid-continuity"
          class="off-grid-continuity"
          aria-labelledby="off-grid-continuity-title"
        >
          <summary class="off-grid-continuity__header">
            <div>
              <p class="text-xs font-semibold uppercase tracking-wide text-secondary">
                Off-grid continuity
              </p>
              <h2 id="off-grid-continuity-title" class="mt-1 text-xl font-semibold">
                Keep the food control loop local
              </h2>
            </div>
            <p class="max-w-2xl text-sm leading-6 text-base-content/65">
              Monitoring, AI guidance, safety checks, and producer decisions can stay at the farm
              so food operations do not stop with an internet outage. Measured solar autonomy is
              the next deployment proof.
            </p>
            <.icon name="hero-chevron-down" class="off-grid-continuity__chevron" />
          </summary>

          <div class="off-grid-continuity__modes">
            <div>
              <.icon name="hero-signal-slash" />
              <span>
                <small>No Wi-Fi</small>
                <strong>DECT NR+ private field link</strong>
                <p>PT-to-FT traffic stays local without Wi-Fi, a SIM, or cloud access.</p>
              </span>
              <span class="badge badge-sm badge-success">Physical radio proven</span>
            </div>
            <div>
              <.icon name="hero-cloud" />
              <span>
                <small>No cloud</small>
                <strong>Self-hosted Gemma + local verifier</strong>
                <p>A separate edge computer keeps inference and deterministic safety on site.</p>
              </span>
              <span class="badge badge-sm badge-success">Local AI proven</span>
            </div>
            <div>
              <.icon name="hero-sun" />
              <span>
                <small>No electrical grid</small>
                <strong>Solar + battery edge power</strong>
                <p>The target power system removes grid dependence after an energy audit.</p>
              </span>
              <span class="badge badge-sm badge-warning">Deployment design</span>
            </div>
          </div>

          <ol
            id="field-acquisition-path"
            class="off-grid-continuity__path"
            aria-label="Local field data path"
          >
            <li data-proof-state="planned">
              <span class="off-grid-continuity__step">1</span>
              <div>
                <strong>Water probes</strong>
                <p>Chemistry probes are the next field integration.</p>
              </div>
              <span class="badge badge-sm badge-warning">planned</span>
            </li>
            <li data-proof-state="mixed">
              <span class="off-grid-continuity__step">2</span>
              <div>
                <strong>nRF9151 PT tank node</strong>
                <p>Physical board proven; sensor packet firmware comes next.</p>
              </div>
              <span class="badge badge-sm badge-info">board proven</span>
            </li>
            <li data-proof-state="proven">
              <span class="off-grid-continuity__step">3</span>
              <div>
                <strong>DECT NR+ private link</strong>
                <p>Bidirectional PT and FT sequence #100 is captured.</p>
              </div>
              <span class="badge badge-sm badge-success">link proven</span>
            </li>
            <li data-proof-state="mixed">
              <span class="off-grid-continuity__step">4</span>
              <div>
                <strong>nRF9151 FT gateway radio</strong>
                <p>The FT radio hands local packets to edge compute.</p>
              </div>
              <span class="badge badge-sm badge-info">board proven</span>
            </li>
            <li data-proof-state="proven">
              <span class="off-grid-continuity__step">5</span>
              <div>
                <strong>Separate edge computer</strong>
                <p>Gemma runs on the edge computer, not on either radio board; local rules verify.</p>
              </div>
              <span class="badge badge-sm badge-success">runtime proven</span>
            </li>
            <li data-proof-state="proven">
              <span class="off-grid-continuity__step">6</span>
              <div>
                <strong>Producer decision</strong>
                <p>Approve, reduce, or reject risky action without a cloud dependency.</p>
              </div>
              <span class="badge badge-sm badge-success">workflow proven</span>
            </li>
          </ol>
        </details>

        <.realtime_tank_scene id="operator-system-scene" state={@state} controls={true}>
          <:agent_controls>
            <div class="realtime-tank__agent-header">
              <div>
                <p class="text-xs font-semibold uppercase tracking-wide text-primary">
                  Verified recovery
                </p>
                <h3 class="mt-1 text-base font-semibold">
                  <span class="realtime-tank__agent-compact-title">AI recovery control</span>
                  <span class="realtime-tank__agent-fullscreen-detail">
                    {if @mission_phase == :completed,
                      do: "Recovery complete",
                      else: "Protect this protein loop"}
                  </span>
                </h3>
              </div>
              <span class={[
                "badge badge-sm",
                if(@sagents_status.endpoint_configured?, do: "badge-success", else: "badge-warning")
              ]}>
                {if @sagents_status.endpoint_configured?,
                  do: "Gemma 4 ready",
                  else: "Gemma 4 unavailable"}
              </span>
            </div>

            <div
              class="realtime-tank__agent-compact-status"
              role="status"
              aria-live="polite"
            >
              <.icon
                name={if @sagents_running?, do: "hero-arrow-path", else: "hero-user-group"}
                class={if @sagents_running?, do: "animate-spin", else: nil}
              />
              <div>
                <strong>{@agent_activity.title}</strong>
                <span>
                  {if @sagents_running?, do: "Gemma team working", else: "Ready for a safe plan"}
                </span>
              </div>
            </div>

            <div class="realtime-tank__agent-fullscreen-detail">
              <.agent_activity_monitor
                id="tank-agent-activity"
                activity={@agent_activity}
                compact={true}
              />
            </div>

            <label
              for="fullscreen-mission-select"
              class="mt-3 block text-xs font-semibold text-base-content/65"
            >
              Recovery goal
            </label>
            <select
              id="fullscreen-mission-select"
              name="mission"
              class="select select-sm mt-1 w-full border-base-300 bg-white"
              phx-change="select-agentic-mission"
              disabled={@sagents_running?}
            >
              <option
                :for={mission <- @agentic_missions}
                value={mission.id}
                selected={mission.id == @selected_mission.id}
              >
                {mission.title}
              </option>
            </select>

            <div class="realtime-tank__agent-fullscreen-detail mt-3 border-y border-base-300 py-3">
              <p class="text-sm font-semibold">{@selected_mission.title}</p>
              <p class="mt-1 text-xs leading-5 text-base-content/65">
                {@selected_mission.objective}
              </p>
            </div>

            <p class="realtime-tank__agent-fullscreen-detail realtime-tank__trust-line">
              Gemma proposes. Ecosystem rules verify. The producer controls irreversible actions.
            </p>

            <button
              id="fullscreen-run-agentic-mission"
              type="button"
              class="btn btn-sm btn-primary mt-3 w-full"
              phx-click="run-agentic-mission"
              disabled={@sagents_running? || !@sagents_status.endpoint_configured?}
            >
              <.icon
                name={if @sagents_running?, do: "hero-arrow-path", else: "hero-sparkles"}
                class={if @sagents_running?, do: "animate-spin", else: nil}
              />
              {if @sagents_running?,
                do: "Specialists deliberating",
                else: "Create safe recovery plan"}
            </button>

            <div
              :if={@mission_phase == :completed && is_map(@loop_result)}
              id="fullscreen-agent-result"
              class="realtime-tank__agent-fullscreen-detail mt-3 border-l-2 border-success bg-success/10 px-3 py-2"
              role="status"
              aria-live="polite"
              aria-atomic="true"
            >
              <div class="flex flex-wrap items-center justify-between gap-2">
                <p class="text-sm font-semibold">
                  {if get_in(@loop_result, [:verification, "ok"]),
                    do: "Recovery verified",
                    else: "Recovery rejected"}
                </p>
                <span class={[
                  "badge badge-sm",
                  if(get_in(@loop_result, [:verification, "ok"]),
                    do: "badge-success",
                    else: "badge-error"
                  )
                ]}>
                  {if get_in(@loop_result, [:verification, "ok"]),
                    do: "Ecosystem rules passed",
                    else: "Ecosystem rules blocked it"}
                </span>
              </div>
              <p class="mt-1 text-xs font-semibold text-success">
                {if get_in(@loop_result, [:verification, "ok"]),
                  do: "Fish and prawns protected",
                  else: "No rejected action was executed"}
              </p>
              <dl class="realtime-tank__recovery-delta">
                <div>
                  <dt>Ammonia</dt>
                  <dd>
                    {rounded(@loop_result.before_state["ammonia_mg_l"])} → {rounded(
                      @loop_result.state["ammonia_mg_l"]
                    )} mg/L
                  </dd>
                </div>
                <div>
                  <dt>Oxygen</dt>
                  <dd>
                    {rounded(@loop_result.before_state["dissolved_oxygen_mg_l"])} → {rounded(
                      @loop_result.state["dissolved_oxygen_mg_l"]
                    )} mg/L
                  </dd>
                </div>
              </dl>
              <div class="realtime-tank__safe-count">
                <span>Unsafe actions executed</span>
                <strong>0</strong>
              </div>
              <p class="mt-1 text-[0.65rem] text-base-content/55">
                Deterministic verifier reward {rounded(@loop_result.reward)}
              </p>
            </div>

            <p
              :if={@mission_phase == :failed}
              id="fullscreen-agent-failed"
              class="mt-3 border-l-2 border-error bg-error/10 px-3 py-2 text-xs font-semibold"
            >
              Agent mission failed. No simulator action was applied.
            </p>
          </:agent_controls>
        </.realtime_tank_scene>

        <.judge_proof_result :if={is_map(@demo_result)} result={@demo_result} />

        <section
          id="agentic-mission"
          class="rounded-box border-2 border-primary/30 bg-base-100 p-4 sm:p-5"
        >
          <div class="flex flex-col gap-3 lg:flex-row lg:items-start lg:justify-between">
            <div>
              <div class="flex flex-wrap items-center gap-2">
                <h2 class="text-xl font-semibold">Create a verified recovery</h2>
                <span class={[
                  "badge",
                  if(@sagents_status.endpoint_configured?, do: "badge-success", else: "badge-warning")
                ]}>
                  {if @sagents_status.endpoint_configured?,
                    do: "Gemma 4 ready",
                    else: "Gemma 4 not ready"}
                </span>
              </div>
              <p class="mt-1 max-w-3xl text-sm text-base-content/70">
                Choose what food outcome matters now. Protein-loop specialists compare the living
                system, ecosystem rules block unsafe actions, and irreversible changes still require
                producer approval.
              </p>
            </div>
            <span class="text-sm font-semibold text-base-content/60">
              {@sagents_status.agent_count}-agent recovery team
            </span>
          </div>

          <.agent_activity_monitor
            id="mission-agent-activity"
            activity={@agent_activity}
          />

          <div class="mt-4">
            <p class="mb-2 text-sm font-semibold">What should the system protect?</p>
            <div
              class="grid overflow-hidden rounded-field border border-base-300 sm:grid-cols-3"
              aria-label="AI goal"
            >
              <button
                :for={mission <- @agentic_missions}
                id={"mission-#{mission.id}"}
                type="button"
                class={[
                  "btn min-h-14 h-auto rounded-none border-0 border-base-300 px-3 py-2 text-sm sm:border-r sm:last:border-r-0",
                  if(@selected_mission.id == mission.id, do: "btn-primary", else: "btn-ghost")
                ]}
                phx-click="select-agentic-mission"
                phx-value-mission={mission.id}
                disabled={@sagents_running?}
              >
                {mission.title}
              </button>
            </div>
          </div>

          <div class="mt-4 grid gap-4 lg:grid-cols-[0.9fr_1.1fr] lg:items-stretch">
            <div class="border-y border-base-300 py-3">
              <p class="text-xs font-semibold uppercase tracking-wide text-secondary">
                Selected goal
              </p>
              <p class="mt-1 font-semibold">{@selected_mission.title}</p>
              <p class="mt-1 text-sm text-base-content/70">{@selected_mission.objective}</p>
            </div>

            <ol
              class="grid grid-cols-2 border-y border-base-300 sm:grid-cols-4"
              aria-label="AI safety workflow"
            >
              <li class="p-3 sm:border-r sm:border-base-300">
                <.icon name="hero-eye" class="size-5 text-info" />
                <p class="mt-1 text-sm font-semibold">Read the live loop</p>
              </li>
              <li class="border-l border-base-300 p-3 sm:border-l-0 sm:border-r">
                <.icon name="hero-user-group" class="size-5 text-secondary" />
                <p class="mt-1 text-sm font-semibold">Compare specialist advice</p>
              </li>
              <li class="border-t border-base-300 p-3 sm:border-r sm:border-t-0">
                <.icon name="hero-shield-check" class="size-5 text-success" />
                <p class="mt-1 text-sm font-semibold">Verify ecosystem safety</p>
              </li>
              <li class="border-l border-t border-base-300 p-3 sm:border-l-0 sm:border-t-0">
                <.icon name="hero-check-circle" class="size-5 text-primary" />
                <p class="mt-1 text-sm font-semibold">Execute only if safe</p>
              </li>
            </ol>
          </div>

          <button
            id="run-agentic-mission"
            class="btn btn-primary mt-4 w-full sm:w-auto sm:min-w-80"
            phx-click="run-agentic-mission"
            disabled={@sagents_running? || !@sagents_status.endpoint_configured?}
          >
            <.icon
              name={if @sagents_running?, do: "hero-arrow-path", else: "hero-sparkles"}
              class={if @sagents_running?, do: "animate-spin", else: nil}
            />
            {if @sagents_running?, do: "Specialists deliberating", else: "Create safe recovery plan"}
          </button>

          <p
            :if={@mission_phase == :deliberating}
            id="mission-deliberating"
            class="mt-2 text-sm font-semibold text-primary"
          >
            Specialists deliberating · ecosystem rules will verify the final plan
          </p>
          <p :if={!@sagents_status.endpoint_configured?} class="mt-2 text-sm text-error">
            Gemma 4 is not ready yet.
          </p>

          <div class="mt-4">
            <.loop_result result={@loop_result} />
          </div>
        </section>

        <details
          id="advanced-evidence"
          class="group min-w-0 rounded-box border border-base-300 bg-base-100"
          open={@advanced_evidence_open?}
        >
          <summary
            class="flex cursor-pointer list-none items-center justify-between gap-4 p-4 [&::-webkit-details-marker]:hidden"
            phx-click="toggle-advanced-evidence"
            aria-expanded={to_string(@advanced_evidence_open?)}
          >
            <span>
              <span class="block font-semibold">Advanced evidence and controls</span>
              <span class="mt-1 block text-sm text-base-content/60">
                DECT radios, simulator controls, agent details, safety evidence, and traces
              </span>
            </span>
            <.icon
              name="hero-chevron-down"
              class="size-5 shrink-0 transition-transform group-open:rotate-180"
            />
          </summary>

          <div class="advanced-evidence__content flex min-w-0 flex-col gap-4 border-t border-base-300 p-4">
            <section class="grid gap-3 md:grid-cols-2 xl:grid-cols-4">
              <.metric_card
                label="Day"
                value={metric(@state, "day")}
                detail={metric(@state, "last_event")}
              />
              <.metric_card
                label="Waste in water"
                value={"#{rounded(metric(@state, "ammonia_mg_l"))} mg/L"}
                detail="Ammonia · safe below 1.5"
                value_class={risk_class(metric(@state, "ammonia_mg_l"), 1.5, 3.0)}
              />
              <.metric_card
                label="Breathing oxygen"
                value={"#{rounded(metric(@state, "dissolved_oxygen_mg_l"))} mg/L"}
                detail="Dissolved oxygen · comfortable above 5.0"
                value_class={
                  if metric(@state, "dissolved_oxygen_mg_l") < 3.5,
                    do: "text-error",
                    else: "text-success"
                }
              />
              <.metric_card
                label="Reward"
                value={@snapshot.reward || "pending"}
                detail={@snapshot.source}
              />
            </section>

            <section
              id="dect-live-evidence"
              class="rounded-box border border-base-300 bg-base-100 p-4"
            >
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
                  <p class="mt-2 max-w-3xl text-sm leading-6 text-base-content/75">
                    DECT NR+ is a private, non-cellular 5G field link. The PT tank node can reach
                    the FT gateway locally; this hop does not need Wi-Fi, a SIM, or cloud access. A
                    separate edge computer runs self-hosted Gemma and the deterministic verifier.
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

            <section class="grid min-w-0 gap-4 lg:grid-cols-[1.3fr_0.7fr]">
              <div
                id="advanced-closed-loop-state"
                class="min-w-0 rounded-box border border-base-300 bg-base-100 p-4"
              >
                <div class="advanced-state__header mb-3 flex items-center justify-between gap-3">
                  <h2 class="text-lg font-semibold">Closed-loop state</h2>
                  <div class="advanced-state__commands join">
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
                <p
                  :if={!@snapshot.connected?}
                  class="mt-4 rounded-box bg-error/10 p-3 text-sm text-error"
                >
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
                  <h2 class="text-lg font-semibold">Human approval</h2>
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
                  <p class="mt-1 text-xs text-base-content/50">
                    Sagents {@sagents_status.framework_version} / LangChain {@sagents_status.langchain_version} / {@sagents_status.termination}
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
                      <option
                        value="openai_compatible"
                        selected={@agent_provider == :openai_compatible}
                      >
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
          </div>
        </details>
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

  attr :id, :string, required: true
  attr :activity, :map, required: true
  attr :compact, :boolean, default: false

  def agent_activity_monitor(assigns) do
    assigns =
      assigns
      |> assign(:phase_label, activity_phase_label(assigns.activity.phase))
      |> assign(:phase_icon, activity_phase_icon(assigns.activity.phase))

    ~H"""
    <section
      id={@id}
      class={["agent-live-monitor", @compact && "agent-live-monitor--compact"]}
      data-phase={@activity.phase}
      role={if @compact, do: "status", else: "region"}
      aria-live={if @compact, do: "polite", else: "off"}
      aria-atomic="false"
    >
      <header class="agent-live-monitor__header">
        <div class="agent-live-monitor__live-label">
          <span class="agent-live-monitor__signal" aria-hidden="true"></span>
          <span>Live agent activity</span>
        </div>
        <span class="agent-live-monitor__phase">{@phase_label}</span>
      </header>

      <div class="agent-live-monitor__current">
        <span class="agent-live-monitor__current-icon" aria-hidden="true">
          <.icon name={@phase_icon} />
        </span>
        <div>
          <h4>{@activity.title}</h4>
          <p>{@activity.detail}</p>
        </div>
      </div>

      <div class="agent-live-monitor__network" aria-label="Five-agent execution network">
        <div class="agent-live-monitor__source">
          <.icon name="hero-signal" />
          <span>Live tank</span>
        </div>
        <span class="agent-live-monitor__link" aria-hidden="true"></span>
        <ol class="agent-live-monitor__specialists" aria-label="Gemma specialists">
          <li
            :for={specialist <- @activity.specialists}
            id={"#{@id}-specialist-#{specialist.id}"}
            data-status={specialist.status}
          >
            <span class="agent-live-monitor__agent-icon" aria-hidden="true">
              <.icon name={specialist.icon} />
            </span>
            <span>
              <strong>{specialist.label}</strong>
              <small>{activity_status_label(specialist.status)}</small>
            </span>
            <.icon
              :if={specialist.status == :completed}
              name="hero-check-circle"
              class="agent-live-monitor__complete-icon"
            />
          </li>
        </ol>
        <span class="agent-live-monitor__link" aria-hidden="true"></span>
        <div class="agent-live-monitor__decision-nodes">
          <div data-active={
            @activity.phase in [
              :supervising,
              :verifying,
              :verified,
              :applying,
              :measuring,
              :completed
            ]
          }>
            <.icon name="hero-cpu-chip" />
            <span>Supervisor</span>
          </div>
          <div data-active={
            @activity.phase in [:verifying, :verified, :applying, :measuring, :completed]
          }>
            <.icon name="hero-shield-check" />
            <span>Ecosystem safety check</span>
          </div>
        </div>
      </div>

      <div :if={!@compact} class="agent-live-monitor__details">
        <section aria-label="Structured specialist updates">
          <h5>Structured briefs arriving now</h5>
          <ol>
            <li
              :for={specialist <- @activity.specialists}
              data-status={specialist.status}
            >
              <span>{specialist.label}</span>
              <p>
                {if specialist.report,
                  do: specialist.report["recommendation"],
                  else: "Waiting for a structured recommendation."}
              </p>
            </li>
          </ol>
        </section>

        <section aria-label="Agent event stream">
          <h5>Execution events</h5>
          <ol class="agent-live-monitor__events">
            <li :if={@activity.events == []}>
              <span>Ready</span>
              <p>No model call is running yet.</p>
            </li>
            <li :for={event <- @activity.events} data-status={event.status}>
              <span>{event.title}</span>
              <p>{event.detail}</p>
            </li>
          </ol>
        </section>
      </div>

      <p class="agent-live-monitor__disclosure">
        AI activity is visible as structured events and tool outcomes, not private chain-of-thought.
        Producer stays in control.
      </p>
    </section>
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

  defp activity_phase_label(:ready), do: "Ready"
  defp activity_phase_label(:observing), do: "Observing"
  defp activity_phase_label(:specialists), do: "4 agents working"
  defp activity_phase_label(:supervising), do: "Synthesizing"
  defp activity_phase_label(:verifying), do: "Safety check"
  defp activity_phase_label(:verified), do: "Accepted"
  defp activity_phase_label(:applying), do: "Applying"
  defp activity_phase_label(:measuring), do: "Measuring"
  defp activity_phase_label(:completed), do: "Complete"
  defp activity_phase_label(:failed), do: "Stopped safely"
  defp activity_phase_label(_phase), do: "Waiting"

  defp activity_phase_icon(:ready), do: "hero-user-group"
  defp activity_phase_icon(:observing), do: "hero-eye"
  defp activity_phase_icon(:specialists), do: "hero-user-group"
  defp activity_phase_icon(:supervising), do: "hero-cpu-chip"
  defp activity_phase_icon(:verifying), do: "hero-shield-check"
  defp activity_phase_icon(:verified), do: "hero-check-badge"
  defp activity_phase_icon(:applying), do: "hero-wrench-screwdriver"
  defp activity_phase_icon(:measuring), do: "hero-chart-bar"
  defp activity_phase_icon(:completed), do: "hero-check-circle"
  defp activity_phase_icon(:failed), do: "hero-no-symbol"
  defp activity_phase_icon(_phase), do: "hero-clock"

  defp activity_status_label(:waiting), do: "waiting"
  defp activity_status_label(:running), do: "working"
  defp activity_status_label(:completed), do: "brief ready"
  defp activity_status_label(:failed), do: "stopped"
  defp activity_status_label(_status), do: "waiting"

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
      No recovery receipt yet. Create a safe plan to compare the chemistry before and after a
      verified intervention.
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
            <h3 class="text-lg font-semibold">Verified recovery receipt</h3>
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

  attr :evidence, :map, required: true

  def amd_experiment_replay(assigns) do
    selected = assigns.evidence.search.selected

    assigns =
      assigns
      |> assign(:selected, selected)
      |> assign(:selected_action, selected.action)

    ~H"""
    <section
      id="amd-experiment-replay"
      class="amd-experiment"
      data-evidence-state="captured"
      aria-labelledby="amd-experiment-title"
    >
      <header class="amd-experiment__header">
        <div>
          <p class="amd-experiment__eyebrow">
            <.icon name="hero-cpu-chip" /> Captured AMD experiment
          </p>
          <h2 id="amd-experiment-title">
            Gemma explored {@evidence.search.generated_count} recovery plans on AMD
          </h2>
          <p>
            The verifier admitted {@evidence.search.safe_count} and rejected {@evidence.search.rejected_count} before tank mutation.
          </p>
        </div>
        <div class="amd-experiment__provenance">
          <span class="badge badge-success">Verified artifacts</span>
          <strong>Captured experiment · not a live notebook connection</strong>
          <small>Public demo runtime: {@evidence.public_runtime}</small>
        </div>
      </header>

      <div class="amd-experiment__runtime" aria-label="Captured AMD runtime">
        <span>
          <small>Model</small>
          <strong>{@evidence.model}</strong>
        </span>
        <span>
          <small>AMD software</small>
          <strong>ROCm {@evidence.runtime.rocm_version}</strong>
        </span>
        <span>
          <small>Serving engine</small>
          <strong>vLLM {@evidence.runtime.vllm_version}</strong>
        </span>
        <span>
          <small>GPU proof</small>
          <strong>{@evidence.runtime.architecture} · {@evidence.runtime.gpu_memory_gib} GiB</strong>
        </span>
      </div>

      <ol class="amd-experiment__flow" aria-label="AMD Gemma verifier-guided search">
        <li>
          <span>1</span>
          <div>
            <small>Gemma 4</small>
            <strong>{@evidence.search.generated_count} different plans</strong>
          </div>
        </li>
        <li>
          <span>2</span>
          <div>
            <small>Safety boundary</small>
            <strong>{@evidence.search.rejected_count} blocked</strong>
          </div>
        </li>
        <li>
          <span>3</span>
          <div>
            <small>Simulator ranking</small>
            <strong>{@evidence.search.safe_count} safe plans scored</strong>
          </div>
        </li>
        <li data-selected-stage>
          <span>4</span>
          <div>
            <small>Best verified result</small>
            <strong>+{@evidence.search.reward_delta} reward</strong>
          </div>
        </li>
      </ol>

      <div class="amd-experiment__selection">
        <div class="amd-experiment__selection-copy">
          <p>Selected safe recovery</p>
          <h3>{@selected.strategy}</h3>
          <p>{@selected_action["note"]}</p>
        </div>
        <dl class="amd-experiment__action">
          <div>
            <dt>Feed</dt>
            <dd>{one_decimal(@selected_action["feed_kg"])} kg</dd>
          </div>
          <div>
            <dt>Aeration</dt>
            <dd>{one_decimal(@selected_action["aeration_hours"])} h aeration</dd>
          </div>
          <div>
            <dt>Water</dt>
            <dd>{one_decimal(@selected_action["water_exchange_fraction"] * 100)}% water exchange</dd>
          </div>
          <div>
            <dt>Duckweed</dt>
            <dd>{one_decimal(@selected_action["duckweed_harvest_kg"])} kg harvest</dd>
          </div>
        </dl>
      </div>

      <div class="amd-experiment__outcome" aria-label="Selected plan measured outcome">
        <span>
          <small>Waste in water</small>
          <strong>
            {@evidence.search.initial_state["ammonia_mg_l"]} → {@selected.final_state["ammonia_mg_l"]} mg/L
          </strong>
          <p>Ammonia moved toward the safe range.</p>
        </span>
        <span>
          <small>Breathing oxygen</small>
          <strong>
            {@evidence.search.initial_state["dissolved_oxygen_mg_l"]} → {@selected.final_state[
              "dissolved_oxygen_mg_l"
            ]} mg/L
          </strong>
          <p>Usable underwater oxygen recovered.</p>
        </span>
        <span>
          <small>Verified reward</small>
          <strong>{@selected.reward}</strong>
          <p>+{@evidence.search.reward_delta} versus the naive routine.</p>
        </span>
      </div>

      <section
        :if={@evidence.repair_evaluation}
        id="amd-repair-audit"
        class="amd-product-audit amd-product-audit--repair"
        aria-labelledby="amd-repair-audit-title"
      >
        <header>
          <div>
            <p>20-emergency verifier-feedback audit</p>
            <h3 id="amd-repair-audit-title">
              Rejected actions became structured feedback. Gemma revised them and tried again.
            </h3>
          </div>
          <span class="badge badge-success">
            {@evidence.repair_evaluation.scenario_count}/20 model-safe after feedback
          </span>
        </header>
        <div class="amd-product-audit__metrics">
          <span data-audit-risk>
            <small>First proposal</small>
            <strong>{round(@evidence.repair_evaluation.first_safe_rate * 100)}% first-answer safe</strong>
          </span>
          <span data-audit-success>
            <small>Bounded repair</small>
            <strong>{round(@evidence.repair_evaluation.repair_safe_rate * 100)}% safe after feedback</strong>
          </span>
          <span>
            <small>Repair contribution</small>
            <strong>{@evidence.repair_evaluation.rescue_count} rejected answers repaired</strong>
          </span>
          <span>
            <small>Final fallback</small>
            <strong>{@evidence.repair_evaluation.fallback_count} deterministic fallbacks</strong>
          </span>
          <span>
            <small>Food protected</small>
            <strong>{@evidence.repair_evaluation.protected_biomass_kg} kg aggregate scenario biomass protected</strong>
          </span>
          <span>
            <small>Observed generation</small>
            <strong>{@evidence.repair_evaluation.completion_tokens_per_second} completion tokens/s</strong>
          </span>
        </div>
        <footer>
          <strong>
            {@evidence.repair_evaluation.one_revision_count} repaired in one revision · {@evidence.repair_evaluation.multi_revision_count} needed multiple revisions
          </strong>
          <p>
            {@evidence.repair_evaluation.model_request_count} observed AMD requests · {one_decimal(
              @evidence.repair_evaluation.total_tokens / 1000
            )}k observed tokens · {@evidence.repair_evaluation.latency_p50_ms} ms median response.
            Inference-time repair only · no training or weight updates.
          </p>
        </footer>
      </section>

      <section :if={@evidence.product_evaluation} class="amd-product-audit">
        <header>
          <div>
            <p>Five-emergency product audit</p>
            <h3>One model answer was not enough. The verified system recovered every scenario.</h3>
          </div>
          <span class="badge badge-info">{@evidence.product_evaluation.model_candidate_count} AMD Gemma plans tested</span>
        </header>
        <div class="amd-product-audit__metrics">
          <span>
            <small>Single answer</small>
            <strong>{round(@evidence.product_evaluation.first_safe_rate * 100)}% first-answer safe</strong>
          </span>
          <span data-audit-success>
            <small>Verified system</small>
            <strong>{round(@evidence.product_evaluation.selected_safe_rate * 100)}% safe final plan</strong>
          </span>
          <span>
            <small>Search value</small>
            <strong>{@evidence.product_evaluation.rescue_count} rejected first answers rescued</strong>
          </span>
          <span>
            <small>Safety fallback</small>
            <strong>{@evidence.product_evaluation.fallback_count} deterministic fallbacks</strong>
          </span>
          <span>
            <small>Food protected</small>
            <strong>{@evidence.product_evaluation.protected_biomass_kg} kg aquatic biomass protected</strong>
          </span>
          <span>
            <small>AMD generation</small>
            <strong>{@evidence.product_evaluation.latency_p50_ms} ms median generation</strong>
          </span>
        </div>
        <footer>
          <strong>
            Gemma supplied a safe plan in {@evidence.product_evaluation.gemma_safe_scenario_count} of {@evidence.product_evaluation.scenario_count} emergencies.
          </strong>
          <p>
            In the remaining {@evidence.product_evaluation.fallback_count}, every model proposal was
            blocked and the deterministic emergency policy recovered the loop. The application
            records which path won instead of presenting fallback output as model output.
          </p>
        </footer>
      </section>

      <details class="amd-experiment__ledger">
        <summary>
          <span>
            <strong>Inspect every verifier decision</strong>
            <small>Structured actions and outcomes only · no private chain-of-thought</small>
          </span>
          <.icon name="hero-chevron-down" />
        </summary>
        <ol aria-label="Captured candidate decisions">
          <li
            :for={candidate <- @evidence.search.candidates}
            data-candidate-index={candidate.index}
            data-candidate-decision={if(candidate.accepted?, do: "accepted", else: "rejected")}
            data-selected={to_string(candidate.selected?)}
          >
            <div class="amd-experiment__candidate-heading">
              <span class={[
                "badge badge-sm",
                cond do
                  candidate.selected? -> "badge-success"
                  candidate.accepted? -> "badge-info"
                  true -> "badge-error"
                end
              ]}>
                {cond do
                  candidate.selected? -> "Selected"
                  candidate.accepted? -> "Safe"
                  true -> "Blocked before mutation"
                end}
              </span>
              <div>
                <strong>{candidate.strategy}</strong>
                <small>{candidate_source(candidate.source)}</small>
              </div>
              <span :if={candidate.reward} class="amd-experiment__candidate-reward">
                reward {candidate.reward}
              </span>
            </div>
            <p class="amd-experiment__candidate-action">
              feed {candidate.action["feed_kg"]} kg · aeration {candidate.action["aeration_hours"]} h · water {one_decimal(
                candidate.action["water_exchange_fraction"] * 100
              )}% · duckweed {candidate.action["duckweed_harvest_kg"]} kg
            </p>
            <p :if={!candidate.accepted?} class="amd-experiment__violation">
              {Enum.join(candidate.violations, "; ")}
            </p>
          </li>
        </ol>
      </details>

      <footer class="amd-experiment__footer">
        <p>
          <strong>No model weights were updated.</strong>
          This was verifier-guided inference-time search: Gemma explored; deterministic ecosystem
          rules decided what was safe.
        </p>
        <button
          id="amd-run-local-proof"
          type="button"
          class="btn btn-sm btn-outline"
          phx-click="demo-cascade"
          phx-disable-with="Running local proof..."
        >
          <.icon name="hero-play" /> Run the verifier locally
        </button>
      </footer>
    </section>
    """
  end

  defp one_decimal(value) when is_number(value) do
    :erlang.float_to_binary(value * 1.0, decimals: 1)
  end

  defp one_decimal(_value), do: "—"

  defp candidate_source("control_unsafe"), do: "Deliberate verifier challenge"
  defp candidate_source("amd_hosted_gemma"), do: "AMD-hosted Gemma candidate"
  defp candidate_source(source), do: source

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

  attr :result, :map, required: true

  def judge_proof_result(assigns) do
    violations = get_in(assigns.result, [:unsafe_result, :verification, "violations"]) || []

    assigns = assign(assigns, :violation_count, length(violations))

    ~H"""
    <section
      id="judge-proof-result"
      class="judge-proof-result"
      role="status"
      aria-live="polite"
      aria-atomic="true"
    >
      <header class="judge-proof-result__header">
        <div>
          <p class="text-xs font-semibold uppercase tracking-wide text-success">
            Deterministic verifier proof
          </p>
          <h2 class="mt-1 text-lg font-semibold">One unsafe proposal blocked before recovery</h2>
        </div>
        <span class="badge badge-success">proof complete</span>
      </header>

      <ol class="judge-proof-result__steps" aria-label="Verifier proof sequence">
        <li data-proof-stage="emergency">
          <span class="judge-proof-result__number">1</span>
          <div>
            <p>Emergency reproduced</p>
            <strong>{@result.spike_state["ammonia_mg_l"]} mg/L ammonia</strong>
            <small>{@result.spike_state["dissolved_oxygen_mg_l"]} mg/L oxygen</small>
          </div>
        </li>
        <li data-proof-stage="blocked">
          <span class="judge-proof-result__number">2</span>
          <div>
            <p>Unsafe proposal blocked</p>
            <strong>0 unsafe actions executed</strong>
            <small>{@violation_count} verifier violation detected</small>
          </div>
        </li>
        <li data-proof-stage="recovered">
          <span class="judge-proof-result__number">3</span>
          <div>
            <p>Safe recovery admitted</p>
            <strong>{@result.final_state["ammonia_mg_l"]} mg/L ammonia</strong>
            <small>{@result.final_state["dissolved_oxygen_mg_l"]} mg/L oxygen · reward {@result.safe_result.reward}</small>
          </div>
        </li>
      </ol>

      <footer class="judge-proof-result__footer">
        <p>
          This is the repeatable deterministic verifier proof. The model-backed planning path remains
          separate and inspectable.
        </p>
        <a href="#agentic-mission" class="btn btn-sm btn-outline">
          Continue with live Gemma recovery <.icon name="hero-arrow-path" />
        </a>
      </footer>
    </section>
    """
  end

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
