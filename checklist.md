# Piano — Improvement Checklist

Generated from a full code review on 2026-11-20 (branch `arena/cbd5034a-piano`).
Items are ordered highest-value first. Check them off as they're fixed.

Baseline at review: tests passed 80/80, but covered only `core.lua` — `piano.lua`
(about 4,200 lines) was not parsed by CI. Current suite: 168 tests pass; both Lua files are syntax-checked with fengari.

> **Trusted sources:** Obsidian (`deividcomsono/Obsidian`) and 285190-tech are
> trusted. Remote code loading from these sources is accepted — see the
> "Accepted" section at the bottom. Pinning to a commit hash is optional
> hardening only.

## If you only do five things

- [x] Fix noteOn velocity-0 release — `piano.lua:549-556` (P0) ✅ done
- [x] Fix text-sheet replay scoping — `piano.lua:2510-2519` (P0) ✅ done
- [x] Extract + test the timeline builder and text-sheet parser into `core.lua` (P2 tests) ✅ done (`Core.buildTimeline`, `Core.buildTextSheetEvents`, 18 new tests)
- [x] Add a `SCRIPT_VERSION` constant (remote loads are from trusted sources; pinning optional) ✅ done (`piano.lua`, shown in window title)
- [x] Reconcile README with reality: history coverage, velocity sliders (P1/docs) ✅ done

## P0 — Bugs (fix first)

- [x] **noteOn with velocity 0 never releases the note** — `piano.lua:549-556`.
  In MIDI, noteOn with velocity 0 is a noteOff. The guard
  `channel ~= 10 and velocity > 0` dropped both the press and the release, so the
  note rang until the 6-second fallback timer. **Fixed:** velocity-0 noteOn now
  emits a `release` event. Verified with a synthetic MIDI file.
- [x] **Velocity sliders are no-ops** — `piano.lua:176-190`, `piano.lua:2039-2072`,
  consumer at `piano.lua:251`. `mapVelocity` only feeds the fallback hold time
  (4.56–8.4 s); `SendKeyEvent` carries no velocity, so the sliders change nothing
  for well-formed MIDI. **Fixed:** sliders renamed to "Fallback Hold …" with
  tooltips explaining they control hold length, and the README no longer claims
  "velocity mapping".
- [x] **Text-sheet replay breaks after first use** — `piano.lua:2502-2521`
  (replayFn at `:2510`). `local replayFn = function() ... replayFn ... end`
  referred to a global (nil) inside its own initializer, so
  `PlayerHudState.replayFn` became nil permanently after one replay. **Fixed:**
  `local replayFn` declared before assignment; empty sheet now notifies instead
  of silently returning.
- [x] **Legato does the opposite of its intent** — `piano.lua:261-278`
  (guard at `:266`). The `releaseChar` guard was dead code because `pressChar`
  set both fields to the same pressId; overlapping notes got shorter, not
  longer. **Fixed:** added a per-key `keyPressCount` refcount; the key is only
  released when the last overlapping press ends. Verified by simulation.
- [x] **`UploadMidiInput:SetText` throws** — `piano.lua:2400`. The `AddInput`
  return value is discarded at `:2368`, and the rest of the file uses
  `:SetValue`. **Fixed:** changed to `:SetValue(result)`.

## P1 — Risky code

- [x] **History coverage and failed-play pollution** — history recording now
  happens centrally after MIDI parsing (and for text-sheet event generation),
  for every playback with a replay handler. Invalid MIDI is not recorded; the
  README states the actual coverage.
- [x] **Verify All Links request burst** — reduced worker concurrency from six
  to two, added a 250 ms inter-request delay, and a 2 s cool-down after HTTP
  429/403 responses.
- [x] **`activeVoices` bookkeeping drift** — stale per-key entries are now
  removed on non-legato retrigger, note release, and each fallback timeout;
  voice stealing clears all stacked entries and active note tokens for a stolen
  key; `releaseHeldKeys` clears the voice list.
- [x] **Compact layout range/transposition** — compact mode now has a
  configurable starting MIDI note (36–116), stops playback before remapping,
  and maps up to 12 valid consecutive notes. README and code comments describe
  the actual control.
- [x] **61st key `m` is dropped** — full layout now maps all 61 characters,
  including `m` at MIDI note 96; README and dropdown label updated.
- [ ] **Fixed wall-clock fallback hold** — `piano.lua:30`
  (`FALLBACK_HOLD_SECONDS = 6`), `piano.lua:251`. Hold time is wall-clock based
  (4.56–8.4 s after velocity mapping) and drifts under lag; it also masks the
  velocity-0 bug above.

## P2 — Missing tests

- [ ] **Most of `piano.lua` lacks behavior tests** — CI now syntax-compiles the
  script with fengari, but Roblox/UI/input/network behavior is not executable
  in this harness. Extracted pure helpers tested in `core.lua` include
  `buildTimeline`, `buildTextSheetEvents`, `mapVelocity`, `sortMidiEvents`,
  sparse seek checkpoints, active-note/voice cleanup, and same-tick note ordering
  (168 tests pass).
- [x] **Concrete `core.lua` test gaps** — covered truncated MTrk chunks, unknown
  chunk (`"XFIH"`), format-1 multi-track files, controller/pitch/timeSig/keySig/
  sysex and F7 escaped events, VLQ boundaries, `formatArtists`
  nil/table/string/number inputs, 65-character base64 alphabets, and
  `mergeCookieStrings` with an Expires comma.
- [ ] **Remaining CI gap** — CI now uses `npm ci`, validates `songs.json`,
  syntax-checks `core.lua`/`piano.lua` on Lua 5.3 and 5.4, runs native Lua 5.3
  tests, and runs the fengari suite. Still outstanding: configure `selene` for
  Roblox globals.

## P2 — Documentation gaps

- [ ] **`songs.json` metadata** — README now identifies the five upstream
  repositories and clarifies that links do not imply redistribution rights.
  The catalog still has no per-song artist field. One URL uses uppercase `.MID`
  (`Offenbach - Can-Can` → `CAN-CAN.MID`), accepted by the case-insensitive CI
  suffix validator.
- [x] **Text-sheet format documentation** — README now documents single notes,
  chords, arpeggios, separators, BPM timing, ignored unmapped characters, and
  includes a compact example.
- [ ] **Orphan `piano-ui-preview.png`** — 1.3 MB, the largest blob in the repo,
  never referenced in the README.
- [ ] **Missing project docs and stale plan references** — no CHANGELOG,
  CONTRIBUTING, or ToS disclaimer; `SCRIPT_VERSION` is now defined and shown
  in the window title. Orphan plan references still point to a plan not in the
  repo.

## P2 — Developer experience

- [ ] **~1,500 duplicated lines across five source tabs** — Quick Picks,
  NanoMIDI, MuseScore, MidiShow, and Global each reimplement the same
  `{map, order, query, selected, suppressCallback}` state pattern; the Auto-Try
  loop is duplicated at `piano.lua:1646, 2952, 3186, 3554`. A `SongSource`
  abstraction would collapse this.
- [ ] **33 silent `pcall`s** — `piano.lua` swallows errors without capture, and
  log prefixes are inconsistent (`[Piano]`, `[Repo Auto-Load]`, `[NanoMIDI]`,
  `[QuickPicks Verify]`, `[Local MIDI]`), making failures hard to trace.
- [ ] **Hot-path string/table copies** — `piano.lua:534-536` copies the whole
  MIDI via `sub`; `core.lua:568-600` and `core.lua:529-563` build output
  byte-by-byte with `table.insert`; the next-note highlight scans forward every
  40 ms slice (`piano.lua:477-490`). No upload size cap either.
- [ ] **Unpinned Obsidian internals** — `piano.lua:2196`
  (`HistoryDropdown.Value`), `:2400` (`SetText`), `:3986`
  (`ShowPlayerHudToggle:SetValue`). Obsidian is trusted, so this is low risk,
  but it stays fragile if Obsidian changes internals.
- [ ] **Batched minor nits** — `piano.lua:2288` calls `isfolder` twice (second
  unguarded); `deriveTitleFromUrl` now strips query/fragment before extracting
  the filename (with regression tests); `normalizeMidiUrl` only escapes spaces;
  `piano.lua` HUD connections only disconnect on ScreenGui destroy; the player
  clamps `dtReal` to 0.5 s, dispatching up to 0.5 s of key events in one frame.

## Accepted — no action needed

- **Remote `loadstring` of `Library.lua` and `core.lua`** — `piano.lua:16-19`,
  `piano.lua:53-70`. Obsidian (`deividcomsono/Obsidian`) and 285190-tech are
  trusted sources, so executing code fetched from `refs/heads/main` is
  accepted. Optional hardening: pin to a commit hash for reproducibility.
