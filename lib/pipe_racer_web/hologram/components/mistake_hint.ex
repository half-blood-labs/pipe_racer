defmodule PipeRacerWeb.Components.MistakeHint do
  @moduledoc """
  Says what went wrong at the first mistake. The code box only shows the
  snippet, so without this the player can't see which key they pressed, and
  hitting the wrong-run limit looks like the game froze.
  """
  use Hologram.Component

  prop :mistake, :map, default: nil

  def template do
    ~HOLO"""
    {%if @mistake}
      <div class={if @mistake.blocked do "mistake blocked" else "mistake" end}>
        You typed <kbd>{@mistake.typed}</kbd> where <kbd>{@mistake.expected}</kbd> goes.
        {%if @mistake.blocked}
          <strong>Press Backspace to fix it and keep going.</strong>
        {%else}
          Backspace to fix it.
        {/if}
      </div>
    {/if}
    """
  end
end
