defmodule PipeRacerWeb.Router do
  use PipeRacerWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {PipeRacerWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  get "/health", PipeRacerWeb.HealthController, :show

  # Other scopes may use custom stacks.
  # scope "/api", PipeRacerWeb do
  #   pipe_through :api
  # end
end
