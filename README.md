# |> pipe_racer

A typing race where you type real Elixir code instead of prose. Race alone for
WPM, or open a room and race your friends on the same snippet.

Built with [Hologram](https://hologram.page), so the game logic is Elixir that
runs in the browser: every keystroke is handled client-side with no server
round trip, and the server only syncs the race.

## How it works

| Part | Where it runs | File |
| --- | --- | --- |
| Typing state (cursor, mistakes, WPM) | Browser, compiled to JS by Hologram | `lib/pipe_racer/typing.ex` |
| Key handling and live stats | Browser, as Hologram actions | `lib/pipe_racer_web/hologram/pages/` |
| Race rooms (players, places) | Server, one GenServer per room | `lib/pipe_racer/race/room.ex` |
| Progress sync | Hologram commands + realtime broadcasts | `lib/pipe_racer_web/hologram/pages/race_page.ex` |

The typing state stores only the cursor position and the index of the first
mistake, so each keystroke is constant time and the snippet renders as four
spans (correct, wrong, cursor, pending) rather than one per character.

## Rules

- Mistakes turn red and must be fixed with Backspace before you can go on.
- Enter auto-skips the next line's indentation, like an editor.
- In a race, progress is sent to the room every 4%, not on every key.

## Running locally

Needs Elixir 1.19, OTP 28 and Node.js 20+ (see `.tool-versions`).

```bash
mix setup
mix holo
```

Then open [localhost:4000](http://localhost:4000). `mix holo` starts Phoenix with
Hologram enabled.

```bash
mix test
```

## Deploying

`fly.toml` runs one 256 MB machine that stops when idle. Rooms live in memory,
so keep it to a single machine:

```bash
fly deploy --ha=false
```

`SECRET_KEY_BASE` must be set as a Fly secret.
