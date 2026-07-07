defmodule ProteinLoopWeb.PageController do
  use ProteinLoopWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
