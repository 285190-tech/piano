# 🎹 Universal Piano

A Roblox Lua piano player that plays MIDI files through a virtual keyboard, with
quick-pick songs, local files, text sheets, and scrapers for MuseScore and
MidiShow. The UI is built with the
[Obsidian](https://github.com/deividcomsono/Obsidian) library (a LinoriaLib-style
Lua UI framework), and all Roblox-independent logic lives in a separate,
unit-tested `core.lua` module.

## Features

- **Virtual keyboard** — 60 keys (MIDI notes 36–95) mapped to your
  keyboard/mouse (`1!2@34$5%6^78*9(0` row plus `qQwWeErtTyYuiIoOpPa...`),
  with MIDI note-on/note-off, velocity mapping, a velocity-scaled fallback
  hold, legato mode, and voice stealing (16-voice ceiling) so fast passages
  stay clean.
- **Keyboard layouts** — toggle between the full 60-key layout and a compact
  12-key octave layout.
- **Quick Picks & URL** — browse the built-in `songs.json` list (172 songs),
  paste any `.mid` URL, or merge a custom `Name | URL` list as a third source.
  The dropdown is searchable.
- **Playback History** — every played song is recorded (title + source) with
  one-click replay; history is capped and stores only small replay closures,
  never the MIDI payload.
- **Local & Sheets** — load MIDI files from your Roblox inventory, upload a
  `.mid` via the executor's `InsertString` (or paste base64), or paste
  text-based sheet notation (chords `[ab]`, arpeggios `[a b c]`, one beat per
  space/`-`/`|`/newline, tempo in BPM).
- **NanoMIDI API** — direct playback from NanoMIDI-style API endpoints.
- **MuseScore & MidiShow** — paste a score/MIDI page URL and the script
  resolves the underlying MIDI file (reverse-engineered; see Caveats).
- **Global Search** — one search box across all sources, with token matching.
- **On-screen HUD** — title, progress, seek, pause/resume, replay, speed, and
  a next-note highlight badge (flashes the upcoming key(s) during playback).
- **Network tuning** — adjust max retry attempts and retry delay for all
  song fetches.
- **Single shared playback engine** — one event timeline drives the keyboard,
  HUD, and seek; tempo changes and SMPTE division are honored.

## Installation

1. Copy the contents of [`piano.lua`](piano.lua) into a **Script** inside a
   `ScreenGui` in your Roblox place (or use a ModuleScript and run it from a
   Script).
2. Run it. The script loads two remote files at runtime, both guarded with
   `pcall`:
   - `Library.lua` from the [Obsidian](https://github.com/deividcomsono/Obsidian)
     repository
   - `core.lua` from this repository
3. If either load fails (e.g. no internet in the sandbox), the script reports
   the error in-chat instead of crashing silently.

> **Roblox executors:** the script uses `loadstring`, so it requires an
> executor with `loadstring` support (Synapse X, KRNL, Electron, etc.) and
> `HttpService` access to `raw.githubusercontent.com` and `musescore.com` /
> `midishow.com`.

## Files

| File | Purpose |
| --- | --- |
| `piano.lua` | Main script: UI, input, playback engine, network fetching. |
| `core.lua` | Pure Lua 5.3 logic (MIDI parser, MD5, decoders, URL/HTML/search helpers). No Roblox dependencies — unit-testable. |
| `songs.json` | Canonical quick-pick list (172 entries, `{"name", "url"}`). |
| `tests/run_tests.lua` | Unit test suite for `core.lua`. |
| `tests/run_tests.js` | Fengari (Lua 5.3 in JavaScript) harness so tests run without a Lua install. |

## Testing

`core.lua` is deliberately Roblox-free so it can be tested anywhere. The suite
covers VLQ reading, MIDI event parsing (notes, tempo, running status,
`0xF1`/`0xF7` stream integrity), MD5, custom-base64/hex decoding, HTML/URL
helpers, search/filtering, quick-pick parsing, cookie merging, and duration
formatting.

**With a Lua 5.3+ interpreter:**

```sh
lua tests/run_tests.lua
```

**Without one (uses fengari via Node):**

```sh
cd tests
npm install
npm test
```

## Caveats

- **MuseScore / MidiShow scraping is reverse-engineered.** Neither site offers
  a public MIDI API, so the fetchers extract MIDI URLs from their JS bundles
  and decode MidiShow's custom base64 payload. These sites change their
  internals without notice; if a fetch breaks, expect to adjust the offsets in
  `piano.lua`.
- **`loadstring` is required** — this is a Roblox executor script, not a
  standard Lua module.
- **Quick picks depend on network access** to `raw.githubusercontent.com`.

## License

[MIT](LICENSE)
