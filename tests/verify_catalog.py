#!/usr/bin/env python3
"""Verify pinned GitHub MIDI blobs and playability with the script's Luau parser."""

import json
import os
import re
import subprocess
import tempfile
from pathlib import Path
from urllib.parse import quote, unquote, urlsplit

ROOT = Path(__file__).resolve().parents[1]
NAME = r'[A-Za-z0-9_.-]+'
URL_PATH = re.compile(rf'/({NAME})/({NAME})/([a-f0-9]{{40}})/(.+)', re.ASCII)
LUA_STRING = r'"(?:[^"\\]|\\.)*"'
FALLBACK_ROW = re.compile(rf'\s*{{name = ({LUA_STRING}), url = ({LUA_STRING}), category = ({LUA_STRING})}},')


def decode_url(url):
    parts = urlsplit(url)
    match = URL_PATH.fullmatch(parts.path)
    if parts.scheme != 'https' or parts.netloc != 'raw.githubusercontent.com' or not match or parts.query or parts.fragment:
        raise ValueError(f'Expected a commit-pinned raw GitHub URL: {url}')
    owner, repo, revision, encoded_path = match.groups()
    path = unquote(encoded_path, errors='strict')
    if (quote(path) != encoded_path or any(part in ('', '.', '..') for part in path.split('/'))
            or not path.lower().endswith(('.mid', '.midi'))):
        raise ValueError(f'Invalid or noncanonical MIDI path: {url}')
    return owner, repo, revision, path


def main():
    script = (ROOT / 'piano.lua').read_text(encoding='utf-8')
    songs = json.loads((ROOT / 'songs.json').read_text(encoding='utf-8'))
    fallback = script.split('local DEFAULT_QUICKPICKS = {\n', 1)[1].split('\n}', 1)[0]
    parsed_fallback = []
    for line in fallback.splitlines():
        name, url, category = FALLBACK_ROW.fullmatch(line).groups()
        parsed_fallback.append({'name': json.loads(name), 'url': json.loads(url), 'category': json.loads(category)})
    if songs != parsed_fallback:
        raise ValueError('songs.json and the built-in fallback differ')
    if len({song['url'] for song in songs}) != len(songs) or len({song['name'].casefold() for song in songs}) != len(songs):
        raise ValueError('Duplicate song name or URL')

    with tempfile.TemporaryDirectory(prefix='piano-catalog-') as directory:
        scratch = Path(directory)
        repos = {}
        harness = scratch / 'catalog.luau'
        with harness.open('w', encoding='utf-8') as test:
            test.write((ROOT / 'tests/mocks.luau').read_text(encoding='utf-8') + '\n' + script)
            test.write('''
local failures = 0
local function verifySong(name, data)
    local ok, events, duration = pcall(buildMidiTimeline, data, midiSettings, holdPlaybackKeys)
    if not ok or #events == 0 or duration ~= duration or duration == math.huge then
        failures += 1
        print("FAIL: " .. name .. " — " .. (ok and "not playable" or tostring(events)))
    end
end
''')
            for song in songs:
                owner, repo, revision, path = decode_url(song['url'])
                key = (owner, repo, revision)
                if key not in repos:
                    target = scratch / f'git-{len(repos)}'
                    subprocess.run(['git', 'init', '--quiet', target], check=True)
                    subprocess.run(['git', '-C', target, 'fetch', '--quiet', '--depth=1',
                                    f'https://github.com/{owner}/{repo}.git', revision], check=True)
                    repos[key] = target
                blob = subprocess.check_output(['git', '-C', repos[key], 'cat-file', 'blob', f'{revision}:{path}'])
                if not blob.startswith(b'MThd'):
                    raise ValueError(f'Not a standard MIDI file: {song["url"]}')
                literal = ''.join(f'\\x{byte:02x}' for byte in blob)
                name = json.dumps(song['name'], ensure_ascii=False)
                test.write(f'verifySong({name},"{literal}")\n')
            test.write(f'print("Verified {len(songs)} pinned MIDI files; failures: " .. failures)\n'
                       'assert(failures == 0)\n')
        subprocess.run([os.environ.get('LUAU_BIN', 'luau'), harness], check=True)


if __name__ == '__main__':
    main()
