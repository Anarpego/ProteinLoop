defmodule ProteinLoop.Application do
  # See https://elixir.hexdocs.pm/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    ProteinLoop.Agent.DistributionConfig.configure!()

    children = [
      ProteinLoopWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:proteinloop, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: ProteinLoop.PubSub},
      {ProteinLoop.ClusterConnector,
       peers: Application.get_env(:proteinloop, :cluster_peers, [])},
      Sagents.Supervisor,
      ProteinLoop.Agent.ApprovalQueue,
      ProteinLoop.SimulatorPoller,
      # Start to serve requests, typically the last entry
      ProteinLoopWeb.Endpoint
    ]

    # See https://elixir.hexdocs.pm/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ProteinLoop.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ProteinLoopWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
