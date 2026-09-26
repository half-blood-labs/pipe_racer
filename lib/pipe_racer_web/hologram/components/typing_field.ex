defmodule PipeRacerWeb.Components.TypingField do
  @moduledoc """
  An invisible textarea laid over the code box. Phones only show a keyboard
  for a focused text field, so tapping the code focuses this one. Each edit
  reaches the page as a `:typed` action, which reads it with
  `Keys.classify_input/1` and calls `reset/0` so the next edit stands alone.

  While the field has focus, keys must not also reach `KeyCapture` on the
  window, so key_down stops here. Escape and modified Backspace never change
  the field, so those go to the page as `:key` from here.
  """
  use Hologram.Component
  use Hologram.JS

  alias PipeRacerWeb.Keys

  def template do
    ~HOLO"""
    <textarea
      id="typing-field"
      class="typing-field"
      aria-label="Type the code here"
      autocapitalize="off"
      autocomplete="off"
      autocorrect="off"
      spellcheck="false"
      $input="typed"
      $key_down.stop_propagation="noop"
      $key_down.tab.prevent_default="noop"
      $key_down.escape="key"
      $key_down.alt+backspace.prevent_default="key"
      $key_down.ctrl+backspace.prevent_default="key"
      $key_down.meta+backspace.prevent_default="key"
    >{Keys.blank_field()}</textarea>
    """
  end

  @doc "Puts the field back to blank, ready for the next edit."
  def reset do
    :document
    |> JS.call(:getElementById, ["typing-field"])
    |> JS.set(:value, Keys.blank_field())

    :ok
  end
end
