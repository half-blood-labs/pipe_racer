defmodule PipeRacerWeb.Components.MistakeHint do
  @moduledoc """
  Says what went wrong at the first mistake. The code box only shows the
  snippet, so without this the player can't see which key they pressed, and
  hitting the wrong-run limit looks like the game froze.

  Everything after the first mistake stays red until the player deletes back
  to it, even keys typed correctly, so the hint says how many deletes that is.
  """
  use Hologram.Component

  prop :mistake, :map, default: nil

  def template do
    ~HOLO"""
    {%if @mistake}
      <div class={if @mistake.blocked do "mistake blocked" else "mistake" end}>
        You typed <kbd>{@mistake.typed}</kbd> where <kbd>{@mistake.expected}</kbd> goes.
        <span class="fix">
          {%if @mistake.blocked}<strong>Go back to it:</strong>{%else}Go back to it:{/if}
          <kbd>Backspace</kbd> ×{@mistake.backspaces}, or <kbd>⌥ Backspace</kbd> once.
        </span>
      </div>
    {/if}
    """
  end
end
