defmodule PipeRacerWeb.Components.PlayerList do
  use Hologram.Component

  prop :players, :list
  prop :me, :string

  def template do
    ~HOLO"""
    <ul class="players">
      {%for player <- @players}
        <li class={if player.id == @me do "player me" else "player" end}>
          <span class="place">{place_label(player)}</span>
          <span class="name">{player.name}{if player.id == @me do " (you)" else "" end}</span>
          <span class="track"><span class="car" style="width: {player.progress}%"></span></span>
          <span class="wpm">{player.wpm} wpm</span>
        </li>
      {/for}
    </ul>
    """
  end

  defp place_label(%{place: 1}), do: "1st"
  defp place_label(%{place: 2}), do: "2nd"
  defp place_label(%{place: 3}), do: "3rd"
  defp place_label(%{place: nil, racing: false}), do: "watch"
  defp place_label(%{place: nil}), do: ""
  defp place_label(%{place: n}), do: "#{n}th"
end
