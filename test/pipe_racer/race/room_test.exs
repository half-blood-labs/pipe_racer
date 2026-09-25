defmodule PipeRacer.Race.RoomTest do
  use ExUnit.Case, async: true

  alias PipeRacer.Race
  alias PipeRacer.Race.Room

  setup do
    %{code: Race.new_code()}
  end

  test "players join a lobby and race once it starts", %{code: code} do
    {:ok, room} = Room.join(code, "tab-a", "swift-atom")
    assert room.status == :lobby
    assert [%{name: "swift-atom", racing: true}] = room.players

    {:ok, _} = Room.join(code, "tab-b", "lazy-pipe")
    {:ok, room} = Room.start_race(code)

    assert room.status == :racing
    assert room.race_id == 1
    assert is_integer(room.snippet_index)
    assert length(room.players) == 2
  end

  test "joining twice from the same tab does not duplicate the player", %{code: code} do
    {:ok, _} = Room.join(code, "tab-a", "swift-atom")
    {:ok, room} = Room.join(code, "tab-a", "swift-atom")

    assert length(room.players) == 1
  end

  test "finishers get places and the race ends when everyone is done", %{code: code} do
    {:ok, _} = Room.join(code, "tab-a", "a")
    {:ok, _} = Room.join(code, "tab-b", "b")
    {:ok, _} = Room.start_race(code)

    {:ok, room} = Room.report(code, "tab-b", 100, 80)
    assert room.status == :racing
    assert [%{name: "b", place: 1}, %{name: "a", place: nil}] = room.players

    {:ok, room} = Room.report(code, "tab-a", 100, 60)
    assert room.status == :finished
    assert Enum.map(room.players, & &1.place) == [1, 2]
  end

  test "someone who joins mid-race watches until the next one", %{code: code} do
    {:ok, _} = Room.join(code, "tab-a", "a")
    {:ok, _} = Room.start_race(code)
    {:ok, room} = Room.join(code, "tab-late", "late")

    assert %{racing: false} = Enum.find(room.players, &(&1.name == "late"))

    {:ok, room} = Room.report(code, "tab-late", 50, 40)
    assert %{progress: 0} = Enum.find(room.players, &(&1.name == "late"))
  end

  test "two tabs with the same session name get distinct names", %{code: code} do
    {:ok, _} = Room.join(code, "tab-a", "swift-atom")
    {:ok, room} = Room.join(code, "tab-b", "swift-atom")

    assert room.players |> Enum.map(& &1.name) |> Enum.sort() == ["swift-atom", "swift-atom-2"]
  end

  test "a room is full at eight players", %{code: code} do
    for i <- 1..8, do: {:ok, _} = Room.join(code, "tab-#{i}", "p#{i}")

    assert Room.join(code, "tab-9", "p9") == {:error, :full}
  end

  test "room codes are five lowercase letters or digits" do
    code = Race.new_code()

    assert Race.valid_code?(code)
    refute Race.valid_code?("ABCDE")
    refute Race.valid_code?("abc")
  end
end
