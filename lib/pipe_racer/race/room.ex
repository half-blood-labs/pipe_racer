defmodule PipeRacer.Race.Room do
  @moduledoc """
  One race room: who is in it, which snippet they race on, and how far each
  player got. Each room is a process, found by its code through a Registry.

  Players are keyed by a per-tab id the browser keeps across refreshes. Tabs
  that close never say goodbye, so every player pings the room and anyone
  silent for `@stale_ms` is dropped.
  """
  use GenServer, restart: :transient

  alias PipeRacer.Snippets

  @registry PipeRacer.Race.Registry
  @supervisor PipeRacer.Race.Supervisor

  # Tabs ping every 5s, so three missed pings means the tab is gone.
  @stale_ms 15_000
  @idle_timeout :timer.minutes(30)
  @max_players 8
  # Once someone finishes, the others get this long before the race ends, so
  # one idle racer can't hold the room forever.
  @finish_window_ms 60_000

  # Client API

  def ensure_started(code) do
    case DynamicSupervisor.start_child(@supervisor, {__MODULE__, code}) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
    end
  end

  def join(code, player_id, name), do: call(code, {:join, player_id, name})

  def start_race(code), do: call(code, :start_race)

  def report(code, player_id, progress, wpm), do: call(code, {:report, player_id, progress, wpm})

  def ping(code, player_id), do: call(code, {:ping, player_id})

  def snapshot(code), do: call(code, :snapshot)

  defp call(code, message) do
    ensure_started(code)
    GenServer.call(via(code), message)
  end

  def start_link(code), do: GenServer.start_link(__MODULE__, code, name: via(code))

  defp via(code), do: {:via, Registry, {@registry, code}}

  # Server

  @impl true
  def init(code) do
    state = %{
      code: code,
      status: :lobby,
      snippet_index: nil,
      race_id: 0,
      players: %{},
      finish_order: []
    }

    {:ok, state, @idle_timeout}
  end

  @impl true
  def handle_call({:join, player_id, name}, _from, state) do
    state = prune(state)

    cond do
      # A racer who reloads mid-race lost their progress in the browser, so
      # they sit the rest of it out instead of holding up the finish.
      Map.has_key?(state.players, player_id) ->
        state =
          case state.players[player_id] do
            %{racing: true, place: nil} when state.status == :racing ->
              state |> put_in([:players, player_id, :racing], false) |> maybe_end_race()

            _player ->
              state
          end

        reply(state, {:ok, public(state)})

      map_size(state.players) >= @max_players ->
        reply(state, {:error, :full})

      true ->
        player = %{
          id: player_id,
          name: unique_name(state, name),
          progress: 0,
          wpm: 0,
          place: nil,
          # Someone arriving mid-race watches until the next one.
          racing: state.status != :racing,
          seen_at: now()
        }

        state = put_in(state.players[player_id], player)
        reply(state, {:ok, public(state)})
    end
  end

  def handle_call(:start_race, _from, state) do
    state = prune(state)
    snippet_index = Snippets.random_index(state.snippet_index)

    players =
      Map.new(state.players, fn {id, player} ->
        {id, %{player | progress: 0, wpm: 0, place: nil, racing: true}}
      end)

    state = %{
      state
      | status: :racing,
        snippet_index: snippet_index,
        race_id: state.race_id + 1,
        players: players,
        finish_order: []
    }

    reply(state, {:ok, public(state)})
  end

  def handle_call({:report, player_id, progress, wpm}, _from, state) do
    case state.players do
      %{^player_id => %{racing: true, place: nil} = player} ->
        player = %{player | progress: progress, wpm: wpm, seen_at: now()}
        state = put_in(state.players[player_id], player)
        state = if progress >= 100, do: finish(state, player_id), else: state
        reply(state, {:ok, public(state)})

      _ ->
        reply(state, {:ok, public(state)})
    end
  end

  def handle_call({:ping, player_id}, _from, state) do
    state =
      if Map.has_key?(state.players, player_id) do
        put_in(state.players[player_id].seen_at, now())
      else
        state
      end

    before = public(state)
    state = prune(state)
    after_prune = public(state)
    reply(state, {:ok, after_prune, after_prune != before})
  end

  def handle_call(:snapshot, _from, state), do: reply(state, public(state))

  @impl true
  def handle_info(:timeout, state), do: {:stop, :normal, state}

  # The finish window ran out: whoever hasn't finished is out of this race.
  def handle_info({:end_race, race_id}, %{race_id: race_id, status: :racing} = state) do
    state = %{state | status: :finished}
    broadcast(state)
    {:noreply, state, @idle_timeout}
  end

  def handle_info({:end_race, _race_id}, state), do: {:noreply, state, @idle_timeout}

  defp reply(state, result), do: {:reply, result, state, @idle_timeout}

  # Outside a page handler, so this uses Hologram's direct API. Hologram isn't
  # running in tests, and with nobody to tell there is nothing to send.
  defp broadcast(state) do
    if Hologram.enabled?() do
      Hologram.Realtime.broadcast_action({:race, state.code}, :room_updated, room: public(state))
    end
  end

  defp finish(state, player_id) do
    finish_order = state.finish_order ++ [player_id]
    state = put_in(state.players[player_id].place, length(finish_order))
    state = %{state | finish_order: finish_order}

    if length(finish_order) == 1 do
      Process.send_after(self(), {:end_race, state.race_id}, @finish_window_ms)
    end

    maybe_end_race(state)
  end

  # The race is over once every racer still in the room has a place. Checked
  # after a finish and after racers leave, or a race whose last unfinished
  # racer closed the tab would wait forever.
  defp maybe_end_race(%{status: :racing} = state) do
    racers = state.players |> Map.values() |> Enum.filter(& &1.racing)

    if Enum.all?(racers, &(&1.place != nil)) do
      %{state | status: :finished}
    else
      state
    end
  end

  defp maybe_end_race(state), do: state

  # Two tabs of one browser share a session name; keep them apart.
  defp unique_name(state, name) do
    taken = state.players |> Map.values() |> MapSet.new(& &1.name)

    Stream.iterate(1, &(&1 + 1))
    |> Stream.map(fn
      1 -> name
      n -> "#{name}-#{n}"
    end)
    |> Enum.find(&(not MapSet.member?(taken, &1)))
  end

  defp prune(state) do
    cutoff = now() - @stale_ms
    players = state.players |> Enum.filter(fn {_id, p} -> p.seen_at >= cutoff end) |> Map.new()
    maybe_end_race(%{state | players: players})
  end

  # What clients get to see: no timestamps, players sorted for display.
  defp public(state) do
    players =
      state.players
      |> Map.values()
      |> Enum.sort_by(&{&1.place || 99, -&1.progress, &1.name})
      |> Enum.map(&Map.take(&1, [:id, :name, :progress, :wpm, :place, :racing]))

    %{
      code: state.code,
      status: state.status,
      snippet_index: state.snippet_index,
      race_id: state.race_id,
      players: players
    }
  end

  defp now, do: System.monotonic_time(:millisecond)
end
