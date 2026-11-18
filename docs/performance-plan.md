# Performance mode: plan and review

## Plan

1. Put a **Stage** tab first: show what's playing, what's queued, and whether the next song is ready. Keep the existing playback, pitch, and practice controls in their own tab.
2. Queue existing sources (Quick Picks, direct MIDI URLs, local MIDI, text sheets, and NanoMIDI). Preload and validate the first entry on demand. Never start a song just because a download finishes; **Play Next** is the cue. A bad link stays in the queue until retried or removed.
3. Add a one-shot **Soundcheck** that uses the same input path as songs: ordinary and shifted notes, a chord, and a held note. Leave a lead-in so the performer can return focus to the piano. Provide a Stage stop button.
4. Test load cancellation, queue edits, bad files, changing playback settings after preloading, and note release with mocked services. Reserve claims about actual game support for a live test.

## Design review

- Reuse the existing MIDI/text timeline builders and transport. Maintain only one staged entry in memory; keep the rest as references to their source. Snapshot options for a load; reparse cached data if the settings change before the cue.
- Staging must not send keys. Stopping must silence the current transport, including a pending Play Next, without silently deleting the remaining setlist. If a queued entry is skipped or removed during a load, that load must not start later.
- No game-specific remote adapters, background auto-play, third-party loaders, bundled song downloads, or live-game compatibility promises in this change. Rayfield is still the existing UI dependency. The queue is session-only.

## Likely useful, not verified across games

| Piano setup | Expected usefulness |
| --- | --- |
| Standard desktop virtual-piano keyboard mapping; accepts synthetic key down/up | Best fit. Test ordinary keys and shifted notes, then compare the held note to the short notes. |
| Keyboard piano with a different mapping, or tap-only audio | Some keys can be wrong; octave fitting doesn't remap controls. Tap-only pianos won't gain sustain from hold mode. |
| Touch/click-only keys, rhythm tiles, or runtimes without virtual keyboard input | Not supported by this input path. |

There is no live Roblox client in the development environment, so none of these rows establishes how many experiences work. Use the soundcheck after focusing the piano in an experience that permits automation. If it fails, changing MIDI settings will not fix a mismatched input layout.

## Public script comparison (read-only)

- rScripts' [Visual Pianos listing](https://rscripts.net/script/universal-piano-auto-play-UFBZ) advertises a large organized catalog, but the visible script is a remote loader; its target repository has no visible license. A broad catalog is useful, but it doesn't establish mapping compatibility or the right to redistribute MIDI arrangements.
- [Piano AUTOPLAYER no KEY](https://rscripts.net/script/piano-autoplayer-no-key-vl7e) and the [Starving Pianists listing](https://rscripts.net/script/auto-piano-keyless-57YX) are wrappers for the same [TALENTLESS project](https://github.com/hellohellohell012321/TALENTLESS). Its available source is explicitly study-only under its license; it isn't open source. Two listings for the same loader are not independent compatibility evidence.
- As a genuinely open-source comparison outside rScripts, [saphey's GPLv3 MIDI autoplayer](https://github.com/saphey/roblox-piano-midi-autoplayer) documents a QWERTY dependency. It reinforces the need to make keyboard-layout assumptions explicit, not to promise universal support.

No code from those projects was copied or run.

## Follow-up source review

- [TALENTLESS `MAIN.lua`](https://github.com/hellohellohell012321/TALENTLESS/blob/main/MAIN.lua) contains playlist reorder, shuffle, and favorites backed by local files. Reuse wasn't permitted by its license. This fork independently implements named, data-only saved setlists and shuffle. Unlike the reviewed playlist player, shuffling here only changes the queue; playback still requires a cue.
- The Visual Pianos loader's `LunarZR/QOUTES` payload is roughly 1.2 MB of obfuscated Lua. It was inspected as text but not executed or added as a dependency. It isn't a source base we can usefully audit.
- [The GPLv3 desktop player](https://github.com/saphey/roblox-piano-midi-autoplayer) uses note-on/off to hold keys and centers pitch by octave. This fork already supports those features and also handles overlapping voices, explicit stop, and MIDI pedal data. There was no reason to replace that implementation with the desktop one.

Saved sets are an explicit local backup of the session queue. Loading one neither fetches a song nor starts playback. No external code was copied or run.

### Static audit of the Visual Pianos payload

A read-only pass reversed the decimal escapes, string-table reordering, and custom base64 alphabet without executing the Lua. The decoded table contains `SendKeyEvent`, `HttpGet`, and `loadstring`. Those names are evidence that the payload references input and loading APIs, not proof of how or when it uses them. The readable string table did not expose a feature worth porting. Reconstructing the remaining control flow would be a separate audit; the payload is not treated as safe, open source, or a dependency.

### Compatibility follow-up: user-supplied keyboard layouts

Keyboard Setup can now map MIDI pitches to the actual keys used by an experience and save that layout locally per experience. Soundcheck uses the active layout, and pitch fitting respects absent notes. This improves support for alternate keyboard pianos, but it does not detect layouts automatically, make blocked virtual input work, or add touch-only support. MIDI preflight now lists channels so a performer can isolate a melody rather than play every part of a dense arrangement.
