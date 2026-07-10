defmodule ProteinLoop.Agent.ApprovalQueue do
  @moduledoc """
  One-slot Spanish HITL queue for irreversible producer actions.

  The queue stores intent only. Simulator mutation still happens through
  `ProteinLoop.SimulatorClient.step/1` after the producer approves or edits.
  """

  use GenServer

  @topic "approval_queue"

  @type request :: %{
          id: pos_integer(),
          action: map(),
          prompt: String.t(),
          rationale: String.t(),
          requested_by: String.t(),
          source: String.t(),
          allowed_decisions: [atom()],
          tool_call_id: String.t() | nil,
          runtime_context: map() | nil,
          status: String.t(),
          created_at: String.t()
        }

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{pending: nil, decisions: []}, name: __MODULE__)
  end

  def subscribe do
    Phoenix.PubSub.subscribe(ProteinLoop.PubSub, @topic)
  end

  def snapshot do
    GenServer.call(__MODULE__, :snapshot)
  end

  def reset do
    GenServer.call(__MODULE__, :reset)
  end

  def claim(id) when is_integer(id) do
    GenServer.call(__MODULE__, {:claim, id})
  end

  def release(id) when is_integer(id) do
    GenServer.call(__MODULE__, {:release, id})
  end

  def request_irreversible_action(state \\ %{}, opts \\ []) do
    request(irreversible_action(state), opts)
  end

  def request(action, opts \\ []) when is_map(action) do
    GenServer.call(__MODULE__, {:request, action, opts})
  end

  def resolve(id, decision, result \\ %{}) when decision in [:approved, :edited, :rejected] do
    GenServer.call(__MODULE__, {:resolve, id, decision, result})
  end

  def irreversible_action(state \\ %{}) do
    duckweed = number(state, "duckweed_kg", 3.0)
    harvest = min(0.4, max(0.0, duckweed - 1.0))

    %{
      "feed_kg" => 0.0,
      "aeration_hours" => 12.0,
      "water_exchange_fraction" => 0.20,
      "duckweed_harvest_kg" => Float.round(harvest, 3),
      "note" => "producer_irreversible_harvest"
    }
  end

  def half_action(action) when is_map(action) do
    action
    |> Map.update("water_exchange_fraction", 0.0, &Float.round(&1 / 2, 3))
    |> Map.update("duckweed_harvest_kg", 0.0, &Float.round(&1 / 2, 3))
    |> Map.put("note", "producer_half_irreversible")
  end

  @impl true
  def init(state), do: {:ok, state}

  @impl true
  def handle_call(:snapshot, _from, state) do
    {:reply, state, state}
  end

  def handle_call(:reset, _from, _state) do
    state = %{pending: nil, decisions: []}
    broadcast(state)
    {:reply, state, state}
  end

  def handle_call({:request, action, opts}, _from, %{pending: nil} = state) do
    request = %{
      id: System.unique_integer([:positive]),
      action: action,
      prompt: Keyword.get(opts, :prompt, default_prompt(action)),
      rationale: Keyword.get(opts, :rationale, "accion irreversible requiere aprobacion humana"),
      requested_by: Keyword.get(opts, :requested_by, "operator"),
      source: Keyword.get(opts, :source, "manual"),
      allowed_decisions: Keyword.get(opts, :allowed_decisions, [:approve, :edit, :reject]),
      tool_call_id: Keyword.get(opts, :tool_call_id),
      runtime_context: Keyword.get(opts, :runtime_context),
      status: "pending",
      created_at: DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()
    }

    state = %{state | pending: request}
    broadcast(state)

    {:reply, {:ok, request, state}, state}
  end

  def handle_call({:request, _action, _opts}, _from, %{pending: pending} = state) do
    {:reply, {:pending, pending, state}, state}
  end

  def handle_call({:claim, id}, _from, %{pending: %{id: id, status: "pending"} = pending} = state) do
    claimed = %{pending | status: "processing"}
    state = %{state | pending: claimed}
    broadcast(state)
    {:reply, {:ok, claimed, state}, state}
  end

  def handle_call(
        {:claim, id},
        _from,
        %{pending: %{id: id, status: "processing"}} = state
      ) do
    {:reply, {:error, :already_processing, state}, state}
  end

  def handle_call({:claim, _id}, _from, state) do
    {:reply, {:error, :not_pending, state}, state}
  end

  def handle_call(
        {:release, id},
        _from,
        %{pending: %{id: id, status: "processing"} = pending} = state
      ) do
    released = %{pending | status: "pending"}
    state = %{state | pending: released}
    broadcast(state)
    {:reply, {:ok, released, state}, state}
  end

  def handle_call({:release, _id}, _from, state) do
    {:reply, {:error, :not_processing, state}, state}
  end

  def handle_call(
        {:resolve, id, decision, result},
        _from,
        %{pending: %{id: id, status: "processing"} = pending} = state
      ) do
    entry =
      pending
      |> Map.delete(:runtime_context)
      |> Map.put(:status, Atom.to_string(decision))
      |> Map.put(
        :resolved_at,
        DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()
      )
      |> Map.put(:result, result)

    state = %{pending: nil, decisions: Enum.take([entry | state.decisions], 5)}
    broadcast(state)

    {:reply, {:ok, entry, state}, state}
  end

  def handle_call({:resolve, _id, _decision, _result}, _from, state) do
    {:reply, {:error, :not_processing, state}, state}
  end

  defp broadcast(state) do
    Phoenix.PubSub.broadcast(ProteinLoop.PubSub, @topic, {:approval_queue, state})
  end

  defp default_prompt(action) do
    "El agente propone cambiar #{percent(action["water_exchange_fraction"])}% del agua y cosechar #{action["duckweed_harvest_kg"]} kg de lenteja. Procedo?"
  end

  defp percent(value) when is_float(value), do: round(value * 100)
  defp percent(value) when is_integer(value), do: value * 100
  defp percent(_value), do: 0

  defp number(map, key, default) do
    case Map.get(map, key, default) do
      value when is_number(value) -> value * 1.0
      _value -> default
    end
  end
end
