defmodule PipeRacer.TypingTest do
  use ExUnit.Case, async: true

  alias PipeRacer.Typing

  defp type_all(game, text, now \\ 0) do
    text |> String.graphemes() |> Enum.reduce(game, &Typing.type(&2, &1, now))
  end

  test "typing the whole snippet correctly finishes the game" do
    game = Typing.new("a |> b") |> type_all("a |> b", 5_000)

    assert Typing.finished?(game)
    assert game.pos == 6
    assert Typing.accuracy(game) == 100
  end

  test "a wrong character stops the correct run until it is backspaced" do
    game = Typing.new("abc") |> type_all("axc")

    assert game.first_error == 1
    assert game.pos == 3
    assert Typing.correct_chars(game) == 1
    refute Typing.finished?(game)

    game = game |> Typing.backspace() |> Typing.backspace()
    assert game.first_error == nil
    assert game.pos == 1

    game = type_all(game, "bc")
    assert Typing.finished?(game)
  end

  test "input stops after a run of wrong characters" do
    game = Typing.new(String.duplicate("a", 20)) |> type_all(String.duplicate("b", 20))

    assert game.first_error == 0
    assert game.pos == 8
  end

  test "mistake reports the key pressed and the key the snippet wanted" do
    game = Typing.new("f(x)") |> type_all("f9")

    assert Typing.mistake(game) == %{typed: "9", expected: "(", blocked: false}

    game = Typing.backspace(game)
    assert Typing.mistake(game) == nil
  end

  test "mistake names invisible keys" do
    game = Typing.new("a b\nc") |> type_all("ax")
    assert Typing.mistake(game).expected == "Space"

    game = Typing.new("ab\nc") |> type_all("ab ")
    assert Typing.mistake(game) == %{typed: "Space", expected: "Enter", blocked: false}
  end

  test "typing is blocked after the wrong run, or at the end with a mistake" do
    game = Typing.new(String.duplicate("a", 20)) |> type_all(String.duplicate("b", 8))
    assert Typing.blocked?(game)
    assert Typing.mistake(game).blocked

    game = Typing.new("ab") |> type_all("xb")
    assert game.pos == 2
    assert Typing.blocked?(game)
  end

  test "Enter skips the next line's indentation" do
    game = Typing.new("do\n  x\nend") |> type_all("do\n")

    assert game.pos == 5
    assert Typing.segments(game).todo == "\nend"

    game = type_all(game, "x\nend")
    assert Typing.finished?(game)
  end

  test "the clock starts on the first keystroke" do
    game = Typing.new("hello")
    refute Typing.started?(game)

    game = Typing.type(game, "h", 1_000)
    assert game.started_at == 1_000

    game = type_all(game, "ello", 13_000)
    assert Typing.elapsed_ms(game, 99_999) == 12_000
    # 5 characters = 1 word in 12 seconds = 5 WPM
    assert Typing.wpm(game, 99_999) == 5
  end

  test "mistakes lower accuracy" do
    game = Typing.new("ab") |> type_all("x") |> Typing.backspace() |> type_all("ab")

    assert Typing.finished?(game)
    assert game.keystrokes == 3
    assert game.mistakes == 1
    assert Typing.accuracy(game) == 67
  end

  test "segments mark correct, wrong, cursor and pending text" do
    game = Typing.new("ab\ncd") |> type_all("aX")

    assert Typing.segments(game) == %{ok: "a", bad: "b", cursor: "↵\n", todo: "cd"}
  end

  test "backspace at the start or after finishing does nothing" do
    game = Typing.new("a")
    assert Typing.backspace(game) == game

    done = type_all(game, "a")
    assert Typing.backspace(done) == done
  end
end
