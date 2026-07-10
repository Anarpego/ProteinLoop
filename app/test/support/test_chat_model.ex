defmodule ProteinLoop.TestChatModel do
  @moduledoc false

  @behaviour LangChain.ChatModels.ChatModel

  alias LangChain.Message
  alias LangChain.Message.ToolCall

  defstruct tool_name: nil, arguments: %{}, callbacks: [], error: nil, observer: nil

  def new(tool_name, arguments, opts \\ []) do
    %__MODULE__{
      tool_name: tool_name,
      arguments: arguments,
      observer: Keyword.get(opts, :observer)
    }
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
  def call(%__MODULE__{} = model, messages, _tools) do
    if is_pid(model.observer) do
      send(
        model.observer,
        {:test_chat_model_call, model.tool_name, Enum.map(messages, &Map.get(&1, :content))}
      )
    end

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
