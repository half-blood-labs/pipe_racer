defmodule PipeRacerWeb.Components.KeyCapture do
  @moduledoc """
  Listens for keys on the whole window and sends them to the page as a
  `:key` action. Space, Tab, quote, slash and Backspace keep their native
  behaviour from scrolling the page, moving focus or opening quick find.
  """
  use Hologram.Component

  def template do
    ~HOLO"""
    <window
      $key_down="key"
      $key_down.space.prevent_default="noop"
      $key_down.tab.prevent_default="noop"
      $key_down.quote.prevent_default="noop"
      $key_down.slash.prevent_default="noop"
      $key_down.backspace.prevent_default="noop"
    />
    """
  end
end
