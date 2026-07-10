defmodule ProteinLoop.Agent.SafetyModeTest do
  use ExUnit.Case, async: true

  alias LangChain.Chains.LLMChain
  alias LangChain.LangChainError
  alias LangChain.Message
  alias LangChain.Message.ToolCall
  alias LangChain.Message.ToolResult
  alias ProteinLoop.Agent.SafetyMode
  alias ProteinLoop.TestChatModel

  test "verify_ecosystem_safety records accepted preflight evidence" do
    action = safe_action()
    chain = chain_with_action(action, &safe_verifier/1)

    assert {:continue, verified_chain} =
             SafetyMode.verify_ecosystem_safety({:continue, chain})

    assert [%{"ok" => true, "violations" => []}] =
             verified_chain.custom_context.safety_verifications
  end

  test "verify_ecosystem_safety terminates unsafe calls before execution" do
    unsafe = Map.put(safe_action(), "feed_kg", 4.0)
    chain = chain_with_action(unsafe, &unsafe_verifier/1)

    assert {:error, _chain, %LangChainError{type: "unsafe_ecosystem_action", message: message}} =
             SafetyMode.verify_ecosystem_safety({:continue, chain})

    assert message =~ "feed_kg"
  end

  test "verify_ecosystem_safety preserves terminal pipeline results" do
    terminal = {:error, :chain, :already_failed}
    assert SafetyMode.verify_ecosystem_safety(terminal) == terminal
  end

  test "resume_after_hitl returns the existing tool result without another model call" do
    result =
      ToolResult.new!(%{
        tool_call_id: "call-hitl",
        name: "irreversible_cycle",
        content: "approved",
        processed_content: %{"state" => %{"day" => 1}}
      })

    chain =
      LLMChain.new!(%{llm: TestChatModel.new("unexpected_model_call", %{})})
      |> LLMChain.add_message(Message.new_tool_result!(%{tool_results: [result]}))

    assert {:ok, _chain, returned} =
             SafetyMode.run(chain,
               resume_after_hitl: true,
               until_tool: "irreversible_cycle"
             )

    assert returned.tool_call_id == "call-hitl"
    assert returned.processed_content == %{"state" => %{"day" => 1}}
  end

  defp chain_with_action(action, verifier) do
    tool_call =
      ToolCall.new!(%{
        status: :complete,
        call_id: "call-safety",
        name: "close_cycle",
        arguments: action
      })

    LLMChain.new!(%{
      llm: TestChatModel.new("close_cycle", action),
      custom_context: %{verify_action: verifier}
    })
    |> LLMChain.add_message(Message.new_assistant!(%{tool_calls: [tool_call]}))
  end

  defp safe_verifier(action) do
    {:ok,
     %{
       "action" => action,
       "verification" => %{"ok" => true, "violations" => [], "warnings" => []}
     }}
  end

  defp unsafe_verifier(_action) do
    {:ok,
     %{
       "verification" => %{
         "ok" => false,
         "violations" => ["feed_kg exceeds safe daily limit"],
         "warnings" => []
       }
     }}
  end

  defp safe_action do
    %{
      "feed_kg" => 0.1,
      "aeration_hours" => 12.0,
      "water_exchange_fraction" => 0.15,
      "duckweed_harvest_kg" => 0.2,
      "note" => "safe"
    }
  end
end
