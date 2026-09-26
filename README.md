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
mistake, not what was typed, and the snippet renders as four spans (correct,
wrong, cursor, pending) rather than one per character.

## Rules

- Mistakes turn red and must be fixed with Backspace before you can go on.
  Everything after the first mistake stays red until you delete back to it;
  Option (or Ctrl/Cmd) + Backspace jumps there in one press.
- Enter auto-skips the next line's indentation, like an editor.
- In a race, progress is sent to the room every 4%, not on every key.
- On a phone, tap the code to bring up the keyboard. Autocorrect is off, and
  curly quotes from the keyboard count as plain ones.

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

`render.yaml` is a Render Blueprint for the free plan (512 MB, Frankfurt).
In the Render dashboard choose New, then Blueprint, and pick this repo. Render
asks for `SECRET_KEY_BASE` once; generate one with:

```bash
mix phx.gen.secret
```

Every push to `master` redeploys. The free plan sleeps after 15 minutes
without traffic and takes about a minute to wake. Race rooms live in memory,
so they reset when it sleeps, and it must stay a single instance.
