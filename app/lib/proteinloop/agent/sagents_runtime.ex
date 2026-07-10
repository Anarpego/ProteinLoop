defmodule ProteinLoop.Agent.SagentsRuntime do
  @moduledoc """
  Real Sagents orchestration for the ProteinLoop closed-loop action.

  Four subsystem agents produce parallel recommendations. A supervisor agent
  receives those reports and must call the verified `close_cycle` tool through
  `ProteinLoop.Agent.SafetyMode`.
  """

  alias LangChain.ChatModels.ChatOpenAI
  alias LangChain.Function
  alias LangChain.Message
  alias Sagents.Agent
  alias Sagents.Middleware.HumanInTheLoop
  alias Sagents.Middleware.SubAgent
  alias Sagents.MiddlewareEntry
  alias Sagents.State
  alias Sagents.SubAgent, as: SagentsSubAgent
  alias Sagents.SubAgent.Config

  alias ProteinLoop.Agent.SafetyMode
  alias ProteinLoop.SimulatorClient

  @sagents_version "0.9.0"
  @langchain_version "0.9.2"
  @until_tool "close_cycle"
  @hitl_tool "irreversible_cycle"

  @subsystems [
    %{
      name: "fish-tank",
      description: "Protect fish biomass while balancing feed, ammonia, and oxygen.",
      prompt: "Prioritize fish survival, ammonia control, oxygen, and conservative feed."
    },
    %{
      name: "freshwater-prawn",
      description:
        "Protect freshwater prawns while competing for oxygen, feed, and tank capacity.",
      prompt:
        "Prioritize prawn survival, oxygen, shelter capacity, and conservative resource use."
    },
    %{
      name: "hydroponia",
      description: "Balance plant nutrient uptake with water-quality recovery.",
      prompt: "Prioritize nitrate availability, plant uptake, and safe water exchange."
    },
    %{
      name: "duckweed-chickens",
      description: "Protect the duckweed reserve while supporting laying hens.",
      prompt: "Prioritize the duckweed reserve, harvest limits, and egg support."
    }
  ]

  @action_schema %{
    type: "object",
    properties: %{
      "feed_kg" => %{type: "number", minimum: 0, maximum: 0.25},
      "aeration_hours" => %{type: "number", minimum: 0, maximum: 24},
      "water_exchange_fraction" => %{type: "number", minimum: 0, maximum: 0.30},
      "duckweed_harvest_kg" => %{type: "number", minimum: 0},
      "note" => %{type: "string"}
    },
    required: [
      "feed_kg",
      "aeration_hours",
      "water_exchange_fraction",
      "duckweed_harvest_kg",
      "note"
    ]
  }

  @report_schema %{
    type: "object",
    properties: %{
      "status" => %{type: "string", enum: ["stable", "warning", "critical"]},
      "recommendation" => %{type: "string"},
      "resource_request" => %{type: "string"}
    },
    required: ["status", "recommendation", "resource_request"]
  }

  def status(opts \\ []) do
    endpoint =
      Keyword.get(opts, :endpoint, Application.get_env(:proteinloop, :gemma_endpoint))

    %{
      framework: "sagents",
      framework_version: application_version(:sagents, @sagents_version),
      langchain_version: application_version(:langchain, @langchain_version),
      distribution: Application.get_env(:sagents, :distribution, :local),
      execution_mode: SafetyMode,
      termination: "until_tool_success",
      subagent_runtime: SagentsSubAgent,
      subagents: Enum.map(@subsystems, & &1.name),
      agent_count: length(@subsystems) + 1,
      hitl_tool: @hitl_tool,
      endpoint_configured?: is_binary(endpoint) and endpoint != "",
      model: Keyword.get(opts, :model, Application.get_env(:proteinloop, :gemma_model, "gemma"))
    }
  end

  def run(opts \\ []) do
    state_fun = Keyword.get(opts, :state_fun, &SimulatorClient.state/0)

    with {:ok, %{"state" => ecosystem_state}} <- state_fun.(),
         {:ok, reports} <- run_subsystems(ecosystem_state, opts),
         agent <- build_supervisor_agent(ecosystem_state, opts),
         state <- supervisor_state(ecosystem_state, reports),
         {:ok, _final_state, tool_result} <-
           Agent.execute(agent, state, until_tool_success: @until_tool, max_runs: 3),
         {:ok, result} <- processed_result(tool_result) do
      {:ok,
       %{
         framework: "sagents",
         framework_version: @sagents_version,
         langchain_version: @langchain_version,
         distribution: Application.get_env(:sagents, :distribution, :local),
         execution_mode: SafetyMode,
         termination: "until_tool_success",
         tool: tool_result.name,
         subagents: reports,
         action: result["action"],
         state: result["state"],
         reward: result["reward"],
         verification: result["verification"]
       }}
    end
  end

  def request_irreversible(ecosystem_state, opts \\ []) when is_map(ecosystem_state) do
    opts = Keyword.put(opts, :supervisor_tool, @hitl_tool)
    agent = build_supervisor_agent(ecosystem_state, opts)

    state =
      State.new!(%{
        messages: [
          Message.new_user!(
            "Propose the bounded irreversible water exchange and duckweed harvest now."
          )
        ],
        metadata: %{"ecosystem_state" => ecosystem_state}
      })

    case Agent.execute(agent, state, until_tool: @hitl_tool, max_runs: 2) do
      {:interrupt, interrupted_state, interrupt_data} ->
        {:interrupt,
         %{
           agent: agent,
           state: interrupted_state,
           interrupt_data: interrupt_data,
           tool: @hitl_tool,
           allowed_decisions: [:approve, :edit, :reject]
         }}

      other ->
        other
    end
  end

  def resume_irreversible(pending, decision, edited_action \\ nil)

  def resume_irreversible(%{agent: agent, state: state} = pending, decision, edited_action)
      when decision in [:approve, :edit, :reject] do
    resume_agent = %{
      agent
      | tool_context: Map.put(agent.tool_context || %{}, :resume_after_hitl, true)
    }

    with {:ok, decision_data, submitted_action} <-
           resume_decision(pending, decision, edited_action),
         :ok <- verify_edited_action(agent, decision, submitted_action),
         {:ok, _final_state, tool_result} <-
           Agent.resume(resume_agent, state, [decision_data],
             until_tool: @hitl_tool,
             max_runs: 1,
             resume_after_hitl: true
           ) do
      resume_result(tool_result, decision, submitted_action)
    end
  end

  def resume_irreversible(_pending, decision, _edited_action) do
    {:error, {:invalid_hitl_decision, decision}}
  end

  def build_supervisor_agent(ecosystem_state, opts \\ []) when is_map(ecosystem_state) do
    tool_name = Keyword.get(opts, :supervisor_tool, @until_tool)
    validate_supervisor_tool!(tool_name)
    model = model_factory(opts).(tool_name)
    verify_fun = Keyword.get(opts, :verify_fun, &SimulatorClient.verify/1)
    step_fun = Keyword.get(opts, :step_fun, &SimulatorClient.step/1)

    Agent.new!(
      %{
        agent_id: Keyword.get(opts, :agent_id, unique_agent_id("supervisor")),
        name: "ProteinLoop supervisor",
        model: model,
        base_system_prompt: supervisor_prompt(ecosystem_state, tool_name),
        tools: [cycle_tool(tool_name, step_fun)],
        middleware: [
          {SubAgent,
           [
             model: model,
             subagents: subsystem_configs(opts),
             include_task_list: true
           ]},
          {HumanInTheLoop,
           [
             interrupt_on: %{
               @hitl_tool => %{allowed_decisions: [:approve, :edit, :reject]}
             }
           ]}
        ],
        mode: SafetyMode,
        max_runs: 3,
        tool_context: %{verify_action: verify_fun}
      },
      replace_default_middleware: true
    )
  end

  def describe(%Agent{} = agent) do
    %{
      framework: "sagents",
      version: application_version(:sagents, @sagents_version),
      langchain_version: application_version(:langchain, @langchain_version),
      distribution: Application.get_env(:sagents, :distribution, :local),
      execution_mode: agent.mode,
      until_tool: @until_tool,
      subagent_runtime: SagentsSubAgent,
      subagents: configured_subagent_names(agent),
      agent_count: length(configured_subagent_names(agent)) + 1,
      hitl_tools: configured_hitl_tools(agent)
    }
  end

  defp run_subsystems(ecosystem_state, opts) do
    timeout = Keyword.get(opts, :subsystem_timeout, 120_000)

    results =
      @subsystems
      |> Task.async_stream(
        &run_subsystem(&1, ecosystem_state, opts),
        ordered: true,
        max_concurrency: length(@subsystems),
        timeout: timeout
      )
      |> Enum.to_list()

    results
    |> Enum.reduce_while({:ok, []}, fn
      {:ok, {:ok, report}}, {:ok, reports} ->
        {:cont, {:ok, [report | reports]}}

      {:ok, {:error, reason}}, _acc ->
        {:halt, {:error, {:subsystem_agent_failed, reason}}}

      {:exit, reason}, _acc ->
        {:halt, {:error, {:subsystem_agent_failed, reason}}}

      other, _acc ->
        {:halt, {:error, {:subsystem_agent_failed, {:unexpected_task_result, other}}}}
    end)
    |> case do
      {:ok, reports} -> {:ok, Enum.reverse(reports)}
      error -> error
    end
  rescue
    error -> {:error, {:subsystem_agent_failed, error}}
  end

  defp run_subsystem(subsystem, ecosystem_state, opts) do
    model = model_factory(opts).("report_recommendation")

    agent =
      Agent.new!(
        %{
          agent_id: unique_agent_id(subsystem.name),
          name: subsystem.name,
          model: model,
          base_system_prompt: subsystem.prompt,
          tools: [report_tool()]
        },
        replace_default_middleware: true
      )

    subagent =
      SagentsSubAgent.new_from_compiled(
        parent_agent_id: unique_agent_id("cycle-parent"),
        instructions:
          "Evaluate this ProteinLoop state and submit one recommendation: #{Jason.encode!(ecosystem_state)}",
        compiled_agent: agent,
        until_tool: "report_recommendation",
        require_tool_success: true,
        max_runs: 2
      )

    case SagentsSubAgent.execute(subagent) do
      {:ok, _completed_subagent, tool_result} ->
        with {:ok, report} <- processed_result(tool_result) do
          {:ok, %{name: subsystem.name, runtime: SagentsSubAgent, report: report}}
        end

      {:error, %{error: reason}} ->
        {:error, {subsystem.name, reason}}

      other ->
        {:error, {subsystem.name, {:unexpected_subagent_result, other}}}
    end
  end

  defp subsystem_configs(opts) do
    model = model_factory(opts).("report_recommendation")
    tool = report_tool()

    Enum.map(@subsystems, fn subsystem ->
      Config.new!(%{
        name: subsystem.name,
        description: subsystem.description,
        system_prompt: subsystem.prompt,
        model: model,
        tools: [tool],
        until_tool_success: "report_recommendation",
        max_runs: 2
      })
    end)
  end

  defp supervisor_state(ecosystem_state, reports) do
    State.new!(%{
      messages: [
        Message.new_user!(
          "Current state: #{Jason.encode!(ecosystem_state)}\n" <>
            "Subsystem reports: #{Jason.encode!(reports)}\n" <>
            "Call #{@until_tool} exactly once with a conservative verified action."
        )
      ],
      metadata: %{"ecosystem_state" => ecosystem_state, "subsystem_reports" => reports}
    })
  end

  defp supervisor_prompt(ecosystem_state, tool_name) do
    duckweed_limit = max(number(ecosystem_state, "duckweed_kg") - 0.5, 0.0)

    """
    You are the ProteinLoop supervisor coordinating four subsystem agents.
    Call #{tool_name} exactly once and do not answer with prose.
    Hard bounds: feed_kg 0..0.25; use at most 0.08 when ammonia is at least 1.5,
    and 0 when collapsed. aeration_hours 0..24. water_exchange_fraction 0..0.30.
    duckweed_harvest_kg 0..#{Float.round(duckweed_limit, 3)} so at least 0.5 kg remains.
    The deterministic simulator verifier is authoritative.
    """
  end

  defp cycle_tool(name, step_fun) do
    Function.new!(%{
      name: name,
      description: "Submit one ecosystem action through the deterministic simulator verifier.",
      parameters_schema: @action_schema,
      function: fn action, _context -> execute_cycle(step_fun, action) end
    })
  end

  defp validate_supervisor_tool!(name) when name in [@until_tool, @hitl_tool], do: :ok

  defp validate_supervisor_tool!(name) do
    raise ArgumentError, "unsupported supervisor tool: #{inspect(name)}"
  end

  defp report_tool do
    Function.new!(%{
      name: "report_recommendation",
      description: "Return one concise subsystem status and resource recommendation.",
      parameters_schema: @report_schema,
      function: fn report, _context -> {:ok, Jason.encode!(report), report} end
    })
  end

  defp execute_cycle(step_fun, action) do
    case step_fun.(action) do
      {:ok, result} ->
        result = Map.put_new(result, "action", action)
        {:ok, Jason.encode!(result), result}

      {:error, %{body: body}} ->
        {:error, Jason.encode!(body)}

      {:error, reason} ->
        {:error, inspect(reason)}
    end
  end

  defp processed_result(%{processed_content: result}) when is_map(result), do: {:ok, result}

  defp processed_result(%{content: content}) when is_binary(content) do
    Jason.decode(content)
  end

  defp processed_result(_tool_result), do: {:error, :missing_processed_tool_result}

  defp resume_decision(pending, :approve, nil) do
    {:ok, %{type: :approve}, pending_action(pending)}
  end

  defp resume_decision(_pending, :edit, edited_action) when is_map(edited_action) do
    {:ok, %{type: :edit, arguments: edited_action}, edited_action}
  end

  defp resume_decision(pending, :reject, nil) do
    {:ok, %{type: :reject}, pending_action(pending)}
  end

  defp resume_decision(_pending, decision, action) do
    {:error, {:invalid_hitl_decision_data, decision, action}}
  end

  defp pending_action(pending) do
    pending.interrupt_data.action_requests
    |> List.first()
    |> Map.fetch!(:arguments)
  end

  defp verify_edited_action(_agent, decision, _action) when decision != :edit, do: :ok

  defp verify_edited_action(agent, :edit, action) do
    verifier = get_in(agent.tool_context || %{}, [:verify_action])

    if is_function(verifier, 1) do
      case verifier.(action) do
        {:ok, %{"verification" => %{"ok" => true}}} ->
          :ok

        {:ok, %{"verification" => verification}} ->
          {:error, {:unsafe_edited_action, verification}}

        {:error, reason} ->
          {:error, {:edited_action_verification_failed, reason}}

        other ->
          {:error, {:invalid_edited_action_verification, other}}
      end
    else
      {:error, :edited_action_verifier_not_configured}
    end
  end

  defp resume_result(tool_result, :reject, action) do
    {:ok,
     %{
       decision: :rejected,
       action: action,
       mutated: false,
       message: tool_result.content
     }}
  end

  defp resume_result(tool_result, decision, submitted_action) do
    with {:ok, result} <- processed_result(tool_result) do
      {:ok,
       %{
         decision: if(decision == :approve, do: :approved, else: :edited),
         action: Map.get(result, "action", submitted_action),
         state: result["state"],
         reward: result["reward"],
         verification: result["verification"],
         mutated: true
       }}
    end
  end

  defp model_factory(opts) do
    Keyword.get(opts, :model_factory, fn tool_name -> openai_model(tool_name, opts) end)
  end

  defp openai_model(tool_name, opts) do
    endpoint =
      Keyword.get(opts, :endpoint, Application.get_env(:proteinloop, :gemma_endpoint))

    unless is_binary(endpoint) and endpoint != "" do
      raise ArgumentError, "GEMMA_ENDPOINT is required for the Sagents runtime"
    end

    model = Keyword.get(opts, :model, Application.get_env(:proteinloop, :gemma_model, "gemma"))
    api_key = Keyword.get(opts, :api_key, Application.get_env(:proteinloop, :gemma_api_key))

    ChatOpenAI.new!(%{
      endpoint: String.trim_trailing(endpoint, "/") <> "/v1/chat/completions",
      model: model,
      api_key: empty_key(api_key),
      temperature: Keyword.get(opts, :temperature, 0.0),
      stream: false,
      max_tokens: Application.get_env(:proteinloop, :gemma_max_tokens, 1024),
      receive_timeout: Application.get_env(:proteinloop, :gemma_receive_timeout, 120_000),
      parallel_tool_calls: false,
      tool_choice: %{"type" => "function", "function" => %{"name" => tool_name}}
    })
  end

  defp configured_subagent_names(agent) do
    configured =
      agent.middleware
      |> middleware_config(SubAgent)
      |> Map.get(:agent_map, %{})
      |> Map.keys()
      |> MapSet.new()

    @subsystems
    |> Enum.map(& &1.name)
    |> Enum.filter(&MapSet.member?(configured, &1))
  end

  defp configured_hitl_tools(agent) do
    agent.middleware
    |> middleware_config(HumanInTheLoop)
    |> Map.get(:interrupt_on, %{})
    |> Map.keys()
    |> Enum.sort()
  end

  defp middleware_config(middleware, module) do
    case Enum.find(middleware, &match?(%MiddlewareEntry{module: ^module}, &1)) do
      %MiddlewareEntry{config: config} -> config
      nil -> %{}
    end
  end

  defp application_version(app, fallback) do
    case Application.spec(app, :vsn) do
      nil -> fallback
      version -> to_string(version)
    end
  end

  defp unique_agent_id(prefix) do
    "proteinloop-#{prefix}-#{System.unique_integer([:positive, :monotonic])}"
  end

  defp empty_key(nil), do: "local-no-key"
  defp empty_key(""), do: "local-no-key"
  defp empty_key(key), do: key

  defp number(map, key) do
    case Map.get(map, key) do
      value when is_integer(value) -> value * 1.0
      value when is_float(value) -> value
      value when is_binary(value) -> String.to_float(value)
      _ -> 0.0
    end
  end
end
