defmodule PipeRacerWeb.MainLayout do
  use Hologram.Component

  alias Hologram.UI.Link
  alias Hologram.UI.Runtime

  prop :page_title, :string, default: "Pipe Racer"

  def template do
    ~HOLO"""
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <title>{@page_title}</title>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
        <link
          rel="stylesheet"
          href="https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;600;800&display=swap"
        />
        <link rel="stylesheet" href="/assets/css/app.css" />
        <Runtime />
      </head>
      <body>
        <header class="topbar">
          <Link to={PipeRacerWeb.SoloPage} class="brand"><span class="pipe">|&gt;</span> pipe_racer</Link>
          <nav>
            <Link to={PipeRacerWeb.SoloPage}>solo</Link>
          </nav>
        </header>
        <main>
          <slot />
        </main>
        <footer class="footer">
          Pure Elixir in the browser, built with <a href="https://hologram.page">Hologram</a>.
        </footer>
      </body>
    </html>
    """
  end
end
