defmodule ProteinLoopWeb.Router do
  use ProteinLoopWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {ProteinLoopWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", ProteinLoopWeb do
    pipe_through :browser

    live "/", OperatorLive, :index
    live "/producer", ProducerLive, :index
  end

  scope "/api/horde", ProteinLoopWeb do
    pipe_through :api

    get "/status", HordeController, :status
    post "/probes", HordeController, :create
    get "/probes/:id", HordeController, :show
    delete "/probes/:id", HordeController, :delete
  end
end
