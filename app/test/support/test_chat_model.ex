defmodule ProteinLoop.TestChatModel do
  @moduledoc false

  @behaviour LangChain.ChatModels.ChatModel

  alias LangChain.Message
  alias LangChain.Message.ToolCall

  defstruct tool_name: nil, arguments: %{}, callbacks: [], error: nil

  def new(tool_name, arguments) do
    %__MODULE__{tool_name: tool_name, arguments: arguments}
  end

  def failing(message) do
    %__MODULE__{
      error: LangChain.LangChainError.exception(type: "test_model_error", message: message)
    }
  end

  @impl true
  def call(%__MODULE__{error: %LangChain.LangChainError{} = error}, _messages, _tools) do
    {:error, error}
  end

  @impl true
  def call(%__MODULE__{} = model, _messages, _tools) do
    tool_call =
      ToolCall.new!(%{
        status: :complete,
        call_id: "call-#{System.unique_integer([:positive])}",
        name: model.tool_name,
        arguments: model.arguments
      })

    {:ok, [Message.new_assistant!(%{tool_calls: [tool_call]})]}
  end

  @impl true
  def provider, do: "proteinloop_test"

  @impl true
  def retry_on_fallback?(_error), do: false

  @impl true
  def serialize_config(%__MODULE__{} = model) do
    %{
      "module" => Atom.to_string(__MODULE__),
      "tool_name" => model.tool_name,
      "arguments" => model.arguments
    }
  end

  @impl true
  def restore_from_map(%{"tool_name" => tool_name, "arguments" => arguments}) do
    {:ok, new(tool_name, arguments)}
  end

  def restore_from_map(_data), do: {:error, "invalid ProteinLoop test model"}
end
