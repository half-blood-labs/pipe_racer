defmodule PipeRacerWeb.Keys do
  @moduledoc """
  Turns keyboard input into typing commands, from a Hologram key_down event
  (`classify/1`) or from an edit of the typing field (`classify_input/1`).
  """

  # A zero-width space: invisible, never part of a snippet, and deletable.
  @filler "\u200B"

  # What the typing field holds between edits. Backspace needs something to
  # delete or the browser fires no input event, and holding it down can delete
  # several characters in one event.
  @blank_field String.duplicate(@filler, 8)

  # Phone keyboards swap quotes and spaces for typographic ones; the snippets
  # use plain ones.
  @smart_punctuation %{
    "\u201C" => "\"",
    "\u201D" => "\"",
    "\u201E" => "\"",
    "\u2018" => "'",
    "\u2019" => "'",
    "\u201A" => "'",
    "\u00A0" => " "
  }

  def classify(event) do
    modified? = event.meta_key or event.ctrl_key or event.alt_key

    cond do
      event.key == "Backspace" and modified? -> :backspace_to_mistake
      modified? -> :ignore
      event.key == "Escape" -> :escape
      event.key == "Enter" -> :enter
      event.key == "Backspace" -> :backspace
      String.length(event.key) == 1 -> {:char, event.key}
      true -> :ignore
    end
  end

  @doc "What the typing field holds when nothing has been typed into it."
  def blank_field, do: @blank_field

  @doc """
  Reads the typing field after an edit, when it held `blank_field/0` before,
  as a list of commands: one `:backspace` per filler character deleted, then
  the characters inserted. Both happen in one edit when a phone keyboard
  replaces a word.
  """
  def classify_input(value) do
    graphemes = String.graphemes(value)
    kept = Enum.count(graphemes, &(&1 == @filler))
    deleted = max(String.length(@blank_field) - kept, 0)

    typed =
      graphemes
      |> Enum.reject(&(&1 == @filler))
      |> Enum.map(fn char -> Map.get(@smart_punctuation, char, char) end)
      |> Enum.map(fn
        "\n" -> :enter
        char -> {:char, char}
      end)

    List.duplicate(:backspace, deleted) ++ typed
  end
end
