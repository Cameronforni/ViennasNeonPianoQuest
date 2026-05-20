# Vienna's Neon Piano Quest 🎹✨

A pink, neon, K-pop-inspired piano-learning iPad app for a six-year-old. Built entirely in SwiftUI with programmatic audio synthesis — no bundled sound files required.

---

## Prerequisites

- **macOS 14 Ventura** or later
- **Xcode 15** or later (includes the iOS 17+ SDK and iPad simulators)
- An Apple Developer account is **not** required for simulator testing

If you only have the Command Line Tools installed, you will need the full Xcode from the Mac App Store or [developer.apple.com/xcode](https://developer.apple.com/xcode/).

---

## Project Setup

Two options are provided. Pick whichever suits you.

### Option A — Use the pre-generated Xcode project (recommended)

A `project.yml` spec and `.xcodeproj` have already been generated with [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```zsh
open ~/ViennasNeonPianoQuest/ViennasNeonPianoQuest.xcodeproj
```

That's it. Skip to **Running in the Simulator** below.

> **If the `.xcodeproj` is missing** (e.g. you cloned the source without it), regenerate it:
>
> ```zsh
> brew install xcodegen          # one-time install
> cd ~/ViennasNeonPianoQuest
> xcodegen generate
> open ViennasNeonPianoQuest.xcodeproj
> ```

### Option B — Create a fresh Xcode project manually

1. Open Xcode → **File → New → Project**.
2. Choose **App** under the iOS tab. Click **Next**.
3. Fill in:
   - **Product Name:** `ViennasNeonPianoQuest`
   - **Interface:** SwiftUI
   - **Language:** Swift
4. Save the project anywhere you like.
5. In the Xcode project navigator, **delete** the auto-generated `ContentView.swift` and `ViennasNeonPianoQuestApp.swift` (move to Trash).
6. Drag **all 16 `.swift` files** from `ViennasNeonPianoQuest/ViennasNeonPianoQuest/` into the project navigator.
   - Check **"Copy items if needed"**.
   - Make sure the app target is selected under **"Add to targets"**.
7. Select the project root in the navigator, then under **General → Deployment Info**:
   - Set **Minimum Deployment** to `iOS 16.0`.
   - Under **Supported Destinations**, ensure **iPad** is listed.
   - Under **Supported Interface Orientations (iPad)**, enable all four orientations (Landscape Left and Landscape Right are the most important).

---

## Source Files at a Glance

```
ViennasNeonPianoQuest/
├── project.yml                        ← XcodeGen spec
├── README.md
└── ViennasNeonPianoQuest/
    ├── ViennasNeonPianoQuestApp.swift  ← @main entry point
    ├── ContentView.swift              ← Navigation router
    ├── NoteModel.swift                ← PianoNote, FallingNote, RhythmGem, MelodySequence
    ├── GameModels.swift               ← GameLevel, Reward, Character, ShadowMonster, InstrumentType
    ├── GameState.swift                ← Central ObservableObject + UserDefaults persistence
    ├── AudioEngine.swift              ← AVAudioEngine synthesis, 5 instruments, 12-voice polyphony
    ├── NeonTheme.swift                ← Colours, gradients, glow modifiers, particles, buttons
    ├── PianoKeyboardView.swift        ← Reusable neon piano keyboard component
    ├── HomeScreenView.swift           ← Animated title screen with mascots
    ├── LevelSelectView.swift          ← Scrollable candy-coloured stage map
    ├── TapMagicNoteView.swift         ← Game Mode 1 — falling note bubbles
    ├── RhythmStageView.swift          ← Game Mode 2 — horizontal rhythm gems
    ├── RescueMelodyView.swift         ← Game Mode 3 — call-and-response melodies
    ├── FreePlayView.swift             ← Game Mode 4 — free play with sparkles
    ├── BossBattleView.swift           ← Game Mode 5 — boss dance battle
    ├── StickerRoomView.swift          ← Reward gallery + concert poster decorator
    └── ParentSettingsView.swift       ← Parent controls
```

---

## Audio: How It Works

### No sound files are needed

The app generates all piano sounds **programmatically** at launch using `AVAudioEngine` with additive synthesis. Buffers for every note × instrument combination are pre-computed and cached in memory, so playback is instant with zero latency.

### How the synthesis works

Each note is built from sine-wave harmonics shaped by an ADSR amplitude envelope:

```
signal(t) = envelope(t) × Σ [ amplitude_n × sin(2π × frequency × harmonic_n × t) ]
```

- **Envelope** — fast attack (2–10 ms), exponential decay (rate varies per instrument).
- **Harmonics** — each instrument defines its own overtone profile.
- **Vibrato** — the Kitty Piano adds ±3 Hz wobble at 5.5 Hz.
- **Polyphony** — a pool of 12 `AVAudioPlayerNode` instances allows concurrent notes.

### The 5 built-in instruments

**Grand Piano** — Harmonics 1×, 2×, 3×, 4×, 5×. Rich and warm.
**Bubble Pop Piano** — Harmonics 1×, 2×. Soft, round, almost pure sine.
**Neon Synth** — Harmonics 1×, 3×, 5×, 7×. Buzzy, square-wave character.
**Music Box** — Harmonics 1×, 3×, 6×. Bright, bell-like, fast decay.
**Kitty Piano** — Harmonics 1×, 2×, 4× plus vibrato. Gentle wobble.

---

## Adding Placeholder Audio Assets (Optional)

The synthesised tones work out of the box, but you can replace them with recorded samples for a more realistic sound.

### Step 1 — Prepare the audio files

Record or source **7 audio files per instrument** — one for each note C4 through B4.

- Format: **WAV** or **CAF**, 44.1 kHz, 16-bit or higher, mono or stereo
- Duration: ~1–2 seconds with natural decay
- Naming convention: `note_C.wav`, `note_D.wav`, `note_E.wav`, `note_F.wav`, `note_G.wav`, `note_A.wav`, `note_B.wav`

Organise them into folders by instrument:

```
Audio/
├── GrandPiano/
│   ├── note_C.wav
│   ├── note_D.wav
│   ├── note_E.wav
│   ├── note_F.wav
│   ├── note_G.wav
│   ├── note_A.wav
│   └── note_B.wav
├── BubblePop/
│   └── ... (same 7 files)
├── NeonSynth/
│   └── ...
├── MusicBox/
│   └── ...
└── KittyPiano/
    └── ...
```

You do not need to replace every instrument — the app falls back to synthesis for any missing files.

### Step 2 — Add files to the Xcode project

1. Drag the `Audio/` folder into the Xcode project navigator.
2. Check **"Copy items if needed"**.
3. Make sure **"Create folder references"** is selected (blue folder icon) so the subfolder structure is preserved in the bundle.
4. Verify the app target is checked under **"Add to targets"**.

### Step 3 — Modify AudioEngine.swift

Add a file-loading method and update the caching to prefer files over synthesis:

```swift
// Add this method to AudioEngine
private func loadBuffer(note: PianoNote, instrument: InstrumentType) -> AVAudioPCMBuffer? {
    let folder: String
    switch instrument {
    case .grandPiano: folder = "GrandPiano"
    case .bubblePop:  folder = "BubblePop"
    case .neonSynth:  folder = "NeonSynth"
    case .musicBox:   folder = "MusicBox"
    case .kittyPiano: folder = "KittyPiano"
    }

    guard let url = Bundle.main.url(
        forResource: "note_\(note.rawValue)",
        withExtension: "wav",
        subdirectory: "Audio/\(folder)"
    ) else { return nil }

    guard let file = try? AVAudioFile(forReading: url) else { return nil }
    let format = file.processingFormat
    let frameCount = AVAudioFrameCount(file.length)
    guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
    try? file.read(into: buffer)
    return buffer
}
```

Then update `precacheAllBuffers()` to try file loading first:

```swift
private func precacheAllBuffers() {
    for instrument in InstrumentType.allCases {
        for note in PianoNote.allCases {
            let key = cacheKey(instrument: instrument, note: note)
            // Prefer bundled audio file; fall back to synthesis
            if let fileBuffer = loadBuffer(note: note, instrument: instrument) {
                bufferCache[key] = fileBuffer
            } else {
                bufferCache[key] = generateBuffer(note: note, instrument: instrument)
            }
        }
    }
}
```

### Step 4 — Adding background beat loops (optional)

For the K-pop Rhythm Stage, you can add a looping background beat:

1. Create an original loop as a WAV/CAF file (e.g. `beat_loop_120bpm.wav`), trimmed to an exact number of bars.
2. Add it to the Xcode project bundle.
3. In `AudioEngine.swift`, add a dedicated loop player:

```swift
private var loopPlayer: AVAudioPlayerNode?

func startBeatLoop(named filename: String) {
    guard let url = Bundle.main.url(forResource: filename, withExtension: "wav"),
          let file = try? AVAudioFile(forReading: url) else { return }
    let format = file.processingFormat
    let frameCount = AVAudioFrameCount(file.length)
    guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
    try? file.read(into: buffer)

    let player = AVAudioPlayerNode()
    engine.attach(player)
    engine.connect(player, to: engine.mainMixerNode, format: format)
    player.scheduleBuffer(buffer, at: nil, options: .loops)
    player.volume = 0.3  // mix quietly under the piano
    player.play()
    loopPlayer = player
}

func stopBeatLoop() {
    loopPlayer?.stop()
    if let player = loopPlayer { engine.detach(player) }
    loopPlayer = nil
}
```

---

## Running in the Simulator

### 1. Open the project

```zsh
open ~/ViennasNeonPianoQuest/ViennasNeonPianoQuest.xcodeproj
```

### 2. Select an iPad simulator

In the Xcode toolbar device picker, choose one of:
- **iPad Pro 13-inch (M4)**
- **iPad Air 13-inch (M2)**
- **iPad (10th generation)**

> If no iPad simulators appear, go to **Xcode → Settings → Platforms** and download an iOS simulator runtime.

### 3. Build and run

Press **⌘R** (or click the ▶ button). Xcode will compile the project, boot the simulator, and install the app.

You should see the neon home screen with the "Vienna's Neon Piano Quest" title, bouncing mascot characters, and a large pink Play button.

### 4. What to test

**Home Screen** — App launch. Verify the title animates in, mascots bounce, all 5 menu buttons and the Settings gear are tappable.

**Level Select** — Home → Play. Four stage cards scroll horizontally. Level 1 ("First Notes") should be unlocked; the rest show lock icons.

**Tap the Magic Note** — Level Select → tap Level 1. Coloured note bubbles fall from the top. The matching piano key glows. Tapping the correct key plays a sound, shows a burst particle, and increments the star count. Missed notes trigger an encouragement message.

**K-pop Rhythm Stage** — Home → Rhythm Stage. A start overlay appears. Tap "Start!" and diamond gems scroll left. Tap matching piano keys as gems reach the pink target line. Verify hit ratings ("Perfect!", "Amazing!", etc.) appear.

**Rescue the Melody** — Home → Learn Notes. Tap "Listen" to hear a melody play back with visual note highlights. The piano then enables for your turn. Correct notes advance the sequence; wrong notes show encouragement without penalty.

**Free Play** — Home → Free Play. All 7 keys are playable. The Grand Piano instrument is unlocked by default; others show a lock overlay. Tapping keys produces sparkle effects in the visual area.

**Boss Dance Battle** — Complete a level via Tap the Magic Note, then the next level opens. (Or temporarily modify `isLevelUnlocked` in `GameState.swift` to return `true` for testing.) The boss emoji dances on correct notes and the stage spotlights brighten progressively.

**Sticker Room** — Home → Stickers. Category tabs switch between reward types. The "Pink Star" sticker is unlocked by default. Tap unlocked stickers to place them on the concert poster. Tap "Clear Poster" to reset.

**Parent Settings** — Home → small gear icon at the bottom. Toggle Quiet Mode, switch practice length (5/10/15 min), change difficulty (Easy/Medium/Hard), and test the Reset progress confirmation dialog.

### Simulator tips

- **Sound** — Audio plays through your Mac speakers. Make sure Mac volume is up.
- **Touch** — Click to tap. Hold **⌥ Option** and drag to pinch/multi-touch.
- **Rotation** — **⌘←** / **⌘→** rotates between landscape and portrait.
- **Performance** — Particle effects and animations may stutter slightly in the simulator. This is normal and does not reflect real-device performance.

---

## Running the Unit Tests

The project includes an `ViennasNeonPianoQuestTests` target with **86 tests** covering all core models and game logic.

### From Xcode

1. Open the project:
   ```zsh
   open ~/ViennasNeonPianoQuest/ViennasNeonPianoQuest.xcodeproj
   ```
2. Select an **iPad simulator** in the device picker (the same one you use to run the app).
3. Press **⌘U** (or **Product → Test**).
4. Xcode builds the app, injects the test bundle, and runs all tests. Results appear in the **Test Navigator** (⌘6) and the **Report Navigator** (⌘9).

### From the command line

If you have the full Xcode installed (not just Command Line Tools):

```zsh
xcodebuild test \
  -project ~/ViennasNeonPianoQuest/ViennasNeonPianoQuest.xcodeproj \
  -scheme ViennasNeonPianoQuest \
  -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' \
  2>&1 | tail -30
```

Replace the `-destination` name with whichever iPad simulator you have installed. To list available simulators:

```zsh
xcrun simctl list devices available | grep -i ipad
```

### Test file location

```
ViennasNeonPianoQuestTests/
└── ViennasNeonPianoQuestTests.swift    ← all 86 tests in one file
```

### What the tests cover

**PianoNoteTests** (10 tests)
- Exactly 7 notes, raw values C–B, frequencies ascending, A4 = 440 Hz, C4 = 261.63 Hz
- Key indices 0–6 and unique, Identifiable ID equals raw value, every note has an emoji
- Codable encode/decode round-trip for all notes

**FallingNoteTests** (4 tests)
- Default initialisation values (yOffset, speed, isActive, wasHit)
- Custom speed, unique UUIDs between instances, mutable fields

**RhythmGemTests** (2 tests)
- Initial state (note, beatIndex, xOffset, isActive, wasHit, rating nil)
- Rating assignment and wasHit flag

**HitRatingTests** (2 tests)
- All cases have non-empty display strings, exactly 4 ratings exist

**MelodySequenceTests** (6 tests)
- Beginner melodies non-empty, each has ≥3 notes, all have names
- Difficulty in 1–5, sorted by ascending difficulty, unique IDs

**GameLevelTests** (9 tests)
- 8 predefined levels, sequential stage numbers 1–8, unique IDs
- Every level has available notes, sequences only reference available notes
- Every boss name resolves in `ShadowMonster.all`
- Available-note count is non-decreasing across levels
- Codable round-trip, star thresholds are ascending (t1 ≤ t2 ≤ t3)

**RewardTests** (4 tests)
- 24 total rewards, unique IDs, all 6 `RewardCategory` cases represented
- Codable round-trip for every reward

**InstrumentTypeTests** (6 tests)
- 5 instruments, all have harmonics, positive attack and decay
- Only Kitty Piano has vibrato, fundamental harmonic (1×) always present

**CharacterTests** (5 tests)
- 4 mascots, DJ Vienna Star is `.hero`, all mascots are `.mascot`
- 8 shadow monsters, every monster has positive `danceMovesNeeded`

**ParentSettingsTests** (2 tests)
- Default values match spec (quietMode false, 10 min, difficulty 1, speed 3.0)
- Codable round-trip with non-default values

**GameStateTests** (36 tests)
- *Initial state* — screen is `.home`, stars 0, score 0, default sticker unlocked, no levels completed
- *Session* — `resetSession()` clears score, combo, feedback text, and showFeedback flag
- *Scoring* — `scoreHit()` increments both score and combo, shows celebration; `scoreMiss()` resets combo to 0 but preserves score, shows encouragement
- *Star calculation* — 1★/2★/3★ awarded at correct thresholds; score exceeding max threshold still yields 3★; score of 0 still awards 1★ (no failure)
- *Replay logic* — replaying with the same or lower score does not add stars; replaying with a higher score adds only the delta
- *Multi-level* — stars from different levels accumulate in `totalStars`
- *Level unlocking* — level 1 always unlocked; level 2 locked until level 1 complete; completing level 1 does not skip-unlock level 3
- *Reward unlocking* — completing 1 level unlocks Neon Heart sticker; completing 2 unlocks First Song badge; 3★ total unlocks Diamond sticker; 5★ total unlocks Pink Stage background; `isRewardUnlocked` returns correct bool
- *Persistence* — `save()` then fresh `GameState()` (which calls `load()`) restores totalStars, completedLevelIDs, levelStars, unlockedRewardIDs, and settings; loading from empty UserDefaults produces clean initial state
- *Navigation* — `navigate(to:)` changes `currentScreen`; `goHome()` returns to `.home` and resets session; all screen enum cases are navigable

### Test isolation

Every test clears the five `UserDefaults` keys used by `GameState` in both `setUp()` and `tearDown()`, so tests are fully isolated and can run in any order without leaking state.

---

## Troubleshooting

**"No such module 'SwiftUI'"**
Your Xcode version is too old or the build target is wrong. Update to Xcode 15+ and ensure the destination is an iPad simulator, not "My Mac".

**No iPad simulators available**
Xcode → Settings → Platforms → click **+** → download an iOS simulator runtime (17.0 or later recommended).

**No audio plays**
Check that your Mac is not muted. Simulator audio routes through macOS. Also open Parent Settings in the app and verify Quiet Mode is off.

**"'AVAudioSession' is unavailable in macOS"**
This only happens if you build for a macOS target. The code is guarded with `#if os(iOS)`. Switch the Xcode destination to an iPad simulator.

**"external macro 'Preview' not found"**
This error occurs only when compiling with the standalone `swiftc` CLI. It does not affect Xcode builds. All `#Preview` macros have been removed from the project.

**App launches but the screen is black**
Ensure all 16 `.swift` files are added to the app target. In Xcode, select each file and check the **Target Membership** checkbox in the File Inspector (right panel).

---

## Reward Unlock Schedule

24 rewards across 6 categories, unlocked automatically by playing.

**By levels completed:**
- 1 level → Neon Heart sticker
- 2 levels → First Song badge
- 3 levels → Golden Note sticker
- 4 levels → Bunny's Neon Bow (outfit)
- 5 levels → Rainbow Sparkle sticker + Bubble Pop Piano sound
- 6 levels → Rhythm Star badge + Panda's Pink Jacket (outfit)
- 7 levels → Sparkle Crown + Neon Synth sound
- 8 levels → Piano Hero badge + Neon Crown

**By total stars earned:**
- 3 stars → Diamond Glow sticker
- 5 stars → Pink Concert Stage (background)
- 8 stars → Neon Butterfly sticker
- 10 stars → Neon City Night (background) + Music Box sound
- 12 stars → Neon Heart badge
- 15 stars → Rainbow Arena (background) + Cat's Star Shades (outfit)
- 20 stars → Space Stage (background) + Kitty Piano sound + Fox's Glitter Cape (outfit)

---

## Placeholder Art Asset Guide

The app uses emoji as stand-ins. For a production release, commission or create illustrated assets:

**DJ Vienna Star (👩‍🎤)** — Young girl, chibi/anime style, sparkly pink-and-purple stage outfit, oversized pink headphones, glowing pink keytar. Confident pose, big smile.

**Melody Bunny (🐰)** — Fluffy pink bunny in a K-pop idol outfit. Floppy ears with star-shaped earrings. Dances by hopping side to side.

**Bass Cat (🐱)** — Cool purple cat with oversized neon sunglasses and a tiny bass guitar. Nods head to the beat.

**Sparkle Panda (🐼)** — White-and-pink panda covered in glitter. Wears a sparkly jacket. Claps paws when notes are hit.

**Rhythm Fox (🦊)** — Orange-and-gold fox with a conductor's baton. Quick movements, keeps the beat, wears a glittery cape.

**Shadow Monsters** — Rounded blob shapes in translucent dark purple/grey. Googly eyes, silly grins, wobbly bounce animations. Never scary — always funny. One per boss: 👾 🫠 🕺 🍮 😵‍💫 👻 👑 🎧.

**Stage Backgrounds** — Dark concert-hall base with neon spotlights (pink, purple, cyan). Each of the 4 stages has a unique theme:
- Pink Pop Palace — hot pink and bubblegum
- Neon Note City — purple and violet
- Glitter Moon Stage — cyan and silver
- Rainbow Rhythm Arena — gold and rainbow gradients

**Note Bubbles** — Glowing circles (56 pt) with the note letter centred, unique neon colour per note, radial gradient from bright centre to semi-transparent edge.

**Rhythm Gems** — Diamond shapes (44 pt) in note colours with a white inner stroke and a coloured outer glow trail.

---

## Future Improvements

1. **Illustrated art** — Replace all emoji with original character sprites and Lottie/Rive animations
2. **SpriteKit** — Port falling-note and rhythm modes to SpriteKit for 60 fps particles and physics
3. **Beat loops** — Add original K-pop instrumental loops to Rhythm Stage
4. **Haptics** — Gentle taps via `UIImpactFeedbackGenerator` on every key press
5. **Practice timer** — Enforce the parent-configured session length with a friendly "Time's up, superstar!" screen
6. **iCloud sync** — Persist progress across devices via CloudKit
7. **More content** — 20+ levels introducing sharps, flats, and two-octave range
8. **Recording** — Let Vienna record compositions and play them back
9. **Accessibility** — Full VoiceOver, Dynamic Type, and Switch Control support
10. **Localisation** — Translate the UI and encouragement messages into multiple languages

---

## Safety & Privacy

- ✅ No advertisements
- ✅ No external links
- ✅ No in-app purchases
- ✅ No data collection or network requests
- ✅ No third-party SDKs
- ✅ All characters, music, and content are original
- ✅ Encouraging-only feedback — no failure states, no penalties
- ✅ Parent Settings are subtle and separated from game content
