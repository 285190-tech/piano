// Validate the built-in song catalog's shape and URL hygiene in CI.
const fs = require("fs");
const path = require("path");

const file = path.join(__dirname, "..", "songs.json");
const songs = JSON.parse(fs.readFileSync(file, "utf8"));
if (!Array.isArray(songs) || songs.length === 0) {
    throw new Error("songs.json must be a non-empty array");
}

const names = new Set();
const urls = new Set();
for (const [index, song] of songs.entries()) {
    const where = `songs.json entry ${index + 1}`;
    if (!song || typeof song !== "object" || Array.isArray(song)) {
        throw new Error(`${where} must be an object`);
    }
    if (typeof song.name !== "string" || song.name.trim() === "") {
        throw new Error(`${where} must have a non-empty string name`);
    }
    if (typeof song.url !== "string" || song.url.trim() === "") {
        throw new Error(`${where} must have a non-empty string url`);
    }
    let parsed;
    try {
        parsed = new URL(song.url);
    } catch {
        throw new Error(`${where} has an invalid URL: ${song.url}`);
    }
    if (parsed.protocol !== "https:" && parsed.protocol !== "http:") {
        throw new Error(`${where} URL must use HTTP(S): ${song.url}`);
    }
    if (!parsed.pathname.toLowerCase().endsWith(".mid")) {
        throw new Error(`${where} URL path must end in .mid: ${song.url}`);
    }
    if (names.has(song.name)) throw new Error(`Duplicate song name: ${song.name}`);
    if (urls.has(song.url)) throw new Error(`Duplicate song URL: ${song.url}`);
    names.add(song.name);
    urls.add(song.url);
}

console.log(`songs.json: ${songs.length} valid entries`);
