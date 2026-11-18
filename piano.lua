local QUICKPICKS_REPO_URL = "https://raw.githubusercontent.com/q-29/piano/main/songs.json"

local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")

-- ==========================================
-- Built-in Fallback Quick Picks
-- ==========================================
local DEFAULT_QUICKPICKS = {
    {name = "Tokyo Ghoul - Unravel (Full)", url = "https://raw.githubusercontent.com/callmeyyzx/midi/9ebe76e3d55331ca223d0486f7ca56b738d5f639/%E3%80%90%E4%B8%9C%E4%BA%AC%E5%96%B0%E7%A7%8D%E4%B8%9C%E4%BA%AC%E9%A3%9F%E5%B0%B8%E9%AC%BC%E3%80%91OP-------Unravel.mid", category = "Anime"},
    {name = "Tokyo Ghoul - Unravel (Simple)", url = "https://raw.githubusercontent.com/MAraragi/MusicalScoreRecognition/8d116679be671fb49d95c196cff254552872aeb1/new_midi_file/unravel_after.mid", category = "Anime"},
    {name = "JoJo - Giorno's Theme (Golden Wind)", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Golden%20Wind_JJBA_Giorno_Giovannas_Theme_SOLO.mid", category = "Anime"},
    {name = "JoJo - Bloody Stream", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Bloody%20Stream%20%28JoJo%27s%20Bizarre%20Adventure%29.mid", category = "Anime"},
    {name = "JoJo - Awaken (Pillar Men)", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Jojo%27s%20Bizarre%20Adventure-%20Awaken%20%28Pillar%20Men%20theme%29.mid", category = "Anime"},
    {name = "JoJo - Jonathan's Victory Theme", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Jonathan%27s%20Victory%20Theme.mid", category = "Anime"},
    {name = "Rush E", url = "https://raw.githubusercontent.com/KiyoEditz/Maestro/0c187e80525240b6876d669ae7776ef43baaab51/rush_e_real.mid", category = "Instrumental"},
    {name = "Yiruma - River Flows in You", url = "https://raw.githubusercontent.com/KiyoEditz/Maestro/0c187e80525240b6876d669ae7776ef43baaab51/River-Flows-In-You.mid", category = "Instrumental"},
    {name = "JVKE - Golden Hour", url = "https://raw.githubusercontent.com/KiyoEditz/Maestro/0c187e80525240b6876d669ae7776ef43baaab51/JVKE%20-%20golden%20hour.mid", category = "Pop & Rock"},
    {name = "Canon Rock", url = "https://raw.githubusercontent.com/KiyoEditz/Maestro/0c187e80525240b6876d669ae7776ef43baaab51/Canon-Rock.mid", category = "Pop & Rock"},
    {name = "The Stranglers - Golden Brown", url = "https://raw.githubusercontent.com/KiyoEditz/Maestro/0c187e80525240b6876d669ae7776ef43baaab51/The%20Stranglers%20-%20Golden%20Brown%20%28Updated%29.mid", category = "Pop & Rock"},
    {name = "Beethoven - Fur Elise", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Fur%20Elise.mid", category = "Classical"},
    {name = "Beethoven - Moonlight Sonata (1st Mvt)", url = "https://raw.githubusercontent.com/KiyoEditz/Maestro/0c187e80525240b6876d669ae7776ef43baaab51/Beethoven%20-%20Moonlight%20Sonata%20%281st%20Movement%29%20.mid", category = "Classical"},
    {name = "Beethoven - Moonlight Sonata (3rd Mvt)", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Beethoven-%20Moonlight%20Sonata%20%283rd%20mvt.%29.mid", category = "Classical"},
    {name = "Beethoven - Ode To Joy", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Beethoven%20-%20Ode%20To%20Joy.mid", category = "Classical"},
    {name = "Beethoven Virus", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Beethoven%20Virus%20%281%29.mid", category = "Pop & Rock"},
    {name = "Pachelbel - Canon in D", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Canon%20in%20D.mid", category = "Classical"},
    {name = "Erik Satie - Gymnopedie No. 1", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Erik%20Satie%20-%20Gymnopedie%20No.%201.mid", category = "Classical"},
    {name = "Chopin - Revolutionary Etude", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Chopin%27s%20revolutionary%20etude.mid", category = "Classical"},
    {name = "Chopin - Minute Waltz", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Chopin-Minute%20Waltz%20%28op%2064%20no%201%29.mid", category = "Classical"},
    {name = "Vivaldi - Four Seasons Winter (Rousseau)", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Antonio%20Vivaldi%20-%20The%20Four%20Seasons%20%5BWinter%20Mvt%201.%5D%20%28Rousseau%20Cover%29.mid", category = "Classical"},
    {name = "Grieg - In the Hall of the Mountain King", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/In%20the%20hall%20of%20the%20Mountain%20King.mid", category = "Classical"},
    {name = "Monti - Czardas", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Czardas.mid", category = "Classical"},
    {name = "Scott Joplin - Maple Leaf Rag", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/JOPLIN.Maple%20leaf%20rag.mid", category = "Classical"},
    {name = "Howl's Moving Castle - Merry-Go-Round of Life", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Joe%20Hisaishi%20-%20Merry%20Go%20Round%20Of%20Life%20%28Howl%27s%20Moving%20Castle%29.mid", category = "Anime"},
    {name = "Naruto Shippuden - Blue Bird", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Blue%20Bird%20-%20Naruto%20Shippuden%20OP3.mid", category = "Anime"},
    {name = "Your Lie in April - Hikaru Nara", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Hikaru%20Nara.mid", category = "Anime"},
    {name = "Evangelion - Cruel Angel's Thesis", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Evangelion%20-%20Cruel%20Angel%27s%20Thesis.mid", category = "Anime"},
    {name = "Death Note - L's Theme", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Death%20Note%20-%20L%27s%20Theme.mid", category = "Anime"},
    {name = "Attack on Titan - Jiyuu no Tsubasa", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Attack%20on%20Titan%20-%20Jiyuu%20no%20Tsubasa.mid", category = "Anime"},
    {name = "Demon Slayer", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Demon%20Slayer.mid.mid", category = "Anime"},
    {name = "Dragon Ball Z - CHA-LA HEAD-CHA-LA", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/CHA%20LA%20HEAD%20CHA%20LA%20%28Dragon%20Ball%20Z%29.mid", category = "Anime"},
    {name = "Hatsune Miku - Senbonzakura", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Hatsune%20Miku%20-%20Senbonzakura.mid", category = "Pop & Rock"},
    {name = "Touhou - Bad Apple", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Bad%20Apple.mid", category = "Games"},
    {name = "Undertale - Megalovania", url = "https://raw.githubusercontent.com/KiyoEditz/Maestro/0c187e80525240b6876d669ae7776ef43baaab51/Undertale%20-%20Megalovania%20%28Remaster%20coming%20no%20soon%29.mid", category = "Games"},
    {name = "Undertale - Hopes and Dreams", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Hopes%20and%20Dreams%20-%20Undertale%20%28WIP%29.mid", category = "Games"},
    {name = "Undertale - Bergentruckung (Asgore)", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Bergentruckung%20asgore%20theme%20%28original%20transcription%2C%20full%29.mid", category = "Games"},
    {name = "OMORI - Duet", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/DUET%20%28OMORI%29.mid", category = "Games"},
    {name = "DMC5 - Bury The Light", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Bury%20The%20Light%20%28DMC5%29.mid", category = "Games"},
    {name = "Dark Souls - Gwyn, Lord of Cinder", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Gwyn%2C%20Lord%20of%20Cinder.mid.mid", category = "Games"},
    {name = "Skyrim - Dragonborn Theme", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Elder%20Scrolls%20V%20-%20Skyrim%20-%20Dragonborn%20Theme.mid", category = "Games"},
    {name = "Hollow Knight - Mantis Lords", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Hollow%20Knight%20-%20Mantis%20Lords%20Theme.mid", category = "Games"},
    {name = "Hollow Knight - Hornet", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Hollow%20Knight_%20Hornet.mid", category = "Games"},
    {name = "Minecraft - Sweden", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/C418%20-%20Sweden.mid", category = "Games"},
    {name = "Minecraft - Mice on Venus", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Mice%20on%20Venus%20-%20Minecraft.mid", category = "Games"},
    {name = "Minecraft - Subwoofer Lullaby", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Subwoofer%20Lullaby-C418-%20Minecraft.mid", category = "Games"},
    {name = "Minecraft - Aria Math", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Aria%20Math%20-%20C418.mid", category = "Games"},
    {name = "Minecraft - Pigstep", url = "https://raw.githubusercontent.com/callmeyyzx/midi/9ebe76e3d55331ca223d0486f7ca56b738d5f639/Pigstep__Minecraft.mid", category = "Games"},
    {name = "FNAF 1 Song - The Living Tombstone", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Five%20Nights%20At%20Freddy%27s%20-%20Living%20Tombstone.mid", category = "Games"},
    {name = "Bad Piggies Theme", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Bad%20Piggies%20-%20Main%20Theme%20by%20Funkfan.mid", category = "Games"},
    {name = "Zelda OoT - Song of Storms", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/The%20Legend%20of%20Zelda%20Ocarina%20of%20Time%20-%20Song%20of%20Storms.mid", category = "Games"},
    {name = "Super Mario Bros Theme", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Mario%20Bros.%20-%20Super%20Mario%20Bros.%20Theme.mid", category = "Games"},
    {name = "Super Mario 64 - Inside the Castle Walls", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Inside%20the%20Castle%20Walls%20-%20Super%20Mario%2064.mid", category = "Games"},
    {name = "Tetris - A Theme", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Tetris%20-%20A%20Theme.mid", category = "Games"},
    {name = "Pokemon Center Theme", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Pokemon%20-%20Pokemon%20Center%20Theme.mid", category = "Games"},
    {name = "Wii - Mii Channel Theme", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Mii%20Channel%20Theme%20%28Pixel-Phil%29.mid", category = "Games"},
    {name = "Pirates of the Caribbean - He's a Pirate", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Pirates%20of%20the%20Caribbean%20-%20He%27s%20a%20Pirate%20%281%29.mid", category = "Film & TV"},
    {name = "Interstellar - Main Theme (Hans Zimmer)", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Interstellar%20Main%20Theme-%20Hans%20Zimmer.mid", category = "Film & TV"},
    {name = "Inception - Time (Hans Zimmer)", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Hans%20Zimmer%20-%20Time.mid", category = "Film & TV"},
    {name = "How to Train Your Dragon - Test Drive", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/How%20to%20train%20your%20dragon%20-%20Test%20Drive.mid", category = "Film & TV"},
    {name = "Star Wars - Duel of the Fates", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Duel%20of%20the%20Fates%20by%20John%20Williams.mid", category = "Film & TV"},
    {name = "Adele - Skyfall", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Adele%20-%20Skyfall.mid", category = "Film & TV"},
    {name = "Queen - Bohemian Rhapsody", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Bohemian-Rhapsody-1.mid", category = "Pop & Rock"},
    {name = "Coldplay - Viva La Vida", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Coldplay%20-%20Viva%20La%20Vida.mid", category = "Pop & Rock"},
    {name = "Coldplay - Clocks", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Coldplay%20-%20Clocks%20%28Full%20Song%29.mid", category = "Pop & Rock"},
    {name = "Billy Joel - Piano Man", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Billy%20Joel%20-%20Piano%20Man.mid", category = "Pop & Rock"},
    {name = "a-ha - Take On Me", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/A%20HA.Take%20on%20me%20%20K.mid", category = "Pop & Rock"},
    {name = "ABBA - Dancing Queen", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/ABBA%20-%20Dancing%20Queen.mid", category = "Pop & Rock"},
    {name = "Smash Mouth - All Star", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/SMASH%20MOUTH.All%20star.mid", category = "Pop & Rock"},
    {name = "George Michael - Careless Whisper", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Careless-Whisper.mid", category = "Pop & Rock"},
    {name = "Astronomia (Coffin Dance)", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Tony%20Iggy%20-%20Astronomia.mid", category = "Pop & Rock"},
    {name = "Alan Walker - Faded", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/faded.mid", category = "Pop & Rock"},
    {name = "Avicii - Wake Me Up", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/avicii-wake_me_up.mid", category = "Pop & Rock"},
    {name = "It's Just a Burning Memory", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/It%27s%20just%20a%20burning%20memory%20-%20A1.mid", category = "Instrumental"},
    {name = "Laufey - From The Start", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/From%20the%20start%20-%20Laufey.mid", category = "Pop & Rock"},
    {name = "Arctic Monkeys - 505", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/505%20-%20Arctic%20Monkeys.mid", category = "Pop & Rock"},
    {name = "Eminem - The Real Slim Shady", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Eminem%20-%20The%20Real%20Slim%20Shady.mid", category = "Pop & Rock"},
    {name = "Rick Astley - Never Gonna Give You Up", url = "https://raw.githubusercontent.com/callmeyyzx/midi/9ebe76e3d55331ca223d0486f7ca56b738d5f639/Never%20gonna%20give%20you%20up.mid", category = "Pop & Rock"},
    {name = "ABBA - Lay All Your Love on Me", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Abba%20-%20Lay%20All%20Your%20Love%20On%20Me.mid.mid", category = "Pop & Rock"},
    {name = "Animal Crossing - K.K. Lullaby", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Animal%20Crossing%20-%20KK%20Lullaby%20Aircheck.mid", category = "Games"},
    {name = "Avicii - Levels", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Avicii%20-%20Levels.mid", category = "Pop & Rock"},
    {name = "Avicii - Waiting for Love", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Avicii%20-%20Waiting%20for%20love.mid", category = "Pop & Rock"},
    {name = "Avicii - Hey Brother", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Hey_Brother-Avicii.mid", category = "Pop & Rock"},
    {name = "Avicii - The Nights", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/The%20Nights%20-%20Avicii.mid", category = "Pop & Rock"},
    {name = "Coldplay - Yellow", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Coldplay%20-%20Yellow.mid", category = "Pop & Rock"},
    {name = "Daft Punk - Around the World", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Daft%20Punk%20-%20Around%20The%20World.mid", category = "Pop & Rock"},
    {name = "Daft Punk - One More Time", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Daft%20Punk%20-%20One%20More%20Time.mid", category = "Pop & Rock"},
    {name = "Daft Punk - Harder, Better, Faster, Stronger", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Daft_Punk_-_Harder_Better_Faster_Stronger_-_DmdX.mid", category = "Pop & Rock"},
    {name = "Elton John - Bennie and the Jets", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Elton%20John%20-%20Bennie%20and%20the%20Jets%20-%20Edit%20by%20Sesh.mid.mid", category = "Pop & Rock"},
    {name = "Elton John - I'm Still Standing", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Elton%20John%20-%20I%27m%20still%20standing.mid", category = "Pop & Rock"},
    {name = "Elton John - Rocket Man", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Elton%20John%20-%20Rocket%20Man.mid", category = "Pop & Rock"},
    {name = "Fleetwood Mac - The Chain", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/The%20Chain%20-%20Fleetwood%20Mac.mid", category = "Pop & Rock"},
    {name = "Frank Sinatra - Fly Me to the Moon", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Fly%20Me%20To%20The%20Moon%202.mid", category = "Pop & Rock"},
    {name = "Green Day - Wake Me Up When September Ends", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Green%20Day%20-%20Wake%20Me%20Up%20When%20September%20Ends.mid", category = "Pop & Rock"},
    {name = "Imagine Dragons - Believer", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Believer.mid", category = "Pop & Rock"},
    {name = "Imagine Dragons - Bones", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Imagine%20Dragons%20%20Bones.mid", category = "Pop & Rock"},
    {name = "Imagine Dragons - Demons", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Demons-%20Imagine%20Dragons.mid", category = "Pop & Rock"},
    {name = "Imagine Dragons - Enemy", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Enemy%20Imagine%20Dragons%20PIANO%20-%20MIDI.mid.mid", category = "Pop & Rock"},
    {name = "Imagine Dragons - Radioactive", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Imagine%20dragons%20-%20Radioactive.mid", category = "Pop & Rock"},
    {name = "Imagine Dragons - Thunder", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Thunder%20-%20Imagine%20Dragons.mid", category = "Pop & Rock"},
    {name = "Leonard Cohen - Hallelujah", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Leonard%20Cohen%20-%20Hallelujah.mid", category = "Pop & Rock"},
    {name = "Linkin Park - Numb", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/linkin_park-numb.mid", category = "Pop & Rock"},
    {name = "Linkin Park - One Step Closer", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Linkin%20Park%20-%20One%20Step%20Closer.mid", category = "Pop & Rock"},
    {name = "Luis Fonsi - Despacito", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Luis%20Fonsi%20-%20Despacito%20-%20MIDI.mid.mid", category = "Pop & Rock"},
    {name = "Ludovico Einaudi - Experience", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Ludovico%20Einaudi%20-%20Experience.mid", category = "Instrumental"},
    {name = "Metallica - Enter Sandman", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Metallica%20-%20Enter%20Sandman.mid", category = "Pop & Rock"},
    {name = "Metallica - Master of Puppets", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Metallica%20-%20Master%20Of%20Puppets.mid", category = "Pop & Rock"},
    {name = "Metallica - Nothing Else Matters", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Metallica%20-%20Nothing%20Else%20Matters.mid", category = "Pop & Rock"},
    {name = "Michael Jackson - Beat It", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Michael%20Jackson%20-%20Beat%20It.mid", category = "Pop & Rock"},
    {name = "Michael Jackson - Billie Jean", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Michael%20Jackson%20-%20Billie%20Jean.mid", category = "Pop & Rock"},
    {name = "Nirvana - Smells Like Teen Spirit", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Nirvana%20-%20Smells%20Like%20Teen%20Spirit.mid", category = "Pop & Rock"},
    {name = "Nirvana - Lithium", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Nirvana%20~%20Lithium%20-%20COMPLETE.mid", category = "Pop & Rock"},
    {name = "Rag'n'Bone Man - Human", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Rag%27n%27Bone%20Man%20-%20Human.mid", category = "Pop & Rock"},
    {name = "Sia - Snowman", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Snowman%20-%20Sia.mid", category = "Pop & Rock"},
    {name = "The Beatles - Because", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/The%20Beatles%20-%20Because.mid", category = "Pop & Rock"},
    {name = "The Beatles - Come Together", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/The%20Beatles%20-%20Come%20Together.mid", category = "Pop & Rock"},
    {name = "The Beatles - Here Comes the Sun", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/The%20Beatles%20-%20Here%20Comes%20the%20Sun.mid", category = "Pop & Rock"},
    {name = "The Beatles - Hey Jude", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/THE%20BEATLES.Hey%20Jude%20K.mid", category = "Pop & Rock"},
    {name = "The Beatles - Octopus's Garden", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/The%20Beatles%20-%20Octopus%27s%20Garden.mid", category = "Pop & Rock"},
    {name = "The Beatles - Something", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/The%20Beatles%20-%20Something.mid", category = "Pop & Rock"},
    {name = "The Beatles - Strawberry Fields Forever", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/The%20Beatles%20-%20Strawberry%20Fields%20Forever.mid", category = "Pop & Rock"},
    {name = "The Eagles - Hotel California", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/THE%20EAGLES.Hotel%20California%20K.mid", category = "Pop & Rock"},
    {name = "Two Steps From Hell - Heart of Courage", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Heart%20of%20Courage-%20Two%20Steps%20From%20Hell.mid", category = "Instrumental"},
    {name = "Attack on Titan - Vogel im Käfig", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Attack%20on%20Titan%20-%20Vogel%20im%20K%25E4fig.mid", category = "Anime"},
    {name = "Dragon Ball - Opening Theme", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Dragon%20Ball%20%28Classic%29%20Theme.mid", category = "Anime"},
    {name = "Dragon Ball Kai - Dragon Soul", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Dragon%20Ball%20Kai%20-%20Dragon%20Soul.mid", category = "Anime"},
    {name = "Fairy Tail - Main Theme (Piano)", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Fairy%20Tail%20-%20Main%20Theme%20%28Piano%20Ver%29.mid", category = "Anime"},
    {name = "Fairy Tail - Sad Theme", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Fairy%20Tail%20-%20Sad%20Theme%20%28Piano%29.mid", category = "Anime"},
    {name = "Naruto - Rocks", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Naruto%20-%201st%20opening%20-%20Rocks.mid", category = "Anime"},
    {name = "Naruto - Sadness and Sorrow", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Naruto%20-%20sadness%20and%20sorrow.mid", category = "Anime"},
    {name = "Naruto Shippuden - Akatsuki Theme", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Naruto%20Shippuden%20-%20Akatsuki%20Theme.mid", category = "Anime"},
    {name = "One Piece - Bink's Sake", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/One%20Piece%20-%20Bink%27s%20Sake.mid", category = "Anime"},
    {name = "One Piece - Medley", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/One%20Piece%20-%20One%20Piece%20Medley.mid", category = "Anime"},
    {name = "Interstellar - No Time for Caution", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/No%20Time%20For%20Caution%20%28Interstellar%29%20.mid", category = "Film & TV"},
    {name = "Jurassic Park - Main Theme", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Jurassic%20Park%20Theme.mid", category = "Film & TV"},
    {name = "How to Train Your Dragon - Where No One Goes", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/How%20to%20Train%20Your%20Dragon%20-%20Where%20No%20One%20Goes.mid", category = "Film & TV"},
    {name = "Pirates of the Caribbean - Davy Jones", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Davy%20Jones%20Theme%20%28Pirates%20of%20the%20Caribbean%29.mid", category = "Film & TV"},
    {name = "Star Wars - Main Title", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Star%20Wars%20Theme%20-%20Main%20Title.mid", category = "Film & TV"},
    {name = "Star Wars - The Imperial March", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Star%20Wars%20-%20The%20Imperial%20March.mid", category = "Film & TV"},
    {name = "Up - Married Life", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Married%20Life%20-%20UP%202.mid.mid", category = "Film & TV"},
    {name = "Deltarune - A CYBER'S WORLD?", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Deltarune_%20A%20CYBER%27S%20WORLD_%20%28Pixel-Phil%29.mid", category = "Games"},
    {name = "Final Fantasy VII - Main Theme", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Final%20Fantasy%20VII%20-%20Final%20Fantasy%20VII%20Main%20Theme.mid", category = "Games"},
    {name = "Final Fantasy VII - One-Winged Angel", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Final%20Fantasy%20VII%20-%20One%20Winged%20Angel%20%28Better%20Version%29%20%281%29.mid", category = "Games"},
    {name = "Final Fantasy XIV - Dragonsong", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Dragonsong%20FFXIV.mid", category = "Games"},
    {name = "Final Fantasy XIV - Heavensward", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Heavensward%20-%20Final%20Fantasy%20XIV%203.0%20%28Rutuweianzhice%29.mid", category = "Games"},
    {name = "FNAF 2 - It's Been So Long", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/The%20Living%20Tombstone%20-%20It%27s%20Been%20So%20Long%20%28FNaF%202%20Song%29.mid", category = "Games"},
    {name = "FNAF 3 - Die in a Fire", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Die%20In%20a%20Fire%20%28A%20FNAF%203%20Song%29%20-%20The%20Living%20Tombstone.mid", category = "Games"},
    {name = "FNAF 4 - I Got No Time", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/The%20Living%20Tombstone%20-%20I%20Got%20No%20Time%20%28FNAF%204%29.mid", category = "Games"},
    {name = "FNAF Sister Location - I Can't Fix You", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/I%20Can%27t%20Fix%20You-%20Sister%20Location%20%28The%20Living%20Tombstone%29%20%28Piano%29.mid", category = "Games"},
    {name = "Genshin Impact - Good Night Liyue", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Genshin%20Impact_%20Good%20Night%20Liyue%20%28Pixel-Phil%29.mid", category = "Games"},
    {name = "Genshin Impact - In a Harmonious Atmosphere", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Genshin%20Impact_%20In%20a%20Harmonious%20Atmosphere%20%28Pixel-Phil%29.mid", category = "Games"},
    {name = "Genshin Impact - Tales of Woe", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Genshin%20Impact_%20Tales%20of%20Woe%20%28Pixel-Phil%29.mid", category = "Games"},
    {name = "Genshin Impact - All the World's a Stage", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Furina_%20All%20the%20World%27s%20a%20Stage%20%28Furina%20Theme%29%20-%20Genshin%20Impact.mid", category = "Games"},
    {name = "Genshin Impact - Le Souvenir avec le crépuscule", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Le%20Souvenir%20avec%20le%20crepuscule%20-%20Fontaine%20_%20Genshin%20Impact.mid", category = "Games"},
    {name = "Geometry Dash - Back on Track", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Back%20on%20Track%20Geometry%20dash.mid", category = "Games"},
    {name = "Halo - Main Theme", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/halo%20theme.mid.mid", category = "Games"},
    {name = "Halo 2 - Menu Theme", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Halo%202%20-%20Menu.mid", category = "Games"},
    {name = "Kingdom Hearts - Dearly Beloved", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Kingdom%20Hearts%20-%20Dearly%20Beloved.mid", category = "Games"},
    {name = "Kirby Super Star - Gourmet Race", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Kirby%20Super%20Star%20-%20Gourmet%20Race.mid", category = "Games"},
    {name = "Kirby Super Star - Marx Boss Battle", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Kirby%20Super%20Star%20-%20Marx%20Boss%20Battle.mid", category = "Games"},
    {name = "Minecraft - Fallen Kingdom", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Minecraft%20-%20Parody%20of%20Coldplay_s%20Viva%20la%20Vida%20-%20Fallen%20Kingdom.mid", category = "Games"},
    {name = "Minecraft - Living Mice", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Minecraft%20-%20LivingMice.mid", category = "Games"},
    {name = "Minecraft - Moog City", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Minecraft%20-%20MoogCity.mid", category = "Games"},
    {name = "Minecraft - Wet Hands", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Minecraft%20-%20Wet%20Hands%20%28Piano%20Solo%29.mid", category = "Games"},
    {name = "Pokémon - Wild Battle (Red / Blue / Yellow)", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Pokemon%20RedBlueYellow%20-%20Wild%20Pokemon%20Battle.mid", category = "Games"},
    {name = "Pokémon Black and White - Dreamyard / Pinwheel Forest", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Pokemon%20Black_White%20Dreamyard_Pinwheel%20Forest.mid", category = "Games"},
    {name = "Pokémon Black 2 and White 2 - Battle! Kyurem", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Battle%21%20Black%20Kyurem%20_%20White%20Kyurem%20-%20Pokemon%20Black%202%20and%20White%202.mid", category = "Games"},
    {name = "Portal - Still Alive", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Portal%20-%20Still%20Alive.mid", category = "Games"},
    {name = "Portal 2 - Cara Mia Addio", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Portal%202%20-%20Cara%20Mia.mid", category = "Games"},
    {name = "Red Dead Redemption 2 - A Quiet Time", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/A%20Quiet%20Time%20Red%20Dead%20Redemption%202.mid", category = "Games"},
    {name = "Red Dead Redemption 2 - Cruel Cruel World", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Cruel%20Cruel%20World%20-%20Red%20Dead%20Redemption%202.mid", category = "Games"},
    {name = "Red Dead Redemption 2 - House Building Theme", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Red%20Dead%202%20-%20House%20Building%20Theme%20-%20Edit%20by%20Sesh.mid", category = "Games"},
    {name = "Red Dead Redemption 2 - Mountain Banjo", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Mountain%20Banjo%20-%20Red%20Dead%20Redemption%202.mid", category = "Games"},
    {name = "Sonic the Hedgehog - Green Hill Zone", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Sonic%20the%20Hedgehog%20-%20Green%20Hill%20Zone.mid", category = "Games"},
    {name = "Super Mario 64 - Slide", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Super%20Mario%2064%20-%20Slide.mid", category = "Games"},
    {name = "Super Mario Land 2 - Athletic Theme", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Super%20Mario%20Land%202%206%20Golden%20Coins%20-%20Athletic.mid", category = "Games"},
    {name = "Super Mario Land 2 - Star Maze", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Super%20Mario%20Land%202%206%20Golden%20Coins%20-%20Star%20Maze.mid", category = "Games"},
    {name = "Super Mario RPG - Forest Maze", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Super%20Mario%20RPG%20-%20Forest%20Maze.mid", category = "Games"},
    {name = "Super Mario World - Ending Theme", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Super%20Mario%20World%20-%20Ending%20Theme%20%28Tom%20Brier%29.mid", category = "Games"},
    {name = "Undertale - Fallen Down (Reprise)", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Undertale%20-%20Fallen%20Down%20%28Reprise%29.mid.mid", category = "Games"},
    {name = "Undertale - Finale", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Undertale%20-%20Finale.mid", category = "Games"},
    {name = "Undertale - Spider Dance", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Undertale%20-%20Spider%20Dance.mid", category = "Games"},
    {name = "Undertale Yellow - Enemy Retreating", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Undertale%20Yellow%20-%20Enemy%20Retreating.mid", category = "Games"},
    {name = "Undertale Yellow - Justice", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Undertale%20Yellow%20-%20Justice.mid", category = "Games"},
    {name = "Undertale Yellow - A Mother's Love", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Undertale%20Yellow%20OST_%20120%20-%20A%20Mother%27s%20Love.mid", category = "Games"},
    {name = "Zelda - Overworld", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Legend%20of%20Zelda%20-%20Overworld.mid", category = "Games"},
    {name = "Zelda OoT - Song of Time", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/The%20Legend%20of%20Zelda%20Ocarina%20of%20Time%20-%20Song%20of%20Time.mid", category = "Games"},
    {name = "Zelda OoT - Zelda's Lullaby", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Zelda%20-%20Legend%20of%20Zelda%20-%20Zeldas%20Lullaby%20-%20Hyrule%20Symphonic%20Version.mid", category = "Games"},
    {name = "Zelda BotW - Goron City (Day)", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Goron%20City%20%28Day%29%20-%20Legend%20of%20Zelda%20Breath%20of%20the%20Wild.mid", category = "Games"},
    {name = "Zelda BotW - Kass' Theme", url = "https://raw.githubusercontent.com/thewildwestmidis/midis/4f320c690f70ad933cee505fa5ddbe03fa90f121/Legend%20of%20Zelda_%20Breath%20of%20the%20Wild%20-%20Kass%27%20Theme.mid", category = "Games"},
    {name = "Petzold - Minuet in G Major, BWV Anh. 114", url = "https://raw.githubusercontent.com/bubagump02/piano-buddy-catalogue/8d32604626104436cb076951aaa1bdf3b1775a11/bach-menuet-g.mid", category = "Classical"},
    {name = "Petzold - Minuet in G Minor, BWV Anh. 115", url = "https://raw.githubusercontent.com/bubagump02/piano-buddy-catalogue/8d32604626104436cb076951aaa1bdf3b1775a11/bach-menuet-g-mineur.mid", category = "Classical"},
    {name = "Bach - Musette in D Major, BWV Anh. 126", url = "https://raw.githubusercontent.com/bubagump02/piano-buddy-catalogue/8d32604626104436cb076951aaa1bdf3b1775a11/bach-musette.mid", category = "Classical"},
    {name = "Burgmüller - Arabesque, Op. 100 No. 2", url = "https://raw.githubusercontent.com/bubagump02/piano-buddy-catalogue/8d32604626104436cb076951aaa1bdf3b1775a11/burgmuller-arabesque.mid", category = "Classical"},
    {name = "Burgmüller - Innocence, Op. 100 No. 5", url = "https://raw.githubusercontent.com/bubagump02/piano-buddy-catalogue/8d32604626104436cb076951aaa1bdf3b1775a11/burgmuller-innocence.mid", category = "Classical"},
    {name = "Tchaikovsky - Morning Prayer, Op. 39 No. 1", url = "https://raw.githubusercontent.com/bubagump02/piano-buddy-catalogue/8d32604626104436cb076951aaa1bdf3b1775a11/tchaikovsky-priere.mid", category = "Classical"},
    {name = "Tchaikovsky - Old French Song, Op. 39 No. 16", url = "https://raw.githubusercontent.com/bubagump02/piano-buddy-catalogue/8d32604626104436cb076951aaa1bdf3b1775a11/tchaikovsky-chanson.mid", category = "Classical"},
    {name = "Tchaikovsky - March of the Wooden Soldiers, Op. 39 No. 5", url = "https://raw.githubusercontent.com/bubagump02/piano-buddy-catalogue/8d32604626104436cb076951aaa1bdf3b1775a11/tchaikovsky-soldats.mid", category = "Classical"},
    {name = "Clementi - Sonatina in C Major, Op. 36 No. 1", url = "https://raw.githubusercontent.com/bubagump02/piano-buddy-catalogue/8d32604626104436cb076951aaa1bdf3b1775a11/clementi-sonatine-1.mid", category = "Classical"},
    {name = "Kuhlau - Sonatina in C Major, Op. 20 No. 1 (Allegro)", url = "https://raw.githubusercontent.com/bubagump02/piano-buddy-catalogue/8d32604626104436cb076951aaa1bdf3b1775a11/kuhlau-sonatine-1.mid", category = "Classical"},
    {name = "Chopin - Prelude in E Minor, Op. 28 No. 4", url = "https://raw.githubusercontent.com/bubagump02/piano-buddy-catalogue/8d32604626104436cb076951aaa1bdf3b1775a11/chopin-prelude-4.mid", category = "Classical"},
    {name = "Chopin - Prelude in C Minor, Op. 28 No. 20", url = "https://raw.githubusercontent.com/bubagump02/piano-buddy-catalogue/8d32604626104436cb076951aaa1bdf3b1775a11/chopin-prelude-20.mid", category = "Classical"},
    {name = "Bach - Prelude in C Major, BWV 846", url = "https://raw.githubusercontent.com/bubagump02/piano-buddy-catalogue/8d32604626104436cb076951aaa1bdf3b1775a11/bach-prelude-c.mid", category = "Classical"},
    {name = "Bach - Invention No. 8 in F Major, BWV 779", url = "https://raw.githubusercontent.com/bubagump02/piano-buddy-catalogue/8d32604626104436cb076951aaa1bdf3b1775a11/bach-invention-8.mid", category = "Classical"},
    {name = "Mozart - Sonata K. 331 (Opening Theme)", url = "https://raw.githubusercontent.com/bubagump02/piano-buddy-catalogue/8d32604626104436cb076951aaa1bdf3b1775a11/mozart-k331-theme.mid", category = "Classical"},
    {name = "Scott Joplin - The Entertainer", url = "https://raw.githubusercontent.com/bubagump02/piano-buddy-catalogue/8d32604626104436cb076951aaa1bdf3b1775a11/joplin-entertainer.mid", category = "Classical"},
    {name = "Chopin - Waltz in B Minor, Op. 69 No. 2", url = "https://raw.githubusercontent.com/bubagump02/piano-buddy-catalogue/8d32604626104436cb076951aaa1bdf3b1775a11/chopin-valse-b-mineur.mid", category = "Classical"},
    {name = "Beethoven - Pathétique Sonata (2nd Mvt)", url = "https://raw.githubusercontent.com/bubagump02/piano-buddy-catalogue/8d32604626104436cb076951aaa1bdf3b1775a11/beethoven-pathetique-2.mid", category = "Classical"},
    {name = "Debussy - Arabesque No. 1", url = "https://raw.githubusercontent.com/bubagump02/piano-buddy-catalogue/8d32604626104436cb076951aaa1bdf3b1775a11/debussy-arabesque-1.mid", category = "Classical"},
    {name = "Debussy - Clair de Lune", url = "https://raw.githubusercontent.com/bubagump02/piano-buddy-catalogue/8d32604626104436cb076951aaa1bdf3b1775a11/debussy-clair-de-lune.mid", category = "Classical"},
    {name = "Chopin - Prelude, Op. 28 No. 1", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Chopin/prelude28-01.mid", category = "Classical"},
    {name = "Chopin - Prelude, Op. 28 No. 2", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Chopin/prelude28-02.mid", category = "Classical"},
    {name = "Chopin - Prelude, Op. 28 No. 3", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Chopin/prelude28-03.mid", category = "Classical"},
    {name = "Chopin - Prelude, Op. 28 No. 5", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Chopin/prelude28-05.mid", category = "Classical"},
    {name = "Chopin - Prelude, Op. 28 No. 6", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Chopin/prelude28-06.mid", category = "Classical"},
    {name = "Chopin - Prelude, Op. 28 No. 7", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Chopin/prelude28-07.mid", category = "Classical"},
    {name = "Chopin - Prelude, Op. 28 No. 8", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Chopin/prelude28-08.mid", category = "Classical"},
    {name = "Chopin - Prelude, Op. 28 No. 9", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Chopin/prelude28-09.mid", category = "Classical"},
    {name = "Chopin - Prelude, Op. 28 No. 10", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Chopin/prelude28-10.mid", category = "Classical"},
    {name = "Chopin - Prelude, Op. 28 No. 11", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Chopin/prelude28-11.mid", category = "Classical"},
    {name = "Chopin - Prelude, Op. 28 No. 12", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Chopin/prelude28-12.mid", category = "Classical"},
    {name = "Chopin - Prelude, Op. 28 No. 13", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Chopin/prelude28-13.mid", category = "Classical"},
    {name = "Chopin - Prelude, Op. 28 No. 14", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Chopin/prelude28-14.mid", category = "Classical"},
    {name = "Chopin - Prelude, Op. 28 No. 15", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Chopin/prelude28-15.mid", category = "Classical"},
    {name = "Chopin - Prelude, Op. 28 No. 16", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Chopin/prelude28-16.mid", category = "Classical"},
    {name = "Chopin - Prelude, Op. 28 No. 17", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Chopin/prelude28-17.mid", category = "Classical"},
    {name = "Chopin - Prelude, Op. 28 No. 18", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Chopin/prelude28-18.mid", category = "Classical"},
    {name = "Chopin - Prelude, Op. 28 No. 19", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Chopin/prelude28-19.mid", category = "Classical"},
    {name = "Chopin - Prelude, Op. 28 No. 21", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Chopin/prelude28-21.mid", category = "Classical"},
    {name = "Chopin - Prelude, Op. 28 No. 22", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Chopin/prelude28-22.mid", category = "Classical"},
    {name = "Chopin - Prelude, Op. 28 No. 23", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Chopin/prelude28-23.mid", category = "Classical"},
    {name = "Chopin - Prelude, Op. 28 No. 24", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Chopin/prelude28-24.mid", category = "Classical"},
    {name = "Chopin - Mazurka, Op. 6 No. 1", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Chopin/mazurka06-1.mid", category = "Classical"},
    {name = "Chopin - Mazurka, Op. 6 No. 2", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Chopin/mazurka06-2.mid", category = "Classical"},
    {name = "Chopin - Mazurka, Op. 6 No. 3", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Chopin/mazurka06-3.mid", category = "Classical"},
    {name = "Chopin - Mazurka, Op. 6 No. 4", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Chopin/mazurka06-4.mid", category = "Classical"},
    {name = "Chopin - Mazurka, Op. 7 No. 1", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Chopin/mazurka07-1.mid", category = "Classical"},
    {name = "Chopin - Mazurka, Op. 7 No. 2", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Chopin/mazurka07-2.mid", category = "Classical"},
    {name = "Chopin - Mazurka, Op. 7 No. 3", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Chopin/mazurka07-3.mid", category = "Classical"},
    {name = "Chopin - Mazurka, Op. 7 No. 4", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Chopin/mazurka07-4.mid", category = "Classical"},
    {name = "Chopin - Mazurka, Op. 7 No. 5", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Chopin/mazurka07-5.mid", category = "Classical"},
    {name = "Chopin - Mazurka, Op. 17 No. 1", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Chopin/mazurka17-1.mid", category = "Classical"},
    {name = "Chopin - Mazurka, Op. 17 No. 2", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Chopin/mazurka17-2.mid", category = "Classical"},
    {name = "Chopin - Mazurka, Op. 17 No. 3", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Chopin/mazurka17-3.mid", category = "Classical"},
    {name = "Chopin - Mazurka, Op. 17 No. 4", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Chopin/mazurka17-4.mid", category = "Classical"},
    {name = "Chopin - Mazurka, Op. 24 No. 1", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Chopin/mazurka24-1.mid", category = "Classical"},
    {name = "Chopin - Mazurka, Op. 24 No. 2", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Chopin/mazurka24-2.mid", category = "Classical"},
    {name = "Chopin - Mazurka, Op. 24 No. 3", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Chopin/mazurka24-3.mid", category = "Classical"},
    {name = "Chopin - Mazurka, Op. 24 No. 4", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Chopin/mazurka24-4.mid", category = "Classical"},
    {name = "Beethoven - No. 1, Op. 2 No. 1 (Mvt 1)", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Beethoven/sonata01-1.mid", category = "Classical"},
    {name = "Beethoven - No. 1, Op. 2 No. 1 (Mvt 2)", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Beethoven/sonata01-2.mid", category = "Classical"},
    {name = "Beethoven - No. 1, Op. 2 No. 1 (Mvt 3)", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Beethoven/sonata01-3.mid", category = "Classical"},
    {name = "Beethoven - No. 1, Op. 2 No. 1 (Mvt 4)", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Beethoven/sonata01-4.mid", category = "Classical"},
    {name = "Beethoven - Pathétique, Op. 13 (Mvt 1)", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Beethoven/sonata08-1.mid", category = "Classical"},
    {name = "Beethoven - Pathétique, Op. 13 (Mvt 3)", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Beethoven/sonata08-3.mid", category = "Classical"},
    {name = "Beethoven - Moonlight, Op. 27 No. 2 (Mvt 2)", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Beethoven/sonata14-2.mid", category = "Classical"},
    {name = "Beethoven - Tempest, Op. 31 No. 2 (Mvt 1)", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Beethoven/sonata17-1.mid", category = "Classical"},
    {name = "Beethoven - Tempest, Op. 31 No. 2 (Mvt 2)", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Beethoven/sonata17-2.mid", category = "Classical"},
    {name = "Beethoven - Tempest, Op. 31 No. 2 (Mvt 3)", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Beethoven/sonata17-3.mid", category = "Classical"},
    {name = "Beethoven - Waldstein, Op. 53 (Mvt 1)", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Beethoven/sonata21-1.mid", category = "Classical"},
    {name = "Beethoven - Waldstein, Op. 53 (Mvt 2)", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Beethoven/sonata21-2.mid", category = "Classical"},
    {name = "Beethoven - Waldstein, Op. 53 (Mvt 3)", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Beethoven/sonata21-3.mid", category = "Classical"},
    {name = "Beethoven - Appassionata, Op. 57 (Mvt 1)", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Beethoven/sonata23-1.mid", category = "Classical"},
    {name = "Beethoven - Appassionata, Op. 57 (Mvt 2)", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Beethoven/sonata23-2.mid", category = "Classical"},
    {name = "Beethoven - Appassionata, Op. 57 (Mvt 3)", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Beethoven/sonata23-3.mid", category = "Classical"},
    {name = "Beethoven - Les Adieux, Op. 81a (Mvt 1)", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Beethoven/sonata26-1.mid", category = "Classical"},
    {name = "Beethoven - Les Adieux, Op. 81a (Mvt 2)", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Beethoven/sonata26-2.mid", category = "Classical"},
    {name = "Beethoven - Les Adieux, Op. 81a (Mvt 3)", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Beethoven/sonata26-3.mid", category = "Classical"},
    {name = "Beethoven - Hammerklavier, Op. 106 (Mvt 1)", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Beethoven/sonata29-1.mid", category = "Classical"},
    {name = "Beethoven - Hammerklavier, Op. 106 (Mvt 2)", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Beethoven/sonata29-2.mid", category = "Classical"},
    {name = "Beethoven - Hammerklavier, Op. 106 (Mvt 3)", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Beethoven/sonata29-3.mid", category = "Classical"},
    {name = "Beethoven - Hammerklavier, Op. 106 (Mvt 4)", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Beethoven/sonata29-4.mid", category = "Classical"},
    {name = "Beethoven - No. 30, Op. 109 (Mvt 1)", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Beethoven/sonata30-1.mid", category = "Classical"},
    {name = "Beethoven - No. 30, Op. 109 (Mvt 2)", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Beethoven/sonata30-2.mid", category = "Classical"},
    {name = "Beethoven - No. 30, Op. 109 (Mvt 3)", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Beethoven/sonata30-3.mid", category = "Classical"},
    {name = "Beethoven - No. 31, Op. 110 (Mvt 1)", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Beethoven/sonata31-1.mid", category = "Classical"},
    {name = "Beethoven - No. 31, Op. 110 (Mvt 2)", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Beethoven/sonata31-2.mid", category = "Classical"},
    {name = "Beethoven - No. 31, Op. 110 (Mvt 3)", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Beethoven/sonata31-3.mid", category = "Classical"},
    {name = "Beethoven - No. 32, Op. 111 (Mvt 1)", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Beethoven/sonata32-1.mid", category = "Classical"},
    {name = "Beethoven - No. 32, Op. 111 (Mvt 2)", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Beethoven/sonata32-2.mid", category = "Classical"},
    {name = "Scott Joplin - Antoinette", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Joplin/antoinette.mid", category = "Classical"},
    {name = "Scott Joplin - Bethena", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Joplin/bethena.mid", category = "Classical"},
    {name = "Scott Joplin - The Cascades", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Joplin/cascades.mid", category = "Classical"},
    {name = "Scott Joplin - The Chrysanthemum", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Joplin/chrysanthemum.mid", category = "Classical"},
    {name = "Scott Joplin - Cleopha", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Joplin/cleopha.mid", category = "Classical"},
    {name = "Scott Joplin - Country Club", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Joplin/countryclub.mid", category = "Classical"},
    {name = "Scott Joplin - Elite Syncopations", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Joplin/elite.mid", category = "Classical"},
    {name = "Scott Joplin - Eugenia", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Joplin/eugenia.mid", category = "Classical"},
    {name = "Scott Joplin - Felicity Rag", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Joplin/felicity.mid", category = "Classical"},
    {name = "Scott Joplin - Fig Leaf Rag", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Joplin/figleaf.mid", category = "Classical"},
    {name = "Scott Joplin - Gladiolus Rag", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Joplin/gladiolus.mid", category = "Classical"},
    {name = "Scott Joplin - Heliotrope Bouquet", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Joplin/heliotrope.mid", category = "Classical"},
    {name = "Scott Joplin - Lily Queen", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Joplin/lilyqueen.mid", category = "Classical"},
    {name = "Scott Joplin - Magnetic Rag", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Joplin/magnetic.mid", category = "Classical"},
    {name = "Scott Joplin - Scott Joplin’s New Rag", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Joplin/newrag.mid", category = "Classical"},
    {name = "Scott Joplin - Nonpareil", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Joplin/nonpareil.mid", category = "Classical"},
    {name = "Scott Joplin - Original Rags", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Joplin/original.mid", category = "Classical"},
    {name = "Scott Joplin - Paragon Rag", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Joplin/paragon.mid", category = "Classical"},
    {name = "Scott Joplin - Peacherine Rag", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Joplin/peacherine.mid", category = "Classical"},
    {name = "Scott Joplin - Pine Apple Rag", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Joplin/pineapple.mid", category = "Classical"},
    {name = "Scott Joplin - Rose Leaf Rag", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Joplin/roseleaf.mid", category = "Classical"},
    {name = "Scott Joplin - Searchlight Rag", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Joplin/searchlight.mid", category = "Classical"},
    {name = "Scott Joplin - Solace", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Joplin/solace.mid", category = "Classical"},
    {name = "Scott Joplin - Stop-Time Rag", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Joplin/stoptime.mid", category = "Classical"},
    {name = "Scott Joplin - Sugar Cane", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Joplin/sugarcane.mid", category = "Classical"},
    {name = "Scott Joplin - Swipesy Cakewalk", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Joplin/swipesy.mid", category = "Classical"},
    {name = "Scott Joplin - Wall Street Rag", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Joplin/wallstreet.mid", category = "Classical"},
    {name = "Scott Joplin - Weeping Willow", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Joplin/weepingwillow.mid", category = "Classical"},
    {name = "Scarlatti - Keyboard Sonata, K. 514", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Scarlatti/L001K514.mid", category = "Classical"},
    {name = "Scarlatti - Keyboard Sonata, K. 384", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Scarlatti/L002K384.mid", category = "Classical"},
    {name = "Scarlatti - Keyboard Sonata, K. 502", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Scarlatti/L003K502.mid", category = "Classical"},
    {name = "Scarlatti - Keyboard Sonata, K. 461", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Scarlatti/L008K461.mid", category = "Classical"},
    {name = "Scarlatti - Keyboard Sonata, K. 303", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Scarlatti/L009K303.mid", category = "Classical"},
    {name = "Scarlatti - Keyboard Sonata, K. 84", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Scarlatti/L010K084.mid", category = "Classical"},
    {name = "Scarlatti - Keyboard Sonata, K. 534", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Scarlatti/L011K534.mid", category = "Classical"},
    {name = "Scarlatti - Keyboard Sonata, K. 478", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Scarlatti/L012K478.mid", category = "Classical"},
    {name = "Scarlatti - Keyboard Sonata, K. 60", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Scarlatti/L013K060.mid", category = "Classical"},
    {name = "Scarlatti - Keyboard Sonata, K. 492", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Scarlatti/L014K492.mid", category = "Classical"},
    {name = "Scarlatti - Keyboard Sonata, K. 160", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Scarlatti/L015K160.mid", category = "Classical"},
    {name = "Scarlatti - Keyboard Sonata, K. 306", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Scarlatti/L016K306.mid", category = "Classical"},
    {name = "Scarlatti - Keyboard Sonata, K. 238", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Scarlatti/L027K238.mid", category = "Classical"},
    {name = "Scarlatti - Keyboard Sonata, K. 166", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Scarlatti/L051K166.mid", category = "Classical"},
    {name = "Scarlatti - Keyboard Sonata, K. 165", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Scarlatti/L052K165.mid", category = "Classical"},
    {name = "Scarlatti - Keyboard Sonata, K. 75", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Scarlatti/L053K075.mid", category = "Classical"},
    {name = "Scarlatti - Keyboard Sonata, K. 200", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Scarlatti/L054K200.mid", category = "Classical"},
    {name = "Scarlatti - Keyboard Sonata, K. 330", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Scarlatti/L055K330.mid", category = "Classical"},
    {name = "Scarlatti - Keyboard Sonata, K. 281", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Scarlatti/L056K281.mid", category = "Classical"},
    {name = "Scarlatti - Keyboard Sonata, K. 148", url = "https://raw.githubusercontent.com/narcisse-dev/classical_ancient_midifiles/366eb8ed315510bcd20e8b42dd81ad1215eb0c3a/classical/Scarlatti/L064K148.mid", category = "Classical"},
}

-- ==========================================
-- MIDI Stream & Parser
-- ==========================================
local function createStringStream(str)
    return {
        data = str,
        pos = 1,
        read = function(self, bytes)
            if bytes == 0 then return "" end
            if self.pos > #self.data then return nil end
            local res = self.data:sub(self.pos, self.pos + bytes - 1)
            self.pos = self.pos + bytes
            return res
        end,
        seek = function(self, whence, offset)
            if whence == "cur" then
                self.pos = self.pos + offset
            elseif whence == "set" then
                self.pos = offset + 1
            elseif whence == "end" then
                self.pos = #self.data + offset + 1
            end
            return self.pos - 1
        end
    }
end

local function read(stream, count)
    local result = ""
    while #result < count do
        local r = stream:read(count - #result)
        if not r or r == "" then error("missing value") end
        result = result .. r
    end
    return result
end

local function readVLQ(stream)
    local value = 0
    local length = 0
    repeat
        local b = stream:read(1)
        if not b then error("incomplete variable length quantity") end
        local byte = b:byte()
        value = bit32.lshift(value, 7)
        value = bit32.bor(value, bit32.band(byte, 0x7F))
        length = length + 1
        if length > 4 then error("VLQ too long") end
    until byte < 0x80
    return value, length
end

local midiEvent = {
    [0x80] = function(stream, callback, channel, fb)
        local key = fb:byte()
        local velocity = read(stream, 1):byte()
        callback("noteOff", channel, key, velocity / 0x7F)
        return 2
    end,
    [0x90] = function(stream, callback, channel, fb)
        local key = fb:byte()
        local velocity = read(stream, 1):byte()
        callback("noteOn", channel, key, velocity / 0x7F)
        return 2
    end,
    [0xA0] = function(stream, callback, channel, fb)
        local key = fb:byte()
        local pressure = read(stream, 1):byte()
        callback("keyPressure", channel, key, pressure / 0x7F)
        return 2
    end,
    [0xB0] = function(stream, callback, channel, fb)
        local number = fb:byte()
        local value = read(stream, 1):byte()
        if number < 120 then
            callback("controller", channel, number, value)
        else
            callback("modeMessage", channel, number, value)
        end
        return 2
    end,
    [0xC0] = function(_, callback, channel, fb)
        local program = fb:byte()
        callback("program", channel, program)
        return 1
    end,
    [0xD0] = function(_, callback, channel, fb)
        local pressure = fb:byte()
        callback("channelPressure", channel, pressure / 0x7F)
        return 1
    end,
    [0xE0] = function(stream, callback, channel, fb)
        local lsb = fb:byte()
        local msb = read(stream, 1):byte()
        callback("pitch", channel, (bit32.bor(lsb, bit32.lshift(msb, 7))) / 0x2000 - 1)
        return 2
    end
}

local function makeForwarder(name)
    return function(data, callback)
        callback(name, data)
    end
end

local metaEvents = {
    [0x00] = makeForwarder("sequenceNumber"),
    [0x01] = makeForwarder("text"),
    [0x02] = makeForwarder("copyright"),
    [0x03] = makeForwarder("sequencerOrTrackName"),
    [0x04] = makeForwarder("instrumentName"),
    [0x05] = makeForwarder("lyric"),
    [0x06] = makeForwarder("marker"),
    [0x07] = makeForwarder("cuePoint"),
    [0x20] = makeForwarder("channelPrefix"),
    [0x2F] = makeForwarder("endOfTrack"),
    [0x51] = function(data, callback)
        local b1, b2, b3 = string.byte(data, 1, 3)
        local rawTempo = bit32.bor(bit32.lshift(b1, 16), bit32.lshift(b2, 8), b3)
        callback("setTempo", rawTempo)
    end,
    [0x54] = makeForwarder("smpteOffset"),
    [0x58] = function(data, callback)
        local numerator, denominator, metronome, dotted = string.byte(data, 1, 4)
        callback("timeSignature", numerator, bit32.lshift(1, denominator), metronome, dotted)
    end,
    [0x59] = function(data, callback)
        local count, minor = string.byte(data, 1, 2)
        if count >= 128 then count = count - 256 end
        callback("keySignature", math.abs(count), count < 0 and "flat" or count > 0 and "sharp" or "C", minor == 0 and "major" or "minor")
    end,
    [0x7F] = makeForwarder("sequenceEvent")
}

local function metaEvent(stream, callback, fb)
    local event = fb:byte()
    local length, vlqLength = readVLQ(stream)
    local data = read(stream, length)
    local handler = metaEvents[event]
    if handler then
        handler(data, callback)
    end
    return 1 + vlqLength + length
end

local function readChunkInfo(stream)
    local chunkInfo = stream:read(8)
    if not chunkInfo or #chunkInfo < 8 then return false end
    local magic = chunkInfo:sub(1, 4)
    local len = string.unpack(">I4", chunkInfo:sub(5, 8))
    return magic, len
end

local function readHeader(stream, callback, chunkLength)
    local header = read(stream, chunkLength)
    local format, tracks, division = string.unpack(">I2I2I2", header)
    callback("header", format, tracks, division)
    return format, tracks
end

local function processEvent(stream, callback, runningStatus)
    local firstByte = stream:read(1)
    if not firstByte then error("missing event") end
    local status = firstByte:byte()
    local length = 0

    if status < 0x80 then
        status = runningStatus
        if not status then error("no running status") end
    elseif status < 0xF0 then
        firstByte = read(stream, 1)
        length = 1
        runningStatus = status
    else
        runningStatus = nil
        if status == 0xF0 or status == 0xF7 then
            local dataLen, vlqLen = readVLQ(stream)
            local data = read(stream, dataLen)
            callback("sysexEvent", data, status)
            return 1 + vlqLen + dataLen, runningStatus
        elseif status == 0xF2 then
            read(stream, 2)
            return 3, runningStatus
        elseif status == 0xF3 then
            read(stream, 1)
            return 2, runningStatus
        elseif status == 0xFF then
            local metaType = read(stream, 1)
            return 1 + metaEvent(stream, callback, metaType), runningStatus
        else
            callback("ignore", status)
            return 1, runningStatus
        end
    end

    local handler = midiEvent[bit32.band(status, 0xF0)]
    if handler then
        length = length + handler(stream, callback, bit32.band(status, 0x0F) + 1, firstByte)
    end
    return length, runningStatus
end

local function readTrack(stream, callback, chunkLength, track)
    callback("track", track)
    local chunkEnd = stream:seek("cur", 0) + chunkLength
    local runningStatus
    local ended = false

    local function trackCallback(name, ...)
        if name == "endOfTrack" then
            ended = true
        end
        callback(name, ...)
    end

    while not ended and stream:seek("cur", 0) < chunkEnd do
        local ticks = readVLQ(stream)
        if ticks > 0 then trackCallback("deltatime", ticks) end
        local _, nextRunningStatus = processEvent(stream, trackCallback, runningStatus)
        runningStatus = nextRunningStatus
    end
    stream:seek("set", chunkEnd)
end

local function processMidi(stream, callback)
    local tracks
    local track = 0
    while true do
        local chunkType, chunkLength = readChunkInfo(stream)
        if not chunkType then break end
        if chunkType == "MThd" then
            local _, trackCount = readHeader(stream, callback, chunkLength)
            tracks = trackCount
        elseif chunkType == "MTrk" then
            track = track + 1
            readTrack(stream, callback, chunkLength, track)
        else
            stream:seek("cur", chunkLength)
        end
    end
    return tracks
end

-- ==========================================
-- Virtual Piano Key Mapping & Input
-- ==========================================
local keys = "1!2@34$5%6^78*9(0qQwWeErtTyYuiIoOpPasSdDfgGhHjJklLzZxcCvVbBnm"

local digitKeyCodes = {
    ["1"] = Enum.KeyCode.One,   ["2"] = Enum.KeyCode.Two,
    ["3"] = Enum.KeyCode.Three, ["4"] = Enum.KeyCode.Four,
    ["5"] = Enum.KeyCode.Five,  ["6"] = Enum.KeyCode.Six,
    ["7"] = Enum.KeyCode.Seven, ["8"] = Enum.KeyCode.Eight,
    ["9"] = Enum.KeyCode.Nine,  ["0"] = Enum.KeyCode.Zero,
}

local shiftSymbolToDigit = {
    ["!"] = "1", ["@"] = "2", ["#"] = "3", ["$"] = "4", ["%"] = "5",
    ["^"] = "6", ["&"] = "7", ["*"] = "8", ["("] = "9", [")"] = "0",
}

local CharToKeyInfo = {}
local KeyToChars = {}

local physicalKeys = keys .. "#&)"
for i = 1, #physicalKeys do
    local ch = physicalKeys:sub(i, i)
    local isUpper = ch:upper() == ch and ch:lower() ~= ch
    local mappedDigit = shiftSymbolToDigit[ch]
    local needsShift = isUpper or (mappedDigit ~= nil)
    local baseChar = mappedDigit or ch:upper()
    local keyEnum = digitKeyCodes[baseChar] or Enum.KeyCode[baseChar]

    CharToKeyInfo[ch] = {
        keyEnum = keyEnum,
        needsShift = needsShift,
    }
    if keyEnum then
        if not KeyToChars[keyEnum] then KeyToChars[keyEnum] = {} end
        table.insert(KeyToChars[keyEnum], ch)
    end
end

local layoutTools = {}

function layoutTools.parse(text)
    local first, sequence = text:match("^%s*(%d+)%s*:%s*(.-)%s*$")
    if not first then return nil, "Use a starting MIDI note, a colon, then keys. Example: 60:a.s.df" end
    first, sequence = tonumber(first), sequence:gsub("%s+", "")
    if first > 127 or #sequence == 0 or first + #sequence > 128 then
        return nil, "Layout pitches must stay between MIDI notes 0 and 127."
    end
    local map, used, count = {}, {}, 0
    for index = 1, #sequence do
        local char = sequence:sub(index, index)
        if char ~= "." then
            if not CharToKeyInfo[char] or not CharToKeyInfo[char].keyEnum then
                return nil, "Unsupported key: " .. char .. ". Use letters, digits, shifted digit symbols, or a dot for a gap."
            end
            if used[char] then return nil, "Each key must appear only once: " .. char end
            used[char] = true
            map[first + index - 1] = char
            count = count + 1
        end
    end
    if count == 0 then return nil, "Add at least one playable key." end
    return {first = first, last = first + #sequence - 1, map = map, count = count, spec = first .. ":" .. sequence}
end

layoutTools.default = assert(layoutTools.parse("36:" .. keys))

function layoutTools.soundcheck(layout)
    local first, plain, shifted
    local chord, used = {}, {}
    for pitch = layout.first, layout.last do
        local char = layout.map[pitch]
        if char then
            local info = CharToKeyInfo[char]
            first = first or char
            if info.needsShift then shifted = shifted or char else plain = plain or char end
            if #chord < 3 and not used[info.keyEnum] then
                used[info.keyEnum] = true
                table.insert(chord, char)
            end
        end
    end
    return "----" .. (plain or first) .. " " .. (shifted or chord[2] or first)
        .. " [" .. table.concat(chord) .. "] " .. chord[#chord] .. "~~~~"
end

local keyPressId = {}
local keyHeld = {}

local function releaseKey(key)
    if keyHeld[key] then
        VirtualInputManager:SendKeyEvent(false, key, false, game)
        keyHeld[key] = nil
    end
end

local function pressChar(char)
    local info = CharToKeyInfo[char]
    local key = info and info.keyEnum
    if not key then return end

    local pressId = (keyPressId[key] or 0) + 1
    keyPressId[key] = pressId
    releaseKey(key)

    local shift = Enum.KeyCode.LeftShift
    if info.needsShift then
        keyHeld[shift] = true
        VirtualInputManager:SendKeyEvent(true, shift, false, game)
    end
    keyHeld[key] = true
    VirtualInputManager:SendKeyEvent(true, key, false, game)
    if info.needsShift then releaseKey(shift) end
    return key, pressId
end

local function playChar(char)
    local key, pressId = pressChar(char)
    if not key then return end
    task.delay(0.02, function()
        if keyPressId[key] == pressId then releaseKey(key) end
    end)
end

local heldNotes = {}
local keyOwners = {}

local function syncHeldKey(key, retrigger)
    local previous = keyOwners[key]
    local owner = previous and heldNotes[previous] and previous or nil
    if not owner then
        -- Two characters sharing a physical key can't be held simultaneously.
        -- Keep the current owner until it ends, then give the key to any remaining note.
        for _, char in ipairs(KeyToChars[key]) do
            if heldNotes[char] then
                owner = char
                break
            end
        end
    end
    if owner then
        if owner ~= previous or not keyHeld[key] or retrigger then pressChar(owner) end
    else
        releaseKey(key)
    end
    keyOwners[key] = owner
end

local function updateHeldNote(char, change, dirtyKeys)
    local key = CharToKeyInfo[char].keyEnum
    if not key then return end
    local count = (heldNotes[char] or 0) + change
    heldNotes[char] = count > 0 and count or nil
    dirtyKeys[key] = dirtyKeys[key] or (count == 0 and keyOwners[key] == char)
end

-- ==========================================
-- Playback Timelines & Transport
-- ==========================================
local function getMidiChar(note, foldOctaves, layout)
    layout = layout or layoutTools.default
    local direct = layout.map[note]
    if direct or not foldOctaves then return direct end
    local best, distance = nil, math.huge
    local firstOctave = layout.first + (note - layout.first) % 12
    for candidate = firstOctave, layout.last, 12 do
        local delta = math.abs(candidate - note)
        if layout.map[candidate] and delta < distance then
            best, distance = layout.map[candidate], delta
        end
    end
    return best
end

local function chooseOctaveShift(pitches, transpose, layout)
    layout = layout or layoutTools.default
    local bestShift, bestCount, bestDistance = 0, -1, math.huge
    for octave = -13, 13 do
        local shift = octave * 12
        local count, distance = 0, 0
        for pitch, occurrences in pairs(pitches) do
            local mapped = pitch + transpose + shift
            if layout.map[mapped] then
                count = count + occurrences
            elseif mapped < layout.first then
                distance = distance + (layout.first - mapped) * occurrences
            elseif mapped > layout.last then
                distance = distance + (mapped - layout.last) * occurrences
            end
        end
        -- Favor the original register on ties; only break equally distant shifts by overflow.
        if count > bestCount or (count == bestCount and (math.abs(shift) < math.abs(bestShift)
            or (math.abs(shift) == math.abs(bestShift) and distance < bestDistance))) then
            bestShift, bestCount, bestDistance = shift, count, distance
        end
    end
    return bestShift
end

local function buildMidiTimeline(midiString, options, holdKeys)
    local followPedal = holdKeys and options.followPedal
    local transpose = options.transpose or 0
    local activeLayout = options.layout or layoutTools.default
    local soloChannel = options.channel or 0
    local function acceptsChannel(channel)
        if soloChannel > 0 then return channel == soloChannel end
        return not options.skipDrums or channel ~= 10
    end
    local headerIndex = type(midiString) == "string" and midiString:find("MThd", 1, true)
    if not headerIndex then error("Missing MIDI header") end

    local division
    local tick, endTick = 0, 0
    local raw, pitches, availableChannels = {}, {}, {}
    local noteCount = 0
    processMidi(createStringStream(midiString:sub(headerIndex)), function(name, ...)
        if name == "header" then
            local format, _, timing = ...
            if format ~= 0 and format ~= 1 then error("Only MIDI formats 0 and 1 are supported") end
            division = timing
        elseif name == "track" then
            tick = 0
        elseif name == "deltatime" then
            local delta = ...
            tick = tick + delta
            endTick = math.max(endTick, tick)
        elseif name == "noteOn" or (holdKeys and name == "noteOff") then
            local channel, note, velocity = ...
            local down = name == "noteOn" and velocity > 0
            if down then availableChannels[channel] = true end
            if not acceptsChannel(channel) then return end
            if down then
                pitches[note] = (pitches[note] or 0) + 1
                noteCount = noteCount + 1
            end
            if down or holdKeys then
                table.insert(raw, {
                    tick = tick, order = #raw + 1, channel = channel, voice = note, down = down,
                })
            end
        elseif followPedal and name == "controller" then
            local channel, controller, value = ...
            if controller == 64 and acceptsChannel(channel) then
                table.insert(raw, {tick = tick, order = #raw + 1, channel = channel, pedal = value >= 64})
            end
        elseif name == "setTempo" then
            local tempo = ...
            if tempo > 0 then
                table.insert(raw, {tick = tick, order = #raw + 1, tempo = tempo})
            end
        end
    end)
    if not division or division == 0 then error("Invalid MIDI timing division") end

    local fixedSecondsPerTick
    if bit32.btest(division, 0x8000) then
        local fps = 256 - bit32.rshift(division, 8)
        local ticksPerFrame = bit32.band(division, 0xFF)
        if (fps ~= 24 and fps ~= 25 and fps ~= 29 and fps ~= 30) or ticksPerFrame == 0 then
            error("Invalid MIDI SMPTE timing")
        end
        fixedSecondsPerTick = 1 / ((fps == 29 and 30000 / 1001 or fps) * ticksPerFrame)
    end

    local octaveShift = options.autoFit and chooseOctaveShift(pitches, transpose, activeLayout) or 0
    local mappedCount = 0
    table.sort(raw, function(a, b)
        if a.tick == b.tick then return a.order < b.order end
        return a.tick < b.tick
    end)

    local events, seen, channels = {}, {}, {}
    local seconds, lastTick = 0, 0
    local secondsPerTick = fixedSecondsPerTick or 0.5 / division
    local function addHold(char, change)
        table.insert(events, {time = seconds, char = char, change = change})
    end
    local keyByPitch = {}
    for pitch in pairs(pitches) do
        keyByPitch[pitch] = getMidiChar(pitch + transpose + octaveShift, options.foldOctaves, activeLayout)
    end
    for _, event in ipairs(raw) do
        if event.tick ~= lastTick then
            seconds = seconds + (event.tick - lastTick) * secondsPerTick
            lastTick = event.tick
            table.clear(seen)
        end
        local char = event.voice and keyByPitch[event.voice]
        if event.down and char then mappedCount = mappedCount + 1 end
        if event.tempo then
            if not fixedSecondsPerTick then secondsPerTick = event.tempo / 1000000 / division end
        elseif holdKeys and (char or event.pedal ~= nil) then
            local channel = channels[event.channel]
            if not channel then
                channel = {active = {}, sustained = {}, pedalDown = false}
                channels[event.channel] = channel
            end
            if event.pedal ~= nil then
                channel.pedalDown = event.pedal
                if not event.pedal then
                    for _, char in pairs(channel.sustained) do addHold(char, -1) end
                    table.clear(channel.sustained)
                end
            else
                -- Track original pitches before folding so a note-off only ends its own voice.
                local note = event.voice
                local count = channel.active[note] or 0
                if event.down then
                    if channel.sustained[note] then
                        -- A repeated note needs a fresh key-down even with the pedal pressed.
                        addHold(char, -1)
                        channel.sustained[note] = nil
                    end
                    channel.active[note] = count + 1
                    addHold(char, 1)
                elseif count > 0 then
                    channel.active[note] = count > 1 and count - 1 or nil
                    if count == 1 and channel.pedalDown then
                        channel.sustained[note] = char
                    else
                        addHold(char, -1)
                    end
                end
            end
        elseif not holdKeys and char and not seen[char] then
            seen[char] = true
            table.insert(events, {time = seconds, char = char})
        end
    end
    local summary = string.format("Pitch shift: %+d st · %d/%d notes in range", transpose + octaveShift,
        mappedCount, noteCount)
    local channelList = {}
    for channel = 1, 16 do
        if availableChannels[channel] then table.insert(channelList, tostring(channel)) end
    end
    if #channelList > 0 then summary = summary .. " · MIDI ch: " .. table.concat(channelList, ", ") end
    return events, seconds + (endTick - lastTick) * secondsPerTick, summary
end

local function buildSheetTimeline(sheet, bpm, holdKeys)
    local events = {}
    local step = 60 / bpm / 2
    local time, i = 0, 1
    local function addNote(char)
        table.insert(events, {time = time, char = char, change = holdKeys and 1 or nil})
    end
    local function extendNote()
        while sheet:sub(i, i) == "~" do
            time = time + step
            i = i + 1
        end
    end
    local function endNote(char)
        if holdKeys then table.insert(events, {time = time, char = char, change = -1}) end
    end
    while i <= #sheet do
        local char = sheet:sub(i, i)
        local close = char == "[" and sheet:find("]", i + 1, true)
        if close then
            local group = sheet:sub(i + 1, close - 1)
            local rolled = group:find(" ", 1, true) ~= nil
            local seen, notes = {}, {}
            for j = 1, #group do
                local note = group:sub(j, j)
                if CharToKeyInfo[note] and (rolled or not seen[note]) then
                    addNote(note)
                    table.insert(notes, note)
                    seen[note] = true
                    if rolled then time = time + math.min(step * 0.35, 0.06) end
                end
            end
            time = time + (rolled and step * 0.5 or step)
            i = close + 1
            extendNote()
            for _, note in ipairs(notes) do endNote(note) end
        else
            i = i + 1
            if CharToKeyInfo[char] then
                addNote(char)
                time = time + step
                extendNote()
                endNote(char)
            elseif char == " " or char == "-" or char == "|" or char == "\n" then
                time = time + step
            end
        end
    end
    return events, time
end

local currentPlaybackSpeed = 1
local loopPlayback = false
local holdPlaybackKeys = true
local midiSettings = {
    foldOctaves = false, followPedal = true, skipDrums = true, transpose = 0, autoFit = true,
    channel = 0, layout = layoutTools.default,
}
local playbackId = 0
local state, title = "Ready", ""
local position, duration, lastClock = 0, 0, 0
local practiceStart, practiceEnd, seekTarget
local songSummary = ""
local updatePlaybackUI = function() end
local showPlaybackError = function() end
local restoreHeldKeys = false
local fixedPlaybackSpeed

local function isPlaybackBusy()
    return state == "Loading" or state == "Cueing" or state == "Playing" or state == "Paused"
end

local function textEntryActive()
    return UserInputService:GetFocusedTextBox() ~= nil
end

local function releaseKeys()
    for key in pairs(keyHeld) do
        local ok, err = pcall(releaseKey, key)
        if not ok then
            keyHeld[key] = nil
            warn("[Piano] Could not release key:", err)
        end
    end
end

local function clearHeldNotes()
    restoreHeldKeys = false
    table.clear(heldNotes)
    table.clear(keyOwners)
    releaseKeys()
end

local function advancePlaybackClock()
    local now = os.clock()
    if state == "Playing" then position = position + (now - lastClock) * (fixedPlaybackSpeed or currentPlaybackSpeed) end
    lastClock = now
    return now
end

local function clearPractice()
    practiceStart, practiceEnd = nil, nil
end

local function requestSeek(seconds)
    if state ~= "Playing" and state ~= "Paused" then return end
    local target = math.clamp(seconds, 0, duration)
    if practiceEnd and (target < practiceStart or target >= practiceEnd) then clearPractice() end
    seekTarget = target
end

local function beginPlayback(songTitle)
    if isPlaybackBusy() then return nil end
    playbackId = playbackId + 1
    state, title = "Loading", songTitle
    fixedPlaybackSpeed = nil
    position, duration, songSummary, seekTarget = 0, 0, "", nil
    clearPractice()
    updatePlaybackUI()
    return playbackId
end

local function stopPlayback()
    playbackId = playbackId + 1
    state, title = "Ready", ""
    position, duration, songSummary, seekTarget = 0, 0, "", nil
    clearPractice()
    clearHeldNotes()
    updatePlaybackUI()
end

local function togglePause()
    advancePlaybackClock()
    if state == "Playing" then
        state = "Paused"
        releaseKeys()
    elseif state == "Paused" then
        if textEntryActive() then return end
        -- Apply any releases due at this position before restoring held notes.
        state = "Playing"
        restoreHeldKeys = true
    else
        return
    end
    updatePlaybackUI()
end

local function failPlayback(myId, message)
    if myId ~= playbackId then return end
    state = "Playback failed"
    clearHeldNotes()
    updatePlaybackUI()
    showPlaybackError(message)
end

local function restoreActiveKeys()
    for char in pairs(heldNotes) do
        local key = CharToKeyInfo[char].keyEnum
        if key then syncHeldKey(key) end
    end
end

local function runTimeline(events, totalSeconds, summary, holdKeys, myId, oneShot)
    if myId ~= playbackId then return end
    if #events == 0 then
        songSummary = summary or ""
        failPlayback(myId, "No playable notes. Check the keyboard layout, octave folding, or MIDI channel settings.")
        return
    end
    state, position, duration, songSummary = "Playing", 0, totalSeconds, summary or ""
    fixedPlaybackSpeed = oneShot and 1 or nil
    lastClock = os.clock()
    local nextEvent, nextUI = 1, lastClock + 0.2
    local lastFrame = lastClock
    local dirtyKeys = {}
    local function flushKeys()
        for key, retrigger in pairs(dirtyKeys) do syncHeldKey(key, retrigger) end
        table.clear(dirtyKeys)
    end
    local checkpointTime, checkpointIndex, checkpointNotes
    local function jumpTo(target)
        clearHeldNotes()
        position = target
        if target == checkpointTime then
            nextEvent = checkpointIndex
            for char, count in pairs(checkpointNotes) do heldNotes[char] = count end
        else
            nextEvent = 1
            -- Rebuild silently, then cache the state so repeated A–B loops don't rescan the song.
            while nextEvent <= #events and events[nextEvent].time < target do
                if holdKeys then
                    local event = events[nextEvent]
                    updateHeldNote(event.char, event.change, dirtyKeys)
                end
                nextEvent = nextEvent + 1
            end
            table.clear(dirtyKeys)
            checkpointTime, checkpointIndex, checkpointNotes = target, nextEvent, table.clone(heldNotes)
        end
        restoreHeldKeys = holdKeys and target < duration
    end
    updatePlaybackUI()

    while myId == playbackId do
        local now = advancePlaybackClock()
        local stalled = now - lastFrame > 0.2
        lastFrame = now
        if state == "Playing" and textEntryActive() then
            state = "Paused"
            releaseKeys()
            updatePlaybackUI()
        end
        if seekTarget then
            jumpTo(seekTarget)
            stalled = false
            seekTarget = nil
            updatePlaybackUI()
        end
        if state == "Playing" then
            if not oneShot and practiceEnd and position >= practiceEnd then
                jumpTo(practiceStart)
                stalled = false
                updatePlaybackUI()
            end
            if stalled then
                -- Don't replay a backlog of expired taps/notes when the client misses frames.
                -- Rebuild held state through the rough patch, then play the newest taps normally.
                local cutoff = holdKeys and position or position - 0.1 * (fixedPlaybackSpeed or currentPlaybackSpeed)
                while nextEvent <= #events do
                    local event = events[nextEvent]
                    if event.time > cutoff or (not holdKeys and event.time == cutoff) then break end
                    if holdKeys then updateHeldNote(event.char, event.change, dirtyKeys) end
                    nextEvent = nextEvent + 1
                end
                if holdKeys and position >= duration then
                    clearHeldNotes()
                    table.clear(dirtyKeys)
                end
            end
            while nextEvent <= #events and events[nextEvent].time <= position do
                local event = events[nextEvent]
                if holdKeys then
                    -- Reconcile simultaneous changes together so a chord release
                    -- cannot briefly press a second note sharing the same key.
                    local time = event.time
                    repeat
                        updateHeldNote(event.char, event.change, dirtyKeys)
                        nextEvent = nextEvent + 1
                        event = events[nextEvent]
                    until not event or event.time ~= time
                    flushKeys()
                else
                    playChar(event.char)
                    nextEvent = nextEvent + 1
                end
            end
            if holdKeys and next(dirtyKeys) then flushKeys() end
            if restoreHeldKeys then
                restoreHeldKeys = false
                restoreActiveKeys()
            end
            if nextEvent > #events and position >= duration then
                if holdKeys and next(heldNotes) then clearHeldNotes() end
                if oneShot or not loopPlayback then
                    state, position = "Finished", duration
                    updatePlaybackUI()
                    return
                elseif position >= duration + 0.25 then
                    -- Give the final keypress time to release, even on very short sheets.
                    position, nextEvent = 0, 1
                end
            end
            if now >= nextUI then
                updatePlaybackUI()
                nextUI = now + 0.2
            end
        end
        task.wait()
    end
end

local function prepareAndPlay(builder, source, option, holdKeys, myId, oneShot)
    if myId ~= playbackId then return end
    local ok, events, totalSeconds, summary = pcall(builder, source, option, holdKeys)
    if not ok then
        failPlayback(myId, tostring(events))
        return
    end
    local played, err = pcall(runTimeline, events, totalSeconds, summary, holdKeys, myId, oneShot)
    if not played then failPlayback(myId, tostring(err)) end
end

-- ==========================================
-- Rayfield UI
-- ==========================================
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
    Name = "🎹 Universal Piano",
    LoadingTitle = "Loading Notes...",
    LoadingSubtitle = "by Swazi",
    ToggleUIKeybind = Enum.KeyCode.Quote,
    ConfigurationSaving = {Enabled = false},
    KeySystem = false
})

local StageTab = Window:CreateTab("Stage", 4483362458)
local QuickTab = Window:CreateTab("Quick Picks & URL", 4483362458)
local PlaybackTab = Window:CreateTab("Playback", 4483362458)
local LocalTab = Window:CreateTab("Local & Sheets", 4483362458)
local NanoTab = Window:CreateTab("NanoMIDI API", 4483362458)

-- ==========================================
-- HTTP & URL Helpers
-- ==========================================
local httpRequest = request or http_request or (syn and syn.request) or (http and http.request)

local nanoHeaders = {
    ["Accept"] = "application/json, */*",
    ["Origin"] = "https://nanomidi.net",
    ["Referer"] = "https://nanomidi.net/",
}

local function normalizeMidiUrl(url)
    local clean = tostring(url or ""):match("^%s*(.-)%s*$")
    clean = clean:gsub("^https?://github%.com/([^/]+)/([^/]+)/blob/(.+)$", "https://raw.githubusercontent.com/%1/%2/%3")
    clean = clean:gsub("^https?://github%.com/([^/]+)/([^/]+)/raw/(.+)$", "https://raw.githubusercontent.com/%1/%2/%3")
    clean = clean:gsub(" ", "%%20")
    return clean
end

local function safeRequest(url, customHeaders)
    local headers = {
        ["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
        ["Accept"] = "*/*",
    }
    if customHeaders then
        for k, v in pairs(customHeaders) do
            headers[k] = v
        end
    end

    if httpRequest then
        local ok, res = pcall(httpRequest, {
            Url = url,
            Method = "GET",
            Headers = headers,
        })
        if not ok then
            return false, nil, tostring(res)
        end
        if type(res) ~= "table" then
            return false, nil, "Unexpected response type: " .. type(res)
        end
        return true, res, nil
    end

    local getOk, body = pcall(game.HttpGet, game, url)
    if getOk and type(body) == "string" then
        return true, {StatusCode = 200, Body = body}, nil
    end
    return false, nil, "Executor does not support request() or HttpGet failed"
end

local function isMidiUrl(url)
    return url:match("^https?://[^/%s?#]+") ~= nil
end

local function fetchMidiBytes(url, headers)
    local ok, res, err = safeRequest(url, headers)
    if not ok then return nil, "Download failed: " .. tostring(err) end
    local status = res.StatusCode or res.status_code
    if status ~= 200 then return nil, "Download failed (HTTP " .. tostring(status) .. ")." end
    if type(res.Body) ~= "string" then return nil, "The download did not return MIDI data." end
    return res.Body
end

local function downloadAndPlayUrl(rawUrl, songTitle, customHeaders)
    if isPlaybackBusy() then return end
    local url = normalizeMidiUrl(rawUrl)
    if not isMidiUrl(url) then
        Rayfield:Notify({
            Title = "Invalid URL",
            Content = "Enter or select a direct HTTP(S) link to a MIDI file.",
            Duration = 3,
        })
        return
    end

    local myId = beginPlayback(songTitle)
    local options, holdKeys = table.clone(midiSettings), holdPlaybackKeys
    task.spawn(function()
        local data, err = fetchMidiBytes(url, customHeaders)
        if myId ~= playbackId then return end
        if not data then
            failPlayback(myId, err)
            return
        end
        prepareAndPlay(buildMidiTimeline, data, options, holdKeys, myId)
    end)
end

-- ==========================================
-- Stage: session setlist and one-entry preload
-- ==========================================
local setlist, setlistLabels = {}, {}
local nextSetlistId = 0
local maxQueueSize = 50
local selectedSetlistEntry, stageSlot, lastStageSlot
local stageHotkeys = false
local stageLeadIn, cueSecondsLeft = 0, 0
local setlistDropdown
local stageNowPlaying = StageTab:CreateLabel("Ready · No song selected")
local stageNext = StageTab:CreateLabel("Next: none")
local stageEncore = StageTab:CreateLabel("Encore: none")
local stageAnalysis = StageTab:CreateLabel("Preflight: no MIDI analysis")
local stageMixLabel = StageTab:CreateLabel("Selected song: global MIDI settings")
local emptySetlist = "No songs queued"

local function refreshStageNext()
    local head = setlist[1]
    local summary = stageSlot and stageSlot.prepared and stageSlot.prepared.summary
    stageAnalysis:Set(summary or "Preflight: no MIDI analysis")
    if not head then
        stageNext:Set("Next: none")
        return
    end
    local status = stageSlot and stageSlot.status or "Not preloaded"
    stageNext:Set(string.format("Next: %s · %s · %d queued", head.name, status, #setlist))
end

local function refreshSetlist()
    if stageSlot and stageSlot.entry ~= setlist[1] then stageSlot = nil end
    table.clear(setlistLabels)
    local labels, selection = {}, nil
    for _, entry in ipairs(setlist) do
        local label = string.format("#%d · %s", entry.id, entry.name)
        table.insert(labels, label)
        setlistLabels[label] = entry
        if entry == selectedSetlistEntry then selection = label end
    end
    if #labels == 0 then labels[1] = emptySetlist end
    setlistDropdown:Refresh(labels)
    setlistDropdown:Set({selection or labels[1]})
    refreshStageNext()
end

local function setlistNotice(titleText, message)
    Rayfield:Notify({Title = titleText, Content = message, Duration = 4})
end

local function appendQueuedSong(entry)
    nextSetlistId = nextSetlistId + 1
    entry.id = nextSetlistId
    table.insert(setlist, entry)
end

local function queueSong(entry)
    if #setlist >= maxQueueSize then
        setlistNotice("Setlist Full", "Remove a song before adding another (50-song limit).")
        return
    end
    appendQueuedSong(entry)
    refreshSetlist()
end

local function queueMidiUrl(rawUrl, name, headers)
    local url = normalizeMidiUrl(rawUrl)
    if not isMidiUrl(url) then
        setlistNotice("No MIDI Link Selected", "Select a song or enter a direct HTTP(S) MIDI link first.")
        return
    end
    local path = url:match("^[^?#]+") or url
    local label = name or path:match("/([^/]+)%.midi?$") or "Direct MIDI URL"
    queueSong({name = label, kind = "url", source = url, headers = headers})
end

local function readQueuedSong(entry)
    if entry.kind == "url" then
        return fetchMidiBytes(entry.source, entry.headers)
    elseif entry.kind == "file" then
        if not readfile then return nil, "This runtime cannot read local MIDI files." end
        local ok, data = pcall(readfile, entry.source)
        if not ok or type(data) ~= "string" then return nil, "Could not read the selected MIDI file." end
        return data
    end
    return entry.source
end

local function buildQueuedSong(entry, data, options, holdKeys)
    local builder = entry.kind == "sheet" and buildSheetTimeline or buildMidiTimeline
    local option = entry.kind == "sheet" and entry.bpm or options
    local ok, events, seconds, summary = pcall(builder, data, option, holdKeys)
    if not ok then return nil, tostring(events) end
    if #events == 0 then
        return nil, "No playable notes with the current settings." .. (summary and " " .. summary or "")
    end
    return {events = events, seconds = seconds, summary = summary, options = options, holds = holdKeys}
end

local function settingsMatch(prepared, entry, options, holdKeys)
    if prepared.holds ~= holdKeys then return false end
    if entry.kind == "sheet" then return true end
    for key, value in pairs(options) do
        if prepared.options[key] ~= value then return false end
    end
    return true
end

local mixToggles = {"autoFit", "foldOctaves", "followPedal", "skipDrums"}

local function cleanSongMix(value)
    if type(value) ~= "table" or type(value.holds) ~= "boolean"
        or type(value.transpose) ~= "number" or value.transpose % 1 ~= 0 or math.abs(value.transpose) > 24
        or type(value.channel) ~= "number" or value.channel % 1 ~= 0 or value.channel < 0 or value.channel > 16 then
        return nil
    end
    local cleaned = {holds = value.holds, transpose = value.transpose, channel = value.channel}
    for _, field in ipairs(mixToggles) do
        if type(value[field]) ~= "boolean" then return nil end
        cleaned[field] = value[field]
    end
    return cleaned
end

local function getSongSettings(entry)
    local options, holdKeys = table.clone(midiSettings), holdPlaybackKeys
    if entry.mix then
        for key, value in pairs(entry.mix) do
            if key == "holds" then holdKeys = value else options[key] = value end
        end
    end
    -- The keyboard layout belongs to the current experience, not to a song.
    return options, holdKeys
end

local function refreshSelectedMix()
    local entry = selectedSetlistEntry
    if not entry or entry.kind == "sheet" then
        stageMixLabel:Set("Select a queued MIDI to pin note settings")
    elseif entry.mix then
        local mix = entry.mix
        local channel = mix.channel == 0 and "all channels" or "ch " .. mix.channel
        stageMixLabel:Set(string.format("Selected song: pinned · %+d st · %s · %s", mix.transpose, channel,
            mix.holds and "hold" or "tap"))
    else
        stageMixLabel:Set("Selected song: global MIDI settings")
    end
end

local function preloadNext(reportError)
    local entry = setlist[1]
    if not entry then return nil end
    local options, holdKeys = getSongSettings(entry)
    local cached
    if stageSlot then
        local sameOptions = settingsMatch(stageSlot, entry, options, holdKeys)
        if stageSlot.status == "Loading" or (stageSlot.status == "Ready" and sameOptions) then
            if reportError then stageSlot.reportError = true end
            return stageSlot
        end
        if not sameOptions then cached = stageSlot.data end
    end
    local slot = {entry = entry, status = "Loading", reportError = reportError, options = options, holds = holdKeys}
    stageSlot = slot
    refreshStageNext()
    task.spawn(function()
        local data, err = cached, nil
        if not data then data, err = readQueuedSong(entry) end
        if stageSlot ~= slot then return end
        if data then
            slot.data = data
            slot.prepared, err = buildQueuedSong(entry, data, options, holdKeys)
        end
        slot.error = err
        slot.status = slot.prepared and "Ready" or "Failed"
        refreshStageNext()
        if slot.reportError and err then setlistNotice("Preload Failed", err) end
    end)
    return slot
end

local function playStageSlot(slot, fromQueue)
    local id = beginPlayback(slot.entry.name)
    if not id then return end
    local options, holdKeys = getSongSettings(slot.entry)
    local leadIn = stageLeadIn
    local function cueIsCurrent()
        return id == playbackId and (not fromQueue or stageSlot == slot)
    end
    local function cancelStaleCue()
        if id == playbackId then stopPlayback() end
    end
    task.spawn(function()
        while cueIsCurrent() and slot.status == "Loading" do task.wait() end
        if not cueIsCurrent() then cancelStaleCue(); return end

        local prepared, err = slot.prepared, slot.error
        if slot.data and (not prepared or not settingsMatch(prepared, slot.entry, options, holdKeys)) then
            prepared, err = buildQueuedSong(slot.entry, slot.data, options, holdKeys)
            slot.prepared, slot.error = prepared, err
            slot.options, slot.holds = options, holdKeys
            slot.status = prepared and "Ready" or "Failed"
            if fromQueue then refreshStageNext() end
        end
        if not prepared then
            failPlayback(id, err or "The song could not be loaded.")
            return
        end
        if leadIn > 0 then
            local startsAt = os.clock() + leadIn
            state, cueSecondsLeft = "Cueing", leadIn
            updatePlaybackUI()
            while cueIsCurrent() do
                local timeLeft = startsAt - os.clock()
                if timeLeft <= 0 then break end
                local seconds = math.ceil(timeLeft)
                if seconds ~= cueSecondsLeft then
                    cueSecondsLeft = seconds
                    updatePlaybackUI()
                end
                task.wait(math.min(timeLeft, 0.05))
            end
            if not cueIsCurrent() then cancelStaleCue(); return end
        end
        if fromQueue then
            table.remove(setlist, 1)
            refreshSetlist()
            lastStageSlot = slot
            stageEncore:Set("Encore: " .. slot.entry.name)
        end
        local ok, playbackError = pcall(runTimeline, prepared.events, prepared.seconds, prepared.summary, holdKeys, id)
        if not ok then failPlayback(id, tostring(playbackError)) end
    end)
end

local function canCueStageSong()
    if not isPlaybackBusy() then return true end
    setlistNotice("Playback Busy", "Finish or stop the current song before cueing another one.")
    return false
end

local function playNext()
    if not canCueStageSong() then return end
    local slot = preloadNext()
    if not slot then
        setlistNotice("Setlist Empty", "Queue a song from Quick Picks, Local & Sheets, or NanoMIDI first.")
        return
    end
    playStageSlot(slot, true)
end

local function playEncore()
    if not canCueStageSong() then return end
    if not lastStageSlot then
        setlistNotice("No Encore Yet", "Play a song from the Stage setlist first.")
        return
    end
    playStageSlot(lastStageSlot, false)
end

StageTab:CreateSection("On Stage")
StageTab:CreateButton({Name = "Play Next", Callback = playNext})
StageTab:CreateButton({Name = "Encore · Replay Last Stage Song", Callback = playEncore})
StageTab:CreateButton({Name = "Stop", Callback = stopPlayback})
StageTab:CreateButton({Name = "Pause / Resume", Callback = togglePause})
StageTab:CreateButton({
    Name = "Soundcheck · Active Keyboard Layout",
    Callback = function()
        local id = beginPlayback("Soundcheck")
        if not id then return end
        setlistNotice("Soundcheck", "Focus the piano now. Listen for the notes in your active layout.")
        local sheet = layoutTools.soundcheck(midiSettings.layout)
        task.spawn(prepareAndPlay, buildSheetTimeline, sheet, 120, true, id, true)
    end,
})

StageTab:CreateSlider({
    Name = "Cue Countdown",
    Range = {0, 5},
    Increment = 1,
    Suffix = " seconds",
    CurrentValue = stageLeadIn,
    Callback = function(value) stageLeadIn = value end,
})

StageTab:CreateToggle({
    Name = "Stage Hotkeys · F6 Next / F7 Pause / F8 Stop",
    CurrentValue = false,
    Callback = function(value) stageHotkeys = value end,
})

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not stageHotkeys then return end
    if input.KeyCode == Enum.KeyCode.F8 and isPlaybackBusy() then
        stopPlayback()
    elseif not gameProcessed and not textEntryActive() then
        if input.KeyCode == Enum.KeyCode.F6 then
            playNext()
        elseif input.KeyCode == Enum.KeyCode.F7 then
            togglePause()
        end
    end
end)

StageTab:CreateSection("Setlist · This Session")
setlistDropdown = StageTab:CreateDropdown({
    Name = "Queued Songs",
    Options = {emptySetlist},
    CurrentOption = {emptySetlist},
    MultipleOptions = false,
    Callback = function(option)
        local label = type(option) == "table" and option[1] or option
        selectedSetlistEntry = setlistLabels[label]
        refreshSelectedMix()
    end,
})

StageTab:CreateButton({
    Name = "Preload Next",
    Callback = function()
        if not preloadNext(true) then
            setlistNotice("Setlist Empty", "Queue a song to preload it.")
        end
    end,
})

StageTab:CreateButton({
    Name = "Pin Current MIDI Settings to Selected Song",
    Callback = function()
        local entry = selectedSetlistEntry
        if not entry or entry.kind == "sheet" then
            setlistNotice("No MIDI Selected", "Choose a queued MIDI song first.")
            return
        end
        local mix = table.clone(midiSettings)
        mix.holds = holdPlaybackKeys
        entry.mix = cleanSongMix(mix)
        refreshSelectedMix()
        if setlist[1] == entry and stageSlot then stageAnalysis:Set("Song settings changed · Preload Next to refresh") end
    end,
})

StageTab:CreateButton({
    Name = "Clear Selected Song Settings",
    Callback = function()
        local entry = selectedSetlistEntry
        if not entry or not entry.mix then return end
        entry.mix = nil
        refreshSelectedMix()
        if setlist[1] == entry and stageSlot then stageAnalysis:Set("Song settings changed · Preload Next to refresh") end
    end,
})

local function moveSelectedSong(offset)
    local index = selectedSetlistEntry and table.find(setlist, selectedSetlistEntry)
    if not index or not setlist[index + offset] then return end
    setlist[index], setlist[index + offset] = setlist[index + offset], setlist[index]
    refreshSetlist()
end

StageTab:CreateButton({Name = "Move Selected Up", Callback = function() moveSelectedSong(-1) end})
StageTab:CreateButton({Name = "Move Selected Down", Callback = function() moveSelectedSong(1) end})

StageTab:CreateButton({
    Name = "Shuffle Queue",
    Callback = function()
        if #setlist < 2 then return end
        for index = #setlist, 2, -1 do
            local swap = math.random(index)
            setlist[index], setlist[swap] = setlist[swap], setlist[index]
        end
        refreshSetlist()
    end,
})

StageTab:CreateButton({
    Name = "Remove Selected",
    Callback = function()
        local index = selectedSetlistEntry and table.find(setlist, selectedSetlistEntry)
        if not index then return end
        table.remove(setlist, index)
        refreshSetlist()
    end,
})

StageTab:CreateButton({
    Name = "Clear Setlist",
    Callback = function()
        table.clear(setlist)
        refreshSetlist()
    end,
})

-- Save reusable setlists as data, independently of the live playback queue.
local setlistFile = "piano-setlists-v1.json"
local maxSavedSets, maxSavedBytes = 20, 512 * 1024
local noSavedSets = "(No saved setlists)"
local savedSetName, selectedSavedSet = "", nil

local function validSetName(name)
    return type(name) == "string" and #name <= 32 and name:match("^[%w][%w _%-]*$") ~= nil
end

local function cleanSavedEntry(entry)
    if type(entry) ~= "table" or type(entry.name) ~= "string" or #entry.name == 0 or #entry.name > 200
        or type(entry.source) ~= "string" or #entry.source == 0 then return nil end
    local kind, source = entry.kind, entry.source
    if kind == "url" then
        if #source > 2048 or not isMidiUrl(source) or source:find("[%s%c]") then return nil end
    elseif kind == "file" then
        if #source > 512 or not source:lower():match("%.midi?$") or source:find("%c") then return nil end
    elseif kind == "sheet" then
        if #source > 32768 or not (type(entry.bpm) == "number" and entry.bpm >= 40 and entry.bpm <= 300) then
            return nil
        end
    else
        return nil
    end
    local mix
    if entry.mix ~= nil then
        if kind == "sheet" then return nil end
        mix = cleanSongMix(entry.mix)
        if not mix then return nil end
    end
    return {name = entry.name, kind = kind, source = source, bpm = kind == "sheet" and entry.bpm or nil, mix = mix}
end

local function readSavedSets()
    if type(readfile) ~= "function" then return nil, "This runtime does not support reading local files." end
    if type(isfile) == "function" then
        local checked, found = pcall(isfile, setlistFile)
        if checked and not found then return {} end
    end
    local readOk, body = pcall(readfile, setlistFile)
    if not readOk or type(body) ~= "string" then return nil, "Could not read the saved setlists file." end
    if #body > maxSavedBytes then return nil, "The saved setlists file is too large." end
    local decoded, document = pcall(HttpService.JSONDecode, HttpService, body)
    if not decoded or type(document) ~= "table" or document.version ~= 1 or type(document.sets) ~= "table" then
        return nil, "The saved setlists file is invalid or uses an unsupported version. It was not changed."
    end
    local result, count = {}, 0
    for name, entries in pairs(document.sets) do
        count = count + 1
        if not validSetName(name) or type(entries) ~= "table" or #entries == 0 or #entries > maxQueueSize
            or count > maxSavedSets then return nil, "The saved setlists file contains an invalid set." end
        local cleaned = {}
        for index, entry in pairs(entries) do
            if type(index) ~= "number" or index % 1 ~= 0 or index < 1 or index > #entries then
                return nil, "The saved setlists file contains an invalid song list."
            end
            cleaned[index] = cleanSavedEntry(entry)
        end
        for index = 1, #entries do
            if not cleaned[index] then return nil, "The saved setlists file contains an invalid song." end
        end
        result[name] = cleaned
    end
    return result
end

local function saveSets(sets)
    if type(writefile) ~= "function" then return false, "This runtime does not support writing local files." end
    local ok, body = pcall(HttpService.JSONEncode, HttpService, {version = 1, sets = sets})
    if not ok or type(body) ~= "string" then return false, "Could not serialize the setlists." end
    if #body > maxSavedBytes then return false, "The saved setlists file would be too large." end
    local written = pcall(writefile, setlistFile, body)
    if not written then return false, "Could not write the saved setlists file." end
    return true
end

StageTab:CreateSection("Saved Setlists · Local to This Runtime")
StageTab:CreateInput({
    Name = "New Setlist Name",
    CurrentValue = "",
    PlaceholderText = "e.g. Friday Set",
    RemoveTextAfterFocusLost = false,
    Callback = function(text) savedSetName = text:match("^%s*(.-)%s*$") end,
})

local savedSetDropdown = StageTab:CreateDropdown({
    Name = "Saved Setlists",
    Options = {noSavedSets},
    CurrentOption = {noSavedSets},
    MultipleOptions = false,
    Callback = function(option)
        local name = type(option) == "table" and option[1] or option
        selectedSavedSet = name ~= noSavedSets and name or nil
    end,
})

local function refreshSavedSets(sets, preferred)
    local names = {}
    for name in pairs(sets) do table.insert(names, name) end
    table.sort(names)
    if #names == 0 then names[1] = noSavedSets end
    savedSetDropdown:Refresh(names)
    savedSetDropdown:Set({preferred and sets[preferred] and preferred or names[1]})
end

-- Only initialize an empty first save when the runtime can confirm the file is absent.
local existingSavedSets = readSavedSets()
if existingSavedSets then refreshSavedSets(existingSavedSets) end

StageTab:CreateButton({
    Name = "Save Queue by Name",
    Callback = function()
        if not validSetName(savedSetName) then
            setlistNotice("Invalid Name", "Use up to 32 letters, numbers, spaces, dashes, or underscores; begin with a letter or number.")
            return
        end
        if #setlist == 0 then
            setlistNotice("Setlist Empty", "Queue a song before saving the setlist.")
            return
        end
        local entries = {}
        for index, entry in ipairs(setlist) do
            entries[index] = cleanSavedEntry(entry)
            if not entries[index] then
                setlistNotice("Cannot Save Setlist", "A song reference or text sheet exceeds the allowed size or format.")
                return
            end
        end
        local sets, err = readSavedSets()
        if not sets then setlistNotice("Cannot Save Setlist", err); return end
        local count = 0
        for _ in pairs(sets) do count = count + 1 end
        if not sets[savedSetName] and count >= maxSavedSets then
            setlistNotice("Cannot Save Setlist", "The saved setlist limit is 20. Reuse or delete an existing set first.")
            return
        end
        sets[savedSetName] = entries
        local ok, saveError = saveSets(sets)
        if not ok then setlistNotice("Cannot Save Setlist", saveError); return end
        refreshSavedSets(sets, savedSetName)
        setlistNotice("Setlist Saved", savedSetName)
    end,
})

StageTab:CreateButton({
    Name = "Load Saved Setlist (Replace Queue)",
    Callback = function()
        local sets, err = readSavedSets()
        if not sets then setlistNotice("Cannot Load Setlist", err); return end
        local entries = selectedSavedSet and sets[selectedSavedSet]
        if not entries then
            refreshSavedSets(sets)
            setlistNotice("No Saved Setlist Selected", "Pick a saved setlist first.")
            return
        end
        table.clear(setlist)
        for _, entry in ipairs(entries) do
            if entry.kind == "url" and entry.source:match("^https://api%.nanomidi%.net/api/midis/") then
                entry.headers = nanoHeaders
            end
            appendQueuedSong(entry)
        end
        refreshSetlist()
    end,
})

StageTab:CreateButton({
    Name = "Delete Saved Setlist",
    Callback = function()
        if not selectedSavedSet then return end
        local sets, err = readSavedSets()
        if not sets then setlistNotice("Cannot Delete Setlist", err); return end
        sets[selectedSavedSet] = nil
        local ok, saveError = saveSets(sets)
        if not ok then setlistNotice("Cannot Delete Setlist", saveError); return end
        refreshSavedSets(sets)
    end,
})

-- ==========================================
-- Tab 1: Quick Picks (GitHub Repo Sync) & Direct URL
-- ==========================================
QuickTab:CreateSection("Quick Picks (GitHub Repo)")

local repoFileUrl = QUICKPICKS_REPO_URL
local quickPickMap = {}
local quickPickOrder = {}
local selectedQuickPick = nil

local quickBrowser = {
    category = "All categories",
    categories = {"All categories", "Games", "Anime", "Film & TV", "Pop & Rock", "Classical", "Instrumental", "Other"},
    page = 1,
    pageSize = 40,
    query = {},
    favorites = {},
    favoritesOnly = false,
    favoriteFile = "piano-quick-pick-favorites-v1.json",
    entries = {},
    builtinCategories = {},
    accentMap = {},
}

for letter, accents in pairs({
    a = "ÀÁÂÃÄÅàáâãäåĀāĂăĄą", c = "ÇçĆćČč", d = "ÐðĎď", e = "ÈÉÊËèéêëĒēĖėĘęĚě",
    i = "ÌÍÎÏìíîïĪīİı", l = "Łł", n = "ÑñŃńŇň", o = "ÒÓÔÕÖØòóôõöøŌōŐő", r = "Řř",
    s = "ŚśŠš", t = "Ťť", u = "ÙÚÛÜùúûüŪūŮůŰű", y = "ÝŸýÿ", z = "ŹźŻżŽž", ae = "Ææ", oe = "Œœ", ss = "ßẞ",
}) do
    for char in accents:gmatch(utf8.charpattern) do quickBrowser.accentMap[char] = letter end
end

function quickBrowser.normalize(text)
    local lower = text:lower()
    return (lower:gsub(utf8.charpattern, quickBrowser.accentMap):gsub("\204[\128-\191]", ""):gsub("\205[\128-\175]", ""))
end

for _, song in ipairs(DEFAULT_QUICKPICKS) do quickBrowser.builtinCategories[song.name] = song.category end

function quickBrowser.loadFavorites()
    if type(readfile) ~= "function" then return end
    local ok, data = pcall(readfile, quickBrowser.favoriteFile)
    if not ok or type(data) ~= "string" or #data > 256 * 1024 then return end
    local valid, values = pcall(HttpService.JSONDecode, HttpService, data)
    if not valid or type(values) ~= "table" or values.version ~= 1 or type(values.titles) ~= "table" then return end
    table.clear(quickBrowser.favorites)
    for index, title in ipairs(values.titles) do
        if index > 1000 then break end
        if type(title) == "string" and #title <= 256 then quickBrowser.favorites[title] = true end
    end
end

function quickBrowser.saveFavorites()
    if type(writefile) ~= "function" then return false end
    local titles = {}
    for title in pairs(quickBrowser.favorites) do table.insert(titles, title) end
    table.sort(titles)
    local ok, data = pcall(HttpService.JSONEncode, HttpService, {version = 1, titles = titles})
    if not ok or type(data) ~= "string" or #data > 256 * 1024 then return false end
    return pcall(writefile, quickBrowser.favoriteFile, data)
end

local function setQuickPickEntries(entries)
    table.clear(quickPickMap)
    table.clear(quickPickOrder)
    table.clear(quickBrowser.entries)
    quickBrowser.page = 1

    for _, item in ipairs(entries) do
        local baseLabel = tostring(item.name or "Untitled")
        local label, suffix = baseLabel, 2
        while quickPickMap[label] do
            label = string.format("%s (%d)", baseLabel, suffix)
            suffix = suffix + 1
        end
        local category = item.category
        if not table.find(quickBrowser.categories, category) or category == "All categories" then
            category = quickBrowser.builtinCategories[baseLabel] or "Other"
        end
        quickPickMap[label] = normalizeMidiUrl(item.url)
        quickBrowser.entries[label] = {category = category, searchText = quickBrowser.normalize(label .. " " .. category)}
        table.insert(quickPickOrder, label)
    end
end

local function parseQuickPickFile(body)
    local list = {}
    local trimmed = body:match("^%s*(.-)%s*$")

    if trimmed:sub(1, 1) == "[" or trimmed:sub(1, 1) == "{" then
        local ok, data = pcall(HttpService.JSONDecode, HttpService, trimmed)
        if ok and type(data) == "table" then
            local items = data.songs or data
            if type(items) ~= "table" then return list end
            for _, item in ipairs(items) do
                if type(item) == "table" and item.url then
                    table.insert(list, {
                        name = tostring(item.name or "Untitled"),
                        url = tostring(item.url),
                        category = type(item.category) == "string" and item.category or nil,
                    })
                end
            end
            return list
        end
    end

    for line in body:gmatch("[^\r\n]+") do
        local clean = line:match("^%s*(.-)%s*$")
        if clean ~= "" and not clean:match("^#") and not clean:match("^//") then
            local name, url = clean:match("^(.-)%s*|%s*(https?://.+)$")
            if name and url then
                table.insert(list, {name = name, url = url})
            elseif clean:match("^https?://") then
                local fallbackName = clean:match("([^/]+)%.midi?$") or clean
                table.insert(list, {name = fallbackName, url = clean})
            end
        end
    end

    return list
end

quickBrowser.loadFavorites()
setQuickPickEntries(DEFAULT_QUICKPICKS)
local QuickPickDropdown
local quickPickCount = QuickTab:CreateLabel("Quick Picks results")
quickBrowser.selectionLabel = QuickTab:CreateLabel("Select a song")

function quickBrowser.refreshSelection()
    local entry = selectedQuickPick and quickBrowser.entries[selectedQuickPick]
    if not entry then
        quickBrowser.selectionLabel:Set("No song selected")
        return
    end
    quickBrowser.selectionLabel:Set(entry.category .. (quickBrowser.favorites[selectedQuickPick] and " · ★ Favorite" or ""))
end

local function refreshQuickPickDropdown()
    local matches = {}
    for _, label in ipairs(quickPickOrder) do
        local entry = quickBrowser.entries[label]
        local matchesCategory = quickBrowser.category == "All categories" or quickBrowser.category == entry.category
        if matchesCategory and (not quickBrowser.favoritesOnly or quickBrowser.favorites[label]) then
            local matchesQuery = true
            for _, term in ipairs(quickBrowser.query) do
                if not entry.searchText:find(term, 1, true) then matchesQuery = false; break end
            end
            if matchesQuery then table.insert(matches, label) end
        end
    end
    local count = #matches
    quickBrowser.lastPage = math.max(1, math.ceil(count / quickBrowser.pageSize))
    quickBrowser.page = math.clamp(quickBrowser.page, 1, quickBrowser.lastPage)
    local visible = {}
    local start = (quickBrowser.page - 1) * quickBrowser.pageSize + 1
    for index = start, math.min(count, start + quickBrowser.pageSize - 1) do
        table.insert(visible, matches[index])
    end
    local nextPick = table.find(visible, selectedQuickPick) and selectedQuickPick or visible[1]
    if not nextPick then
        -- Rayfield expects at least one option for a single-select dropdown.
        nextPick = "No matching songs"
        while quickPickMap[nextPick] do nextPick = nextPick .. "." end
        visible[1] = nextPick
    end
    QuickPickDropdown:Refresh(visible)
    QuickPickDropdown:Set({nextPick})
    quickPickCount:Set(string.format("%d of %d songs · Page %d/%d", count, #quickPickOrder, quickBrowser.page, quickBrowser.lastPage))
end

local quickPickSearch = QuickTab:CreateInput({
    Name = "Search Quick Picks",
    CurrentValue = "",
    PlaceholderText = "Song title, artist, or game",
    RemoveTextAfterFocusLost = false,
    Callback = function(text)
        table.clear(quickBrowser.query)
        for term in quickBrowser.normalize(text):gmatch("%S+") do table.insert(quickBrowser.query, term) end
        quickBrowser.page = 1
        if QuickPickDropdown then refreshQuickPickDropdown() end
    end,
})

QuickTab:CreateDropdown({
    Name = "Quick Picks Category",
    Options = quickBrowser.categories,
    CurrentOption = {quickBrowser.category},
    MultipleOptions = false,
    Callback = function(option)
        local label = type(option) == "table" and option[1] or option
        if not table.find(quickBrowser.categories, label) then return end
        quickBrowser.category, quickBrowser.page = label, 1
        if QuickPickDropdown then refreshQuickPickDropdown() end
    end,
})

QuickTab:CreateToggle({
    Name = "Favorites Only",
    CurrentValue = false,
    Callback = function(value)
        quickBrowser.favoritesOnly, quickBrowser.page = value, 1
        if QuickPickDropdown then refreshQuickPickDropdown() end
    end,
})

QuickPickDropdown = QuickTab:CreateDropdown({
    Name = "Select Quick Pick",
    Options = {"Loading songs"},
    CurrentOption = {"Loading songs"},
    MultipleOptions = false,
    Flag = "QuickPickSelect",
    Callback = function(Option)
        local label = type(Option) == "table" and Option[1] or Option
        selectedQuickPick = quickPickMap[label] and label or nil
        quickBrowser.refreshSelection()
    end,
})
refreshQuickPickDropdown()

for _, pageButton in ipairs({{"Previous Results Page", -1}, {"Next Results Page", 1}}) do
    QuickTab:CreateButton({
        Name = pageButton[1],
        Callback = function()
            local page = quickBrowser.page + pageButton[2]
            if page < 1 or page > quickBrowser.lastPage then return end
            quickBrowser.page = page
            refreshQuickPickDropdown()
        end,
    })
end

QuickTab:CreateButton({
    Name = "Clear Quick Picks Search",
    Callback = function() quickPickSearch:Set("") end,
})

QuickTab:CreateButton({
    Name = "Favorite / Unfavorite Selected Song",
    Callback = function()
        if not selectedQuickPick then return end
        local title = selectedQuickPick
        local wasFavorite = quickBrowser.favorites[title]
        if not wasFavorite and #title > 256 then
            setlistNotice("Cannot Favorite Song", "This title is too long to save as a favorite.")
            return
        end
        if not wasFavorite then
            local count = 0
            for _ in pairs(quickBrowser.favorites) do count += 1 end
            if count >= 1000 then
                setlistNotice("Favorites Full", "Remove a favorite before adding another.")
                return
            end
        end
        quickBrowser.favorites[title] = not wasFavorite and true or nil
        local saved = quickBrowser.saveFavorites()
        refreshQuickPickDropdown()
        if not saved then setlistNotice("Favorites Updated · Session Only", "Could not write the local favorites file.") end
    end,
})

QuickTab:CreateButton({
    Name = "▶️ Play Quick Pick",
    Callback = function()
        local url = selectedQuickPick and quickPickMap[selectedQuickPick]
        if not url then
            Rayfield:Notify({Title = "No Song Selected", Content = "Pick a song from the dropdown first.", Duration = 3})
            return
        end
        downloadAndPlayUrl(url, selectedQuickPick)
    end,
})

QuickTab:CreateButton({
    Name = "Queue Quick Pick",
    Callback = function()
        queueMidiUrl(selectedQuickPick and quickPickMap[selectedQuickPick], selectedQuickPick)
    end,
})

local function fetchFromRepoUrl(urlToFetch, silent)
    local cleanUrl = normalizeMidiUrl(urlToFetch)
    if cleanUrl == "" then
        setQuickPickEntries(DEFAULT_QUICKPICKS)
        refreshQuickPickDropdown()
        if not silent then
            Rayfield:Notify({
                Title = "Built-in Quick Picks",
                Content = string.format("Loaded %d built-in songs.", #quickPickOrder),
                Duration = 3,
            })
        end
        return
    end

    task.spawn(function()
        local sep = cleanUrl:find("?", 1, true) and "&" or "?"
        local fetchUrl = cleanUrl .. sep .. "t=" .. tostring(os.time())

        local ok, res, err = safeRequest(fetchUrl)
        if not ok then
            warn("[Repo Fetch] Error:", err)
            if not silent then
                Rayfield:Notify({Title = "Repo Fetch Failed", Content = tostring(err), Duration = 4})
            end
            return
        end

        local status = res.StatusCode or res.status_code
        if status ~= 200 or type(res.Body) ~= "string" then
            warn("[Repo Fetch] HTTP:", status)
            if not silent then
                Rayfield:Notify({Title = "Repo Fetch Failed", Content = "HTTP " .. tostring(status), Duration = 4})
            end
            return
        end

        local parsed = parseQuickPickFile(res.Body)
        if #parsed == 0 then
            if not silent then
                Rayfield:Notify({
                    Title = "Empty / Invalid File",
                    Content = "Expected JSON ([{\"name\":...,\"url\":...}]) or 'Name | URL' lines.",
                    Duration = 4,
                })
            end
            return
        end

        -- While q-29/piano still serves the older catalog, don't replace the expanded, verified fallback at startup.
        if silent and #parsed < #DEFAULT_QUICKPICKS then
            local hasCategories = false
            for _, entry in ipairs(parsed) do
                if entry.category then hasCategories = true; break end
            end
            if not hasCategories then return end
        end
        setQuickPickEntries(parsed)
        refreshQuickPickDropdown()
        if not silent then
            Rayfield:Notify({
                Title = "Repo Songs Loaded",
                Content = string.format("Loaded %d songs from your GitHub file!", #quickPickOrder),
                Duration = 3,
            })
        end
    end)
end

if QUICKPICKS_REPO_URL ~= "" then
    fetchFromRepoUrl(QUICKPICKS_REPO_URL, true)
end

QuickTab:CreateInput({
    Name = "GitHub Repo File URL (songs.json / songs.txt)",
    CurrentValue = QUICKPICKS_REPO_URL,
    PlaceholderText = QUICKPICKS_REPO_URL,
    RemoveTextAfterFocusLost = false,
    Flag = "RepoFileUrl",
    Callback = function(Text)
        repoFileUrl = Text
    end,
})

QuickTab:CreateButton({
    Name = "🔄 Fetch Songs from Repo",
    Callback = function()
        fetchFromRepoUrl(repoFileUrl, false)
    end,
})

local verifyingLinks = false
QuickTab:CreateButton({
    Name = "🔍 Verify All Links (Check in F9)",
    Callback = function()
        if verifyingLinks then return end
        verifyingLinks = true

        task.spawn(function()
            local labels = table.clone(quickPickOrder)
            local urls = table.clone(quickPickMap)
            local total = #labels
            local passed = 0
            local failedCount = 0
            local index = 0
            local done = 0

            Rayfield:Notify({
                Title = "Verifying Links...",
                Content = string.format("Testing %d links. Press F9 to view any failures.", total),
                Duration = 3,
            })

            for _ = 1, 6 do
                task.spawn(function()
                    while true do
                        index = index + 1
                        local i = index
                        if i > total then break end

                        local label = labels[i]
                        local url = urls[label]
                        if url then
                            local ok, res, err = safeRequest(url)
                            local status = ok and res and (res.StatusCode or res.status_code) or nil
                            local isMidi = ok and res and status == 200 and type(res.Body) == "string" and res.Body:find("MThd", 1, true) ~= nil

                            if isMidi then
                                passed = passed + 1
                            else
                                failedCount = failedCount + 1
                                local reason = not ok and tostring(err) or ("HTTP " .. tostring(status) .. " / not MIDI")
                                warn(string.format("[Verify FAIL] %s | %s | %s", label, reason, url))
                            end
                        end
                        done = done + 1
                    end
                end)
            end

            while done < total do
                task.wait(0.1)
            end

            verifyingLinks = false
            print(string.format("[QuickPicks Verify] Passed: %d / %d | Failed: %d", passed, total, failedCount))
            Rayfield:Notify({
                Title = "Link Verification Done",
                Content = string.format("%d/%d working, %d failed (see F9).", passed, total, failedCount),
                Duration = 5,
            })
        end)
    end,
})

QuickTab:CreateSection("Direct .mid URL")

local customMidiUrl = ""

QuickTab:CreateInput({
    Name = "Direct .mid URL",
    CurrentValue = "",
    PlaceholderText = "https://raw.githubusercontent.com/.../song.mid",
    RemoveTextAfterFocusLost = false,
    Flag = "CustomMidiUrl",
    Callback = function(Text)
        customMidiUrl = Text
    end,
})

QuickTab:CreateButton({
    Name = "▶️ Download & Play URL",
    Callback = function()
        downloadAndPlayUrl(customMidiUrl, "Direct URL")
    end,
})

QuickTab:CreateButton({
    Name = "Queue Direct URL",
    Callback = function() queueMidiUrl(customMidiUrl) end,
})

QuickTab:CreateButton({
    Name = "⏹️ Stop",
    Callback = stopPlayback,
})

PlaybackTab:CreateSection("Now Playing")
local playbackTitle = PlaybackTab:CreateLabel("No song selected")
local playbackProgress = PlaybackTab:CreateLabel("Ready")
local playbackSummary = PlaybackTab:CreateLabel("No MIDI analysis")
local practiceStatus

local function formatPlaybackTime(seconds)
    local whole = math.floor(seconds)
    return string.format("%d:%02d", math.floor(whole / 60), whole % 60)
end

local function formatPracticeTime(seconds)
    local tenths = math.floor(seconds * 10)
    return formatPlaybackTime(tenths / 10) .. "." .. tostring(tenths % 10)
end

updatePlaybackUI = function()
    playbackTitle:Set(title ~= "" and title or "No song selected")
    local status = state
    if state == "Cueing" then
        status = string.format("Starts in %ds", cueSecondsLeft)
    elseif state == "Paused" and textEntryActive() then
        status = "Paused for text input"
    end
    stageNowPlaying:Set(status .. " · " .. (title ~= "" and title or "No song selected"))
    playbackSummary:Set(songSummary ~= "" and songSummary or "No MIDI analysis")
    if practiceStatus then
        if practiceEnd then
            practiceStatus:Set("Loop: " .. formatPracticeTime(practiceStart) .. " → " .. formatPracticeTime(practiceEnd))
        elseif practiceStart then
            practiceStatus:Set("A: " .. formatPracticeTime(practiceStart) .. " · Set B to loop")
        else
            practiceStatus:Set("No practice loop")
        end
    end
    if state == "Playing" or state == "Paused" or state == "Finished" then
        local percent = duration > 0 and math.floor(math.min(position / duration, 1) * 100) or 100
        playbackProgress:Set(string.format("%s  ·  %s / %s  (%d%%)", state,
            formatPlaybackTime(math.min(position, duration)), formatPlaybackTime(duration), percent))
    else
        playbackProgress:Set(status)
    end
end

showPlaybackError = function(message)
    warn("[Piano] " .. message)
    Rayfield:Notify({Title = "Playback Failed", Content = message, Duration = 4})
end

PlaybackTab:CreateButton({Name = "⏯️ Pause / Resume", Callback = togglePause})
PlaybackTab:CreateButton({Name = "⏹️ Stop", Callback = stopPlayback})

PlaybackTab:CreateToggle({
    Name = "Loop Current Song",
    CurrentValue = false,
    Flag = "LoopCurrentSong",
    Callback = function(value) loopPlayback = value end,
})

PlaybackTab:CreateSlider({
    Name = "Playback Speed",
    Range = {0.1, 5},
    Increment = 0.1,
    Suffix = "x",
    CurrentValue = 1,
    Flag = "PlaybackSpeed",
    Callback = function(value)
        advancePlaybackClock()
        currentPlaybackSpeed = value
    end,
})

PlaybackTab:CreateSection("Practice · Seek & Loop a Section")
practiceStatus = PlaybackTab:CreateLabel("No practice loop")

local function practicePosition()
    if state ~= "Playing" and state ~= "Paused" then return nil end
    advancePlaybackClock()
    return seekTarget or math.min(position, duration)
end

local function skipBy(seconds)
    local current = practicePosition()
    if current then requestSeek(current + seconds) end
end

PlaybackTab:CreateButton({Name = "Back 5 Seconds", Callback = function() skipBy(-5) end})
PlaybackTab:CreateButton({Name = "Forward 5 Seconds", Callback = function() skipBy(5) end})

PlaybackTab:CreateInput({
    Name = "Jump to Time",
    CurrentValue = "",
    PlaceholderText = "Seconds or m:ss (e.g. 1:24)",
    RemoveTextAfterFocusLost = true,
    Callback = function(text)
        if text:match("^%s*$") then return end
        local minutes, seconds = text:match("^%s*(%d+):(%d%d)%s*$")
        local value = tonumber(text)
        if minutes and tonumber(seconds) < 60 then
            value = tonumber(minutes) * 60 + tonumber(seconds)
        end
        if value and value >= 0 and value < math.huge then
            requestSeek(value)
        else
            Rayfield:Notify({Title = "Invalid Time", Content = "Use seconds or m:ss (e.g. 1:24).", Duration = 3})
        end
    end,
})

PlaybackTab:CreateButton({
    Name = "Set A · Loop Start",
    Callback = function()
        local current = practicePosition()
        if not current then return end
        practiceStart, practiceEnd = current, nil
        updatePlaybackUI()
    end,
})

PlaybackTab:CreateButton({
    Name = "Set B · Loop End",
    Callback = function()
        local current = practicePosition()
        if not current then return end
        local first = practiceStart or 0
        if current - first < 0.25 then
            Rayfield:Notify({Title = "Loop Too Short", Content = "Set B at least 0.25 seconds after A.", Duration = 3})
            return
        end
        practiceStart, practiceEnd = first, current
        updatePlaybackUI()
    end,
})

PlaybackTab:CreateButton({
    Name = "Clear Practice Loop",
    Callback = function()
        clearPractice()
        updatePlaybackUI()
    end,
})

PlaybackTab:CreateSection("Note Options (Apply on Next Play)")
PlaybackTab:CreateToggle({
    Name = "Hold Keys for Note Length",
    CurrentValue = holdPlaybackKeys,
    Flag = "HoldPlaybackKeys",
    Callback = function(value) holdPlaybackKeys = value end,
})

PlaybackTab:CreateToggle({
    Name = "Auto-Fit MIDI to Keyboard (Octaves)",
    CurrentValue = midiSettings.autoFit,
    Flag = "AutoFitMidi",
    Callback = function(value) midiSettings.autoFit = value end,
})

PlaybackTab:CreateToggle({
    Name = "Fold Out-of-Range Notes into Piano Range",
    CurrentValue = midiSettings.foldOctaves,
    Flag = "FoldMidiOctaves",
    Callback = function(value) midiSettings.foldOctaves = value end,
})

PlaybackTab:CreateToggle({
    Name = "Follow MIDI Pedal (Hold Mode)",
    CurrentValue = midiSettings.followPedal,
    Flag = "FollowMidiPedal",
    Callback = function(value) midiSettings.followPedal = value end,
})

PlaybackTab:CreateToggle({
    Name = "Skip MIDI Drums (Channel 10)",
    CurrentValue = midiSettings.skipDrums,
    Flag = "SkipMidiDrums",
    Callback = function(value) midiSettings.skipDrums = value end,
})

PlaybackTab:CreateSlider({
    Name = "MIDI Transpose",
    Range = {-24, 24},
    Increment = 1,
    Suffix = " semitones",
    CurrentValue = midiSettings.transpose,
    Flag = "MidiTranspose",
    Callback = function(value) midiSettings.transpose = value end,
})

PlaybackTab:CreateSlider({
    Name = "MIDI Channel (0 = All)",
    Range = {0, 16},
    Increment = 1,
    CurrentValue = midiSettings.channel,
    Callback = function(value) midiSettings.channel = value end,
})

-- ==========================================
-- Tab 2: Local .mid Files & Text Sheets
-- ==========================================
LocalTab:CreateSection("Local .mid Files (Workspace)")

local localFiles = {}
local selectedLocalFile = nil

local function scanLocalMidiFiles()
    table.clear(localFiles)
    if not listfiles or not readfile then
        return {"Executor lacks listfiles/readfile"}
    end

    local results = {}
    local seen = {}

    local function tryScan(folder)
        local ok, files = pcall(listfiles, folder)
        if not ok or type(files) ~= "table" then return end
        for _, path in ipairs(files) do
            if type(path) == "string" and path:lower():match("%.midi?$") then
                local name = path:match("([^/\\]+)$") or path
                if not seen[path] then
                    seen[path] = true
                    localFiles[name] = path
                    table.insert(results, name)
                end
            end
        end
    end

    if isfolder and pcall(isfolder, "midis") and isfolder("midis") then
        tryScan("midis")
    end
    tryScan("")

    if #results == 0 then
        return {"No .mid files in workspace"}
    end
    return results
end

local LocalDropdown = LocalTab:CreateDropdown({
    Name = "Select Local .mid",
    Options = scanLocalMidiFiles(),
    CurrentOption = {"Select a file"},
    MultipleOptions = false,
    Flag = "LocalMidiSelect",
    Callback = function(Option)
        selectedLocalFile = type(Option) == "table" and Option[1] or Option
    end,
})

LocalTab:CreateButton({
    Name = "🔄 Refresh Local .mid Files",
    Callback = function()
        LocalDropdown:Refresh(scanLocalMidiFiles())
    end,
})

LocalTab:CreateButton({
    Name = "▶️ Play Local MIDI",
    Callback = function()
        local path = selectedLocalFile and localFiles[selectedLocalFile]
        if not path or not readfile then return end
        local myId = beginPlayback(selectedLocalFile)
        if not myId then return end
        local options, holdKeys = table.clone(midiSettings), holdPlaybackKeys
        task.spawn(function()
            local ok, content = pcall(readfile, path)
            if not ok or type(content) ~= "string" then
                failPlayback(myId, "Could not read the selected MIDI file.")
                return
            end
            prepareAndPlay(buildMidiTimeline, content, options, holdKeys, myId)
        end)
    end,
})

LocalTab:CreateButton({
    Name = "Queue Local MIDI",
    Callback = function()
        local path = selectedLocalFile and localFiles[selectedLocalFile]
        if not path then
            setlistNotice("No Local MIDI Selected", "Select a local MIDI file first.")
            return
        end
        queueSong({name = selectedLocalFile, kind = "file", source = path})
    end,
})

LocalTab:CreateSection("Text Sheets")

local pastedSheet = ""
local sheetBpm = 120

LocalTab:CreateInput({
    Name = "Paste Text Sheet",
    CurrentValue = "",
    PlaceholderText = "e.g. [tu] y [ro] | a [sd]",
    RemoveTextAfterFocusLost = false,
    Flag = "SheetInput",
    Callback = function(Text)
        pastedSheet = Text
    end,
})

LocalTab:CreateSlider({
    Name = "Text Sheet BPM",
    Range = {40, 300},
    Increment = 5,
    Suffix = " BPM",
    CurrentValue = 120,
    Flag = "SheetBPM",
    Callback = function(Value)
        sheetBpm = Value
    end,
})

LocalTab:CreateButton({
    Name = "▶️ Play Pasted Sheet",
    Callback = function()
        if pastedSheet == "" then return end
        local myId = beginPlayback("Pasted text sheet")
        if myId then task.spawn(prepareAndPlay, buildSheetTimeline, pastedSheet, sheetBpm, holdPlaybackKeys, myId) end
    end,
})

LocalTab:CreateButton({
    Name = "Queue Pasted Sheet",
    Callback = function()
        if pastedSheet:match("^%s*$") then
            setlistNotice("No Sheet Entered", "Paste a text sheet first.")
            return
        end
        queueSong({name = "Pasted text sheet", kind = "sheet", source = pastedSheet, bpm = sheetBpm})
    end,
})

LocalTab:CreateButton({
    Name = "⏹️ Stop",
    Callback = stopPlayback,
})

-- ==========================================
-- Tab 3: NanoMIDI API
-- ==========================================
local apiData = {}
local songNames = {}

local function formatArtists(artists)
    if type(artists) == "table" then
        return table.concat(artists, ", ")
    elseif artists ~= nil then
        return tostring(artists)
    end
    return "Unknown"
end

local function encodeUrlPath(str)
    return (str:gsub("([^%w%-%._~/])", function(c)
        return string.format("%%%02X", c:byte())
    end))
end

local function loadMidiData()
    table.clear(apiData)
    table.clear(songNames)

    local ok, res, err = safeRequest("https://api.nanomidi.net/api/midiData", nanoHeaders)
    if not ok then
        warn("[NanoMIDI] Request error:", err)
        return {"Request Error: " .. tostring(err)}
    end

    local status = res.StatusCode or res.status_code
    if status ~= 200 then
        return {"Failed to load API (HTTP " .. tostring(status) .. ")"}
    end

    local decodeOk, data = pcall(HttpService.JSONDecode, HttpService, res.Body)
    if not decodeOk or type(data) ~= "table" then
        return {"Invalid API JSON response"}
    end

    for _, song in ipairs(data) do
        local label = tostring(song.name or "Untitled") .. " - " .. formatArtists(song.artists)
        if apiData[label] then
            label = label .. " (" .. tostring(song.midiFilename or #songNames + 1) .. ")"
        end
        table.insert(songNames, label)
        apiData[label] = song
    end

    if #songNames == 0 then
        return {"No songs found"}
    end
    return songNames
end

local selectedSong = nil
local NanoDropdown = NanoTab:CreateDropdown({
    Name = "Select Song",
    Options = {"Fetching..."},
    CurrentOption = {"Fetching..."},
    MultipleOptions = false,
    Flag = "NanoSongSelect",
    Callback = function(Option)
        selectedSong = type(Option) == "table" and Option[1] or Option
    end,
})

local function refreshSongs()
    task.spawn(function()
        local names = loadMidiData()
        NanoDropdown:Refresh(names)
    end)
end

refreshSongs()

NanoTab:CreateButton({
    Name = "🔄 Refresh Song List",
    Callback = refreshSongs,
})

NanoTab:CreateButton({
    Name = "▶️ Download & Play",
    Callback = function()
        local song = selectedSong and apiData[selectedSong]
        if not song or not song.midiFilename then return end
        local url = "https://api.nanomidi.net/api/midis/" .. encodeUrlPath(tostring(song.midiFilename))
        downloadAndPlayUrl(url, selectedSong, nanoHeaders)
    end,
})

NanoTab:CreateButton({
    Name = "Queue NanoMIDI Song",
    Callback = function()
        local song = selectedSong and apiData[selectedSong]
        if not song or not song.midiFilename then
            setlistNotice("No NanoMIDI Song Selected", "Select a song from the NanoMIDI list first.")
            return
        end
        local url = "https://api.nanomidi.net/api/midis/" .. encodeUrlPath(tostring(song.midiFilename))
        queueMidiUrl(url, selectedSong, nanoHeaders)
    end,
})

NanoTab:CreateButton({
    Name = "⏹️ Stop",
    Callback = stopPlayback,
})

-- ==========================================
-- Keyboard Setup: editable MIDI layout, remembered per experience
-- ==========================================
do
    local setupTab = Window:CreateTab("Keyboard Setup", 4483362458)
    local profilePath
    if game.GameId and game.GameId > 0 then
        profilePath = string.format("piano-layout-u%.0f.txt", game.GameId)
    elseif game.PlaceId and game.PlaceId > 0 then
        profilePath = string.format("piano-layout-p%.0f.txt", game.PlaceId)
    end

    local function readLayout()
        if not profilePath or type(readfile) ~= "function" then return nil end
        local ok, data = pcall(readfile, profilePath)
        if not ok or type(data) ~= "string" or #data > 512 then return nil end
        return layoutTools.parse(data)
    end

    local storedLayout = readLayout()
    if storedLayout then midiSettings.layout = storedLayout end
    local draft = midiSettings.layout.spec
    local layoutStatus = setupTab:CreateLabel("Active keyboard layout")
    local function refreshLayoutStatus()
        local layout = midiSettings.layout
        local label = layout.spec == layoutTools.default.spec and "Standard" or "Custom"
        layoutStatus:Set(string.format("%s · %d keys · MIDI %d–%d", label, layout.count, layout.first, layout.last))
    end
    refreshLayoutStatus()

    setupTab:CreateSection("MIDI Mapping · Applies on Next Play")
    setupTab:CreateLabel("Format: lowest MIDI note, colon, then one key per semitone.")
    setupTab:CreateLabel("Example: 60:a.s.df  ·  dots skip pitches; capitals use Shift.")
    local layoutInput = setupTab:CreateInput({
        Name = "Keyboard Mapping",
        CurrentValue = draft,
        PlaceholderText = "60:a.s.df",
        RemoveTextAfterFocusLost = false,
        Callback = function(value) draft = value end,
    })

    local function useLayout(layout)
        midiSettings.layout = layout
        layoutInput:Set(layout.spec)
        refreshLayoutStatus()
        if stageSlot and stageSlot.status == "Ready" and stageSlot.entry.kind ~= "sheet" then
            stageAnalysis:Set("Layout changed · Preload Next to refresh MIDI analysis")
        end
    end

    setupTab:CreateButton({
        Name = "Apply Mapping",
        Callback = function()
            local layout, err = layoutTools.parse(draft)
            if not layout then setlistNotice("Invalid Keyboard Mapping", err); return end
            useLayout(layout)
        end,
    })

    setupTab:CreateButton({
        Name = "Use Standard Mapping",
        Callback = function() useLayout(layoutTools.default) end,
    })

    setupTab:CreateButton({
        Name = "Save Active Mapping for This Experience",
        Callback = function()
            if not profilePath or type(writefile) ~= "function" then
                setlistNotice("Cannot Save Mapping", "This runtime does not have writable experience profiles.")
                return
            end
            local ok = pcall(writefile, profilePath, midiSettings.layout.spec)
            if not ok then setlistNotice("Cannot Save Mapping", "Could not write the local mapping."); return end
            setlistNotice("Keyboard Mapping Saved", "This mapping will load the next time you open the script in this experience.")
        end,
    })

    setupTab:CreateButton({
        Name = "Reload Saved Mapping",
        Callback = function()
            local layout = readLayout()
            if not layout then setlistNotice("No Saved Mapping", "No valid keyboard mapping was found for this experience."); return end
            useLayout(layout)
        end,
    })
end
