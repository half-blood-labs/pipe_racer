defmodule PipeRacerWeb.Components.PlayerList do
  use Hologram.Component

  prop :players, :list
  prop :me, :string
  # "watch" only means something while a race is on.
  prop :race_on, :boolean, default: false

  def template do
    ~HOLO"""
    <ul class="players">
      {%for player <- @players}
        <li class={if player.id == @me do "player me" else "player" end}>
          <span class="place">{place_label(player, @race_on)}</span>
          <span class="name">{player.name}{if player.id == @me do " (you)" else "" end}</span>
          <span class="track"><span class="car" style="width: {player.progress}%"></span></span>
          <span class="wpm">{player.wpm} wpm</span>
        </li>
      {/for}
    </ul>
    """
  end

  defp place_label(%{place: 1}, _race_on), do: "1st"
  defp place_label(%{place: 2}, _race_on), do: "2nd"
  defp place_label(%{place: 3}, _race_on), do: "3rd"
  defp place_label(%{place: nil, racing: false}, true), do: "watch"
  defp place_label(%{place: nil}, _race_on), do: ""
  defp place_label(%{place: n}, _race_on), do: "#{n}th"
end
