defmodule PipeRacerWeb.HealthController do
  use PipeRacerWeb, :controller

  # Polled by the host to decide whether the app is up.
  def show(conn, _params), do: text(conn, "ok")
end
