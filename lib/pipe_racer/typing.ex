defmodule PipeRacer.Typing do
  @moduledoc """
  Pure typing-game state. Runs in the browser (Hologram compiles it to
  JavaScript) so every keystroke is handled without a server round trip.

  The game never stores what the player typed, only how far they got:

    * `pos` - cursor position in the snippet
    * `first_error` - index of the first wrong character, or `nil`

  Everything before `first_error` is correct; everything from `first_error`
  up to `pos` is wrong and has to be backspaced away, TypeRacer style.
  """

  # How far past a mistake the player may keep typing before input stops.
  @max_wrong_run 5

  def new(code) do
    chars = String.graphemes(code)

    %{
      chars: chars,
      len: length(chars),
      pos: 0,
      first_error: nil,
      wrong_char: nil,
      keystrokes: 0,
      mistakes: 0,
      started_at: nil,
      finished_at: nil
    }
  end

  def finished?(game), do: game.finished_at != nil

  def started?(game), do: game.started_at != nil

  def type(game, char, now) do
    if finished?(game) or blocked?(game), do: game, else: do_type(game, char, now)
  end

  @doc "True when typing is paused until the player backspaces to the mistake."
  def blocked?(game) do
    game.first_error != nil and
      (game.pos >= game.len or game.pos - game.first_error >= @max_wrong_run)
  end

  @doc """
  What went wrong, for showing the player: the key they pressed and the one
  the snippet wanted at their first mistake. `nil` when there is no mistake.
  """
  def mistake(%{first_error: nil}), do: nil

  def mistake(game) do
    %{
      typed: key_name(game.wrong_char),
      expected: key_name(Enum.at(game.chars, game.first_error)),
      blocked: blocked?(game),
      backspaces: game.pos - game.first_error
    }
  end

  defp key_name(" "), do: "Space"
  defp key_name("\n"), do: "Enter"
  defp key_name(char), do: char

  defp do_type(game, char, now) do
    expected = Enum.at(game.chars, game.pos)
    correct? = char == expected

    game = %{
      game
      | started_at: game.started_at || now,
        keystrokes: game.keystrokes + 1,
        mistakes: if(correct?, do: game.mistakes, else: game.mistakes + 1)
    }

    cond do
      game.first_error == nil and correct? ->
        %{game | pos: game.pos + 1}
        |> skip_indentation(char)
        |> maybe_finish(now)

      game.first_error == nil ->
        %{game | pos: game.pos + 1, first_error: game.pos, wrong_char: char}

      true ->
        %{game | pos: game.pos + 1}
    end
  end

  # After a correct Enter, jump over the next line's leading spaces the way
  # an editor would, so players race on code rather than on indentation.
  defp skip_indentation(game, "\n") do
    indent =
      game.chars
      |> Enum.drop(game.pos)
      |> Enum.take_while(&(&1 == " "))
      |> length()

    %{game | pos: game.pos + indent}
  end

  defp skip_indentation(game, _char), do: game

  defp maybe_finish(game, now) do
    if game.pos == game.len and game.first_error == nil do
      %{game | finished_at: now}
    else
      game
    end
  end

  def backspace(game) do
    cond do
      finished?(game) ->
        game

      game.pos == 0 ->
        game

      true ->
        pos = game.pos - 1

        if game.first_error != nil and pos <= game.first_error do
          %{game | pos: pos, first_error: nil, wrong_char: nil}
        else
          %{game | pos: pos}
        end
    end
  end

  @doc "Deletes back to the first mistake in one go (Option/Ctrl+Backspace)."
  def backspace_to_mistake(%{first_error: nil} = game), do: backspace(game)

  def backspace_to_mistake(game) do
    if finished?(game) do
      game
    else
      %{game | pos: game.first_error, first_error: nil, wrong_char: nil}
    end
  end

  def correct_chars(game), do: game.first_error || game.pos

  def elapsed_ms(game, now) do
    cond do
      game.started_at == nil -> 0
      game.finished_at != nil -> game.finished_at - game.started_at
      true -> max(now - game.started_at, 0)
    end
  end

  @doc "Words per minute, where a word is five characters (the usual convention)."
  def wpm(game, now) do
    ms = elapsed_ms(game, now)

    if ms < 1_000 do
      0
    else
      round(correct_chars(game) / 5 / (ms / 60_000))
    end
  end

  def accuracy(game) do
    if game.keystrokes == 0 do
      100
    else
      round((game.keystrokes - game.mistakes) * 100 / game.keystrokes)
    end
  end

  def progress(game), do: div(correct_chars(game) * 100, max(game.len, 1))

  @doc """
  The snippet split into four runs for rendering: typed correctly, typed
  wrong, the character under the cursor, and not yet typed. Rendering four
  spans instead of one per character keeps each keystroke's re-render tiny.
  """
  def segments(game) do
    ok_until = correct_chars(game)
    {ok, rest} = Enum.split(game.chars, ok_until)
    {bad, rest} = Enum.split(rest, game.pos - ok_until)
    {cursor, todo} = if finished?(game), do: {[], rest}, else: Enum.split(rest, 1)

    %{
      ok: Enum.join(ok),
      bad: show_newlines(bad),
      cursor: show_newlines(cursor),
      todo: Enum.join(todo)
    }
  end

  # A newline is invisible, so mark it when the player needs to see it.
  defp show_newlines(chars) do
    Enum.map_join(chars, fn
      "\n" -> "↵\n"
      char -> char
    end)
  end
end
