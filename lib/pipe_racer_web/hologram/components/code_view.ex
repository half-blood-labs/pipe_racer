defmodule PipeRacerWeb.Components.CodeView do
  @moduledoc "Renders a snippet as correct / wrong / cursor / pending runs."
  use Hologram.Component

  prop :segments, :map
  prop :finished, :boolean, default: false

  def template do
    ~HOLO"""
    <pre class={if @finished do "code finished" else "code" end}><span class="ok">{@segments.ok}</span><span class="bad">{@segments.bad}</span><span class="cursor">{@segments.cursor}</span><span class="todo">{@segments.todo}</span></pre>
    """
  end
end
