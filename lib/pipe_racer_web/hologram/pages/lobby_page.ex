defmodule PipeRacerWeb.LobbyPage do
  use Hologram.Page

  alias Hologram.UI.Link
  alias PipeRacer.Race

  route "/race"

  layout PipeRacerWeb.MainLayout, page_title: "Pipe Racer · race your friends"

  def init(_params, component, _server) do
    put_state(component, code: Race.new_code(), join_error: nil)
  end

  def template do
    ~HOLO"""
    <section class="lobby">
      <h1>Race your friends</h1>
      <p class="lead">
        Open a room, send the link, and race on the same Elixir snippet.
        Everyone sees everyone's progress live.
      </p>

      <Link to={PipeRacerWeb.RacePage, room: @code} class="cta">create a room</Link>

      <form class="join" $submit="join">
        <input name="code" placeholder="room code" maxlength="5" autocomplete="off" spellcheck="false" />
        <button type="submit">join</button>
      </form>

      {%if @join_error}
        <p class="error">{@join_error}</p>
      {/if}
    </section>
    """
  end

  def action(:join, %{event: event}, component) do
    code = event |> Map.get(:code, "") |> String.trim() |> String.downcase()

    if Race.valid_code?(code) do
      put_page(component, PipeRacerWeb.RacePage, room: code)
    else
      put_state(component, :join_error, "Room codes are 5 letters or digits.")
    end
  end
end
