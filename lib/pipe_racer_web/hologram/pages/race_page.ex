defmodule PipeRacerWeb.RacePage do
  use Hologram.Page
  use Hologram.JS

  alias Hologram.UI.Link
  alias PipeRacer.Race
  alias PipeRacer.Race.Room
  alias PipeRacer.Snippets
  alias PipeRacer.Typing
  alias PipeRacerWeb.Components.CodeView
  alias PipeRacerWeb.Components.KeyCapture
  alias PipeRacerWeb.Components.MistakeHint
  alias PipeRacerWeb.Components.PlayerList
  alias PipeRacerWeb.Components.Stats
  alias PipeRacerWeb.Keys

  route "/race/:room"

  param :room, :string

  layout PipeRacerWeb.MainLayout, page_title: "Pipe Racer · race"

  @tick_ms 250
  # Each tab pings the room this often; the reply also resyncs the tab.
  @ping_ms 5_000
  @countdown 3
  # Progress is sent to the room in steps of this many percent, not per key.
  @report_step 4

  # The player joins from the browser (see :join), not here: a player is a
  # tab, identified by an id kept in sessionStorage so a refresh is the same
  # player again. Hologram's instance_id is new on every refresh, which left a
  # ghost racer behind each time.
  def init(params, component, server) do
    code = params.room
    server = put_session(server, :name, get_session(server, :name) || Race.random_name())
    component = put_state(component, initial_state(code))

    if Race.valid_code?(code) do
      component =
        component
        |> put_state(:share_url, PipeRacerWeb.Endpoint.url() <> "/race/" <> code)
        |> join_room(Room.snapshot(code))
        |> put_action(:join)

      {component, put_subscription(server, {:race, code})}
    else
      {put_state(component, :error, "That room code doesn't look right."), server}
    end
  end

  def template do
    ~HOLO"""
    <KeyCapture />

    {%if @error}
      <section class="notice">
        <p>{@error}</p>
        <Link to={PipeRacerWeb.LobbyPage}>back to races</Link>
      </section>
    {%else}
      <section class="race">
        <div class="room-bar">
          <div>room <strong>{@room}</strong></div>
          <div class="share">invite: <code>{@share_url}</code></div>
        </div>

        <PlayerList players={@players} me={@me} />

        {%if @phase == :lobby}
          <div class="phase-note">{lobby_note(@players)}</div>
          <button class="primary" $click={command: :start, params: %{room: @room}}>start race</button>
        {/if}

        {%if @phase == :watching}
          <div class="phase-note">A race is on. You're in the next one.</div>
        {/if}

        {%if @phase == :countdown}
          <div class="countdown">{@countdown}</div>
          <div class="phase-note"># {@title}</div>
        {/if}

        {%if @phase == :racing or @phase == :done}
          <div class="snippet-title"><span class="hash">#</span> {@title}</div>
          <Stats
            wpm={Typing.wpm(@game, @now)}
            accuracy={Typing.accuracy(@game)}
            seconds={div(Typing.elapsed_ms(@game, @now), 1000)}
            progress={Typing.progress(@game)}
          />
          <CodeView
            segments={Typing.segments(@game)}
            finished={Typing.finished?(@game)}
            blocked={Typing.blocked?(@game)}
          />
          <MistakeHint mistake={Typing.mistake(@game)} />
        {/if}

        {%if @phase == :done}
          <div class="result">
            <div class="result-line">
              <strong>{Typing.wpm(@game, @now)} wpm</strong> at {Typing.accuracy(@game)}% accuracy
            </div>
            {%if @room_status == :racing}
              <div class="hint">Waiting for the others. The race ends a minute after the first finish.</div>
            {%else}
              <button class="primary" $click={command: :start, params: %{room: @room}}>race again</button>
            {/if}
          </div>
        {/if}
      </section>
    {/if}
    """
  end

  # Actions (client)

  def action(:noop, _params, component), do: component

  def action(:room_updated, %{room: room}, component), do: sync_room(component, room)

  def action(:count, %{race_id: race_id}, component) do
    state = component.state

    cond do
      race_id != state.race_id or state.phase != :countdown ->
        component

      state.countdown > 1 ->
        component
        |> put_state(:countdown, state.countdown - 1)
        |> put_action(name: :count, params: %{race_id: race_id}, delay: 1_000)

      true ->
        put_state(component, phase: :racing, countdown: 0)
    end
  end

  def action(:key, %{event: event}, component) do
    if component.state.phase == :racing do
      handle_key(component, Keys.classify(event))
    else
      component
    end
  end

  def action(:tick, %{run: run}, component) do
    if run == component.state.run and component.state.phase == :racing do
      component
      |> put_state(:now, now())
      |> put_action(name: :tick, params: %{run: run}, delay: @tick_ms)
    else
      component
    end
  end

  # Runs once the page is live in the browser, because the tab id lives in
  # the browser's sessionStorage.
  def action(:join, _params, component) do
    me = tab_id()

    component
    |> put_state(:me, me)
    |> put_command(:join, room: component.state.room, player: me)
    |> put_action(name: :ping, delay: @ping_ms)
  end

  def action(:room_full, _params, component) do
    put_state(component, :error, "This room is full, 8 racers max.")
  end

  def action(:ping, _params, component) do
    if component.state.error do
      component
    else
      component
      |> put_command(:ping, room: component.state.room, player: component.state.me)
      |> put_action(name: :ping, delay: @ping_ms)
    end
  end

  # Commands (server)

  def command(:start, %{room: code}, server) do
    {:ok, room} = Room.start_race(code)
    put_broadcast(server, {:race, code}, :room_updated, room: room)
  end

  def command(:join, %{room: code, player: player}, server) do
    case Room.join(code, player, get_session(server, :name) || Race.random_name()) do
      {:ok, room} -> put_broadcast(server, {:race, code}, :room_updated, room: room)
      {:error, :full} -> put_action(server, :room_full)
    end
  end

  def command(:report, %{room: code, player: player, progress: progress, wpm: wpm}, server) do
    {:ok, room} = Room.report(code, player, progress, wpm)
    put_broadcast(server, {:race, code}, :room_updated, room: room)
  end

  # Keeps this tab in the room. Hologram realtime is fire-and-forget, so a tab
  # that was asleep or offline misses broadcasts; the reply also hands this
  # tab the latest room state to catch it up.
  def command(:ping, %{room: code, player: player}, server) do
    {:ok, room, changed?} = Room.ping(code, player)

    {room, server} =
      cond do
        # Dropped while the tab slept; come back in.
        not Enum.any?(room.players, &(&1.id == player)) ->
          name = get_session(server, :name) || Race.random_name()

          case Room.join(code, player, name) do
            {:ok, room} -> {room, put_broadcast(server, {:race, code}, :room_updated, room: room)}
            {:error, :full} -> {room, server}
          end

        changed? ->
          {room, put_broadcast(server, {:race, code}, :room_updated, room: room)}

        true ->
          {room, server}
      end

    put_action(server, :room_updated, room: room)
  end

  # Helpers

  defp initial_state(code) do
    %{
      room: code,
      me: nil,
      error: nil,
      share_url: "",
      players: [],
      room_status: :lobby,
      race_id: 0,
      phase: :lobby,
      countdown: 0,
      snippet_index: 0,
      title: "",
      game: Typing.new(""),
      now: 0,
      run: 0,
      last_sent: 0
    }
  end

  # First look at the room: someone arriving mid-race waits for the next one.
  defp join_room(component, room) do
    phase = if room.status == :racing, do: :watching, else: :lobby

    put_state(component,
      players: room.players,
      room_status: room.status,
      race_id: room.race_id,
      phase: phase
    )
  end

  defp sync_room(component, room) do
    state = component.state
    component = put_state(component, players: room.players, room_status: room.status)

    cond do
      room.race_id > state.race_id ->
        start_countdown(component, room)

      room.status == :finished and state.phase == :watching ->
        put_state(component, :phase, :lobby)

      true ->
        component
    end
  end

  defp start_countdown(component, room) do
    snippet = Snippets.get(room.snippet_index)
    me = Enum.find(room.players, &(&1.id == component.state.me))

    component =
      put_state(component,
        race_id: room.race_id,
        snippet_index: room.snippet_index,
        title: snippet.title,
        game: Typing.new(snippet.code),
        now: 0,
        run: component.state.run + 1,
        last_sent: 0
      )

    if me != nil and me.racing do
      component
      |> put_state(phase: :countdown, countdown: @countdown)
      |> put_action(name: :count, params: %{race_id: room.race_id}, delay: 1_000)
    else
      put_state(component, :phase, :watching)
    end
  end

  defp handle_key(component, :enter), do: apply_input(component, &Typing.type(&1, "\n", &2))

  defp handle_key(component, :backspace) do
    apply_input(component, fn game, _now -> Typing.backspace(game) end)
  end

  defp handle_key(component, :backspace_to_mistake) do
    apply_input(component, fn game, _now -> Typing.backspace_to_mistake(game) end)
  end

  defp handle_key(component, {:char, char}),
    do: apply_input(component, &Typing.type(&1, char, &2))

  # No restarting mid-race.
  defp handle_key(component, _other), do: component

  defp apply_input(component, fun) do
    now = now()
    before = component.state.game
    game = fun.(before, now)
    component = put_state(component, game: game, now: now)

    component =
      if not Typing.started?(before) and Typing.started?(game) do
        put_action(component, name: :tick, params: %{run: component.state.run}, delay: @tick_ms)
      else
        component
      end

    report_progress(component, game, now)
  end

  defp report_progress(component, game, now) do
    progress = Typing.progress(game)
    finished? = Typing.finished?(game)

    if finished? or progress - component.state.last_sent >= @report_step do
      component
      |> put_state(:last_sent, progress)
      |> put_state(:phase, if(finished?, do: :done, else: :racing))
      |> put_command(:report,
        room: component.state.room,
        player: component.state.me,
        progress: if(finished?, do: 100, else: min(progress, 99)),
        wpm: Typing.wpm(game, now)
      )
    else
      component
    end
  end

  defp lobby_note(players) do
    case length(players) do
      1 -> "Just you so far. Send the invite link, or start and race yourself."
      n -> "#{n} racers here. Anyone can start."
    end
  end

  # A per-tab id that survives a refresh; a new tab gets a new one.
  defp tab_id do
    case JS.call(:sessionStorage, :getItem, ["pipe_racer_tab"]) do
      nil ->
        id = JS.call(:crypto, :randomUUID, [])
        JS.call(:sessionStorage, :setItem, ["pipe_racer_tab", id])
        id

      id ->
        id
    end
  end

  defp now, do: System.monotonic_time(:millisecond)
end
