# 🎹 Universal Piano

A Roblox Lua piano player that plays MIDI files through a virtual keyboard, with
quick-pick songs, local files, text sheets, and scrapers for MuseScore and
MidiShow. The UI is built with the
[Obsidian](https://github.com/deividcomsono/Obsidian) library (a LinoriaLib-style
Lua UI framework), and all Roblox-independent logic lives in a separate,
unit-tested `core.lua` module.

## Features

- **Virtual keyboard** — 61 keys (MIDI notes 36–96) mapped to your
  keyboard/mouse (`1!2@34$5%6^78*9(0` row plus `qQwWeErtTyYuiIoOpPa...`),
  with MIDI note-on/note-off, legato mode, and voice stealing (16-voice
  ceiling) so fast passages stay clean. The virtual keyboard can't send
  velocity, so the velocity sliders control the fallback hold length (how long
  a note rings if a file has no note-off).
- **Keyboard layouts** — toggle between the full 61-key layout and a compact
  12-key layout. In compact mode, adjust the starting MIDI note (36–116) to
  transpose its range.
- **Quick Picks & URL** — browse the built-in `songs.json` list (172 songs),
  paste any `.mid` URL, or merge a custom `Name | URL` list as a third source.
  The dropdown is searchable. Save favorites locally when the executor supports
  `readfile` and `writefile` (otherwise for the session only), or use
  **Shuffle** to play a random match from the current search, or shuffle
  favorites. Sort Quick Picks alphabetically, step through matching songs,
  and remove or clear favorites.
  URL-based global results and direct URLs can also be favorited. Favorites
  store links, not MIDI files, in `universal_piano_favorites.json`. Save the
  current favorites as a named playlist in `universal_piano_playlists.json`,
  then add that playlist to the playback queue. Without filesystem support,
  favorites and playlists last only for the current session.
- **Playback History** — every played song is recorded (title + source) with
  replay from a selectable list; history updates when playback starts, is
  capped at 25 entries, and stores replay closures rather than MIDI payloads.
  Replay the latest entry or remove individual entries. Upload and text-sheet
  replays use the current input, not an archived copy.

- **Local & Sheets** — load MIDI files from your Roblox inventory, upload a
  `.mid` via the executor's `InsertString` (or paste base64), or paste
  text-based sheet notation (see below). The local scanner also checks
  `UniversalPiano/midis` and `UniversalPiano/sheets`; refresh after adding files.
  MIDI-to-sheet export uses the selected sheet BPM and is lossy: note durations,
  velocity, sustain, and tempo changes are not represented.
- **NanoMIDI API** — direct playback from NanoMIDI-style API endpoints.
- **MuseScore & MidiShow** — paste a score/MIDI page URL and the script
  resolves the underlying MIDI file (reverse-engineered; see Caveats).
- **Global Search** — one search box across all sources, with token matching.
  Queue selected Quick Picks, search results, or a direct URL; reorder/remove
  entries and enable autoplay with a configurable delay. A stop or a newly
  started song cancels a pending autoplay. A failed queued load requires manual
  intervention; it does not silently skip to the next entry.
- **Chat requests** — opt-in and local-player-only by default. `!play <name>`
  plays the first Quick Pick match and `!request <name>` queues it. An optional
  numeric user-ID whitelist permits other players; requests have a five-second
  per-user cooldown. The local player is the executor user, not necessarily the
  server owner. Chat APIs and availability vary by Roblox experience.
- **On-screen HUD** — title, progress, seek, pause/resume, replay, speed, and
  a next-note highlight badge (flashes the upcoming key(s) during playback).
  Playback Controls also offer whole-song looping, A–B practice repeat (A and B
  are available on the HUD), restart, ten-second jumps and percentage seeking,
  including while paused. Looping and restart reuse the
  current timeline without re-downloading it. Optional practice mode waits for
  each physical keyboard note or chord; an optional falling-note preview appears
  above the HUD. Practice requires keyboard input and the HUD to see its prompt.
- **MIDI controls** — sustain pedal CC64, semitone transpose, octave shift and
  optional octave folding for notes outside the selected keyboard layout. Mute
  individual channels (drums are muted by default), mute a selected track, or
  solo a track using its MIDI track and instrument names. Select the melody or
  accompaniment track yourself; there is no automatic classification. Optional
  timing jitter and chord roll are applied when a MIDI is loaded or replayed.
- **Network tuning** — adjust max retry attempts and retry delay for song
  fetches. Public MIDI requests without custom headers use a bounded 16-entry,
  8 MB session cache; authenticated requests are never cached.
- **Single shared playback engine** — one event timeline drives the keyboard,
  HUD, and seek; tempo changes and SMPTE division are honored.

## Song catalog provenance

[`songs.json`](songs.json) is a list of external MIDI links, not MIDI files. At
this revision, its 172 entries point to `thewildwestmidis/midis`,
`KiyoEditz/Maestro`, `reality3d/3d-piano-player`, `callmeyyzx/midi`, and
`MAraragi/MusicalScoreRecognition` on GitHub. The URLs identify the linked
repositories; no license or redistribution permission is implied. Check the
upstream repository and the individual file's terms before redistributing any
linked MIDI.

## Text-sheet notation

Text sheets use characters from the selected keyboard layout. A single valid
character plays one note; `[ab]` plays `a` and `b` together as a chord, while
`[a b c]` plays those notes as a short arpeggio. Spaces, hyphens, pipes, and
newlines each add one beat of rest. Other unmapped characters are ignored.
The tempo field is in beats per minute; each ordinary note or separator
advances half a beat. For example:

```text
[tu] y [ro] | a [sd]
```

## Installation

This is an executor-oriented script, not a normal Roblox Studio `Script` or
`ModuleScript`: it requires access to `loadstring`, HTTP requests and virtual
keyboard input in its execution environment. Run [`piano.lua`](piano.lua) in a
compatible environment. Executor APIs vary, so optional filesystem, clipboard,
and upload features may be unavailable.

The script loads `Library.lua` from [Obsidian](https://github.com/deividcomsono/Obsidian)
and `core.lua` from `q-29/piano`'s main branch at runtime. Loading failures are
reported through warnings/errors. When testing unmerged changes, make sure the
remote `core.lua` matches the version of `piano.lua` being run.

## Files

| File | Purpose |
| --- | --- |
| `piano.lua` | Main script: UI, input, playback engine, network fetching. |
| `core.lua` | Pure Lua 5.3 logic (MIDI parser, MD5, decoders, URL/HTML/search helpers). No Roblox dependencies — unit-testable. |
| `songs.json` | Canonical quick-pick list (172 entries, `{"name", "url"}`). |
| `tests/run_tests.lua` | Unit test suite for the Roblox-independent core helpers. |
| `tests/run_tests.js` | Fengari harness; also syntax-checks `piano.lua` without executing Roblox-dependent code. |
| `tests/run_playback_tests.js`, `tests/run_practice_tests.js`, `tests/run_queue_tests.js` | Mocked tests for playback controls, practice input, and queue automation. |
| `tests/run_chat_tests.js`, `tests/run_verify_tests.js` | Mocked chat authorization and link-verification tests. |
| `tests/run_voice_tests.js`, `tests/run_player_state_tests.js` | Mocked voice lifetime and player-state tests. |
| `tests/validate_songs.js` | Validates `songs.json` shape, URL suffixes, and duplicates. |

## Testing

`core.lua` is deliberately Roblox-free so it can be tested anywhere. The suite
covers MIDI parsing and edge cases (including F7 escaped events), timeline and
text-sheet event generation, velocity mapping, event ordering, sparse seek-state
restoration with bounded seek-index snapshots, active-note and voice cleanup,
sustain, track metadata, humanization,
practice chords, playlist validation, cache behavior, MD5/base64/hex helpers, HTML/URL
handling, search/filtering, quick-pick parsing, cookie merging, and duration/
artist formatting. The CI workflow also syntax-checks both Lua files on Lua 5.3/5.4,
runs the native Lua 5.3 suite, checks `piano.lua` with fengari, and validates
the song catalog.

**With a Lua 5.3+ interpreter:**

```sh
lua tests/run_tests.lua
```

**Without one (uses fengari via Node):**

```sh
cd tests
npm ci
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
