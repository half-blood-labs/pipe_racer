defmodule PipeRacerWeb.SoloPage do
  use Hologram.Page

  alias PipeRacer.Snippets
  alias PipeRacer.Typing
  alias PipeRacerWeb.Keys
  alias PipeRacerWeb.Components.CodeView
  alias PipeRacerWeb.Components.KeyCapture
  alias PipeRacerWeb.Components.MistakeHint
  alias PipeRacerWeb.Components.Stats

  route "/"

  layout PipeRacerWeb.MainLayout, page_title: "Pipe Racer · type Elixir, fast"

  # Live stats refresh rate while a run is in progress.
  @tick_ms 250

  def init(_params, component, _server) do
    load_snippet(component, Snippets.random_index())
  end

  def template do
    ~HOLO"""
    <KeyCapture />

    <section class="arena">
      <div class="snippet-title">
        <span class="hash">#</span> {@title}
      </div>

      <Stats
        wpm={Typing.wpm(@game, @now)}
        accuracy={Typing.accuracy(@game)}
        seconds={div(Typing.elapsed_ms(@game, @now), 1000)}
        progress={Typing.progress(@game)}
      />

      <CodeView
        segments={Typing.segments(@game)}
        finished={Typing.finished?(@game)}
        blocked={Typing.blocked?(@game)}
      />
      <MistakeHint mistake={Typing.mistake(@game)} />

      {%if Typing.finished?(@game)}
        <div class="result">
          <div class="result-line">
            <strong>{Typing.wpm(@game, @now)} wpm</strong> at {Typing.accuracy(@game)}% accuracy
          </div>
          <div class="hint">Press <kbd>Enter</kbd> for the next snippet, <kbd>Esc</kbd> to retry.</div>
        </div>
      {%else}
        {%if not Typing.started?(@game)}
          <div class="hint">Start typing to start the clock. <kbd>Enter</kbd> auto-indents.</div>
        {/if}
        {%if Typing.started?(@game) and Typing.mistake(@game) == nil}
          <div class="hint">Type the code. Mistakes must be fixed with <kbd>Backspace</kbd>. <kbd>Esc</kbd> restarts.</div>
        {/if}
      {/if}

      <div class="actions">
        <button $click="restart">retry</button>
        <button $click="next">next snippet</button>
      </div>
    </section>
    """
  end

  def action(:noop, _params, component), do: component

  def action(:key, %{event: event}, component) do
    handle_key(component, Keys.classify(event))
  end

  def action(:restart, _params, component) do
    load_snippet(component, component.state.snippet_index)
  end

  def action(:next, _params, component) do
    load_snippet(component, Snippets.random_index(component.state.snippet_index))
  end

  def action(:tick, %{run: run}, component) do
    game = component.state.game

    if run == component.state.run and not Typing.finished?(game) do
      component
      |> put_state(:now, now())
      |> put_action(name: :tick, params: %{run: run}, delay: @tick_ms)
    else
      component
    end
  end

  defp handle_key(component, :escape), do: action(:restart, %{}, component)

  defp handle_key(component, :enter) do
    if Typing.finished?(component.state.game) do
      action(:next, %{}, component)
    else
      apply_input(component, &Typing.type(&1, "\n", &2))
    end
  end

  defp handle_key(component, :backspace) do
    apply_input(component, fn game, _now -> Typing.backspace(game) end)
  end

  defp handle_key(component, {:char, char}) do
    apply_input(component, &Typing.type(&1, char, &2))
  end

  defp handle_key(component, :ignore), do: component

  defp apply_input(component, fun) do
    now = now()
    before = component.state.game
    game = fun.(before, now)
    component = put_state(component, game: game, now: now)

    # The first keystroke starts the clock and the stats ticker.
    if not Typing.started?(before) and Typing.started?(game) do
      put_action(component, name: :tick, params: %{run: component.state.run}, delay: @tick_ms)
    else
      component
    end
  end

  defp load_snippet(component, index) do
    snippet = Snippets.get(index)
    run = Map.get(component.state, :run, 0) + 1

    put_state(component,
      snippet_index: index,
      title: snippet.title,
      game: Typing.new(snippet.code),
      now: 0,
      run: run
    )
  end

  defp now, do: System.monotonic_time(:millisecond)
end
