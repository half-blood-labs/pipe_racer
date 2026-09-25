defmodule PipeRacerWeb.Components.CodeView do
  @moduledoc "Renders a snippet as correct / wrong / cursor / pending runs."
  use Hologram.Component

  prop :segments, :map
  prop :finished, :boolean, default: false
  prop :blocked, :boolean, default: false

  def template do
    ~HOLO"""
    <pre class={class_name(@finished, @blocked)}><span class="ok">{@segments.ok}</span><span class="bad">{@segments.bad}</span><span class="cursor">{@segments.cursor}</span><span class="todo">{@segments.todo}</span></pre>
    """
  end

  defp class_name(true, _blocked), do: "code finished"
  defp class_name(_finished, true), do: "code blocked"
  defp class_name(_finished, _blocked), do: "code"
end
