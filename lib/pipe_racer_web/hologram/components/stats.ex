defmodule PipeRacerWeb.Components.Stats do
  use Hologram.Component

  prop :wpm, :integer
  prop :accuracy, :integer
  prop :seconds, :integer
  prop :progress, :integer

  def template do
    ~HOLO"""
    <div class="stats">
      <div class="stat"><span class="value">{@wpm}</span><span class="label">wpm</span></div>
      <div class="stat"><span class="value">{@accuracy}%</span><span class="label">accuracy</span></div>
      <div class="stat"><span class="value">{@seconds}s</span><span class="label">time</span></div>
    </div>
    <div class="progress"><div class="bar" style="width: {@progress}%"></div></div>
    """
  end
end
