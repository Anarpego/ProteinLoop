defmodule ProteinLoop.Agent.SafetyMode do
  @moduledoc """
  Sagents execution mode with a deterministic ecosystem preflight step.

  Tool arguments are checked through the Python simulator's non-mutating
  verifier before Sagents can execute either cycle mutation tool.
  """

  @behaviour LangChain.Chains.LLMChain.Mode

  import LangChain.Chains.LLMChain.Mode.Steps
  import Sagents.Mode.Steps

  alias LangChain.Chains.LLMChain
  alias LangChain.LangChainError

  @protected_tools ["close_cycle", "irreversible_cycle"]

  @impl true
  def run(%LLMChain{} = chain, opts) do
    chain = ensure_mode_state(chain)
    opts = normalize_until_tool_opts(opts)

    if Keyword.get(opts, :resume_after_hitl, false) or
         get_in(chain.custom_context || %{}, [:resume_after_hitl]) == true do
      finish_resumed_tool(chain, opts)
    else
      do_run(chain, opts)
    end
  end

  @doc """
  Validate pending ecosystem tool calls without executing them.
  """
  def verify_ecosystem_safety({:continue, %LLMChain{} = chain}) do
    calls = protected_tool_calls(chain)

    case calls do
      [] ->
        {:continue, chain}

      _calls ->
        with verifier when is_function(verifier, 1) <-
               get_in(chain.custom_context || %{}, [:verify_action]),
             {:ok, verifications} <- verify_calls(calls, verifier) do
          verified_chain =
            LLMChain.update_custom_context(chain, %{safety_verifications: verifications})

          {:continue, verified_chain}
        else
          nil ->
            safety_error(chain, "simulator verifier is not configured")

          {:error, reason} ->
            safety_error(chain, format_reason(reason))
        end
    end
  end

  def verify_ecosystem_safety(terminal), do: terminal

  defp do_run(chain, opts) do
    {:continue, chain}
    |> call_llm()
    |> check_max_runs(Keyword.put_new(opts, :max_runs, 8))
    |> check_pause(opts)
    |> verify_ecosystem_safety()
    |> check_pre_tool_hitl(opts)
    |> execute_tools()
    |> propagate_state(opts)
    |> check_tool_interrupts(opts)
    |> maybe_check_until_tool(opts)
    |> continue_or_done_safe(&do_run/2, opts)
  end

  defp finish_resumed_tool(chain, opts) do
    case maybe_check_until_tool({:continue, chain}, opts) do
      {:continue, resumed_chain} ->
        {:error, resumed_chain,
         LangChainError.exception(
           type: "resume_tool_result_missing",
           message: "HITL resume completed without the expected tool result"
         )}

      terminal ->
        terminal
    end
  end

  defp protected_tool_calls(%LLMChain{last_message: %{role: :assistant, tool_calls: calls}})
       when is_list(calls) do
    Enum.filter(calls, &(&1.name in @protected_tools))
  end

  defp protected_tool_calls(_chain), do: []

  defp verify_calls(calls, verifier) do
    Enum.reduce_while(calls, {:ok, []}, fn call, {:ok, accepted} ->
      case verifier.(call.arguments) do
        {:ok, %{"verification" => %{"ok" => true} = verification}} ->
          {:cont, {:ok, [verification | accepted]}}

        {:ok, %{"verification" => %{"ok" => false} = verification}} ->
          {:halt, {:error, verification}}

        {:error, reason} ->
          {:halt, {:error, reason}}

        other ->
          {:halt, {:error, {:invalid_verifier_response, other}}}
      end
    end)
    |> case do
      {:ok, verifications} -> {:ok, Enum.reverse(verifications)}
      error -> error
    end
  end

  defp safety_error(chain, message) do
    {:error, chain, LangChainError.exception(type: "unsafe_ecosystem_action", message: message)}
  end

  defp format_reason(%{"violations" => violations}) when is_list(violations) do
    Enum.join(violations, "; ")
  end

  defp format_reason(reason), do: inspect(reason)

  defp normalize_until_tool_opts(opts) do
    case normalize_tool_names(Keyword.get(opts, :until_tool)) do
      nil ->
        opts

      names ->
        opts
        |> Keyword.put(:tool_names, names)
        |> Keyword.put(:until_tool_active, true)
    end
  end

  defp normalize_tool_names(nil), do: nil
  defp normalize_tool_names([]), do: nil
  defp normalize_tool_names(name) when is_binary(name), do: [name]
  defp normalize_tool_names(names) when is_list(names), do: names

  defp maybe_check_until_tool(pipeline_result, opts) do
    cond do
      not Keyword.get(opts, :until_tool_active, false) ->
        pipeline_result

      Keyword.get(opts, :require_tool_success, false) ->
        check_until_tool_success(pipeline_result, opts)

      true ->
        check_until_tool(pipeline_result, opts)
    end
  end
end
