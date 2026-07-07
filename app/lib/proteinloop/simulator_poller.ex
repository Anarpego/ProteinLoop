defmodule ProteinLoop.SimulatorPoller do
  @moduledoc """
  Polls the Python simulator and broadcasts snapshots to LiveView clients.
  """

  use GenServer

  alias ProteinLoop.SimulatorClient

  @topic "simulator"

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def subscribe do
    Phoenix.PubSub.subscribe(ProteinLoop.PubSub, @topic)
  end

  def snapshot_now(source \\ "manual") do
    case SimulatorClient.state() do
      {:ok, %{"state" => state} = payload} ->
        %{
          connected?: true,
          source: source,
          state: state,
          reward: Map.get(payload, "reward"),
          error: nil
        }

      {:ok, state} when is_map(state) ->
        %{
          connected?: true,
          source: source,
          state: state,
          reward: nil,
          error: nil
        }

      {:error, reason} ->
        unavailable_snapshot(reason, source)
    end
  end

  def broadcast_snapshot(source \\ "poll") do
    snapshot = snapshot_now(source)
    Phoenix.PubSub.broadcast(ProteinLoop.PubSub, @topic, {:simulator_snapshot, snapshot})
    snapshot
  end

  @impl true
  def init(_opts) do
    schedule_poll(0)
    {:ok, %{}}
  end

  @impl true
  def handle_info(:poll, state) do
    broadcast_snapshot()
    schedule_poll()
    {:noreply, state}
  end

  defp unavailable_snapshot(reason, source) do
    %{
      connected?: false,
      source: source,
      state: SimulatorClient.fallback_state(),
      reward: nil,
      error: inspect(reason)
    }
  end

  defp schedule_poll(delay \\ poll_ms()) do
    Process.send_after(self(), :poll, delay)
  end

  defp poll_ms do
    Application.get_env(:proteinloop, :simulator_poll_ms, 1_000)
  end
end
