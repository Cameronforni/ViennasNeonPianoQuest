import SwiftUI

// MARK: - Instrument Type

enum InstrumentType: String, CaseIterable, Identifiable, Codable {
    case grandPiano  = "Grand Piano"
    case bubblePop   = "Bubble Pop Piano"
    case neonSynth   = "Neon Synth"
    case musicBox    = "Music Box"
    case kittyPiano  = "Kitty Piano"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .grandPiano: return "🎹"
        case .bubblePop:  return "🫧"
        case .neonSynth:  return "🎛️"
        case .musicBox:   return "🎁"
        case .kittyPiano: return "🐱"
        }
    }

    /// Harmonic profile: (harmonic multiplier, amplitude)
    var harmonics: [(Double, Double)] {
        switch self {
        case .grandPiano: return [(1, 1.0), (2, 0.5), (3, 0.25), (4, 0.12), (5, 0.06)]
        case .bubblePop:  return [(1, 1.0), (2, 0.3)]  // softer, rounder
        case .neonSynth:  return [(1, 1.0), (3, 0.6), (5, 0.3), (7, 0.15)]  // square-ish
        case .musicBox:   return [(1, 1.0), (3, 0.4), (6, 0.2)]  // bright & bell-like
        case .kittyPiano: return [(1, 1.0), (2, 0.7), (4, 0.3)]  // with vibrato added
        }
    }

    /// Attack time in seconds
    var attack: Double {
        switch self {
        case .grandPiano: return 0.008
        case .bubblePop:  return 0.002
        case .neonSynth:  return 0.001
        case .musicBox:   return 0.005
        case .kittyPiano: return 0.01
        }
    }

    /// Decay rate (higher = faster fade)
    var decay: Double {
        switch self {
        case .grandPiano: return 2.5
        case .bubblePop:  return 5.0
        case .neonSynth:  return 1.5
        case .musicBox:   return 4.0
        case .kittyPiano: return 3.0
        }
    }

    /// Whether vibrato is applied
    var vibrato: Bool { self == .kittyPiano }
}

// MARK: - Level / Stage

struct GameLevel: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let stageName: String
    let availableNotes: [PianoNote]
    let noteSequence: [PianoNote]       // for Tap mode / Boss battle
    let melodyName: String?             // links to MelodySequence by name
    let bossName: String
    let stageNumber: Int
    let starThresholds: (Int, Int, Int) // 1-star, 2-star, 3-star thresholds

    // Codable conformance for tuple
    enum CodingKeys: String, CodingKey {
        case id, name, stageName, availableNotes, noteSequence, melodyName, bossName, stageNumber
    }

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: GameLevel, rhs: GameLevel) -> Bool { lhs.id == rhs.id }

    init(id: String, name: String, stageName: String, availableNotes: [PianoNote],
         noteSequence: [PianoNote], melodyName: String? = nil, bossName: String,
         stageNumber: Int, starThresholds: (Int, Int, Int) = (3, 5, 8)) {
        self.id = id; self.name = name; self.stageName = stageName
        self.availableNotes = availableNotes; self.noteSequence = noteSequence
        self.melodyName = melodyName; self.bossName = bossName
        self.stageNumber = stageNumber; self.starThresholds = starThresholds
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        stageName = try c.decode(String.self, forKey: .stageName)
        availableNotes = try c.decode([PianoNote].self, forKey: .availableNotes)
        noteSequence = try c.decode([PianoNote].self, forKey: .noteSequence)
        melodyName = try c.decodeIfPresent(String.self, forKey: .melodyName)
        bossName = try c.decode(String.self, forKey: .bossName)
        stageNumber = try c.decode(Int.self, forKey: .stageNumber)
        starThresholds = (3, 5, 8)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id); try c.encode(name, forKey: .name)
        try c.encode(stageName, forKey: .stageName)
        try c.encode(availableNotes, forKey: .availableNotes)
        try c.encode(noteSequence, forKey: .noteSequence)
        try c.encodeIfPresent(melodyName, forKey: .melodyName)
        try c.encode(bossName, forKey: .bossName)
        try c.encode(stageNumber, forKey: .stageNumber)
    }

    // MARK: Predefined levels

    static let allLevels: [GameLevel] = [
        GameLevel(
            id: "pink-pop-1", name: "First Notes", stageName: "Pink Pop Palace",
            availableNotes: [.C, .D, .E],
            noteSequence: [.C, .D, .E, .C, .E, .D, .C, .E],
            melodyName: "Twinkle Star",
            bossName: "Blobby Bounce",
            stageNumber: 1,
            starThresholds: (3, 5, 7)
        ),
        GameLevel(
            id: "pink-pop-2", name: "Three Note Dance", stageName: "Pink Pop Palace",
            availableNotes: [.C, .D, .E],
            noteSequence: [.E, .D, .C, .D, .E, .E, .E, .D, .D, .E],
            melodyName: "Happy March",
            bossName: "Wobbly Woo",
            stageNumber: 2,
            starThresholds: (4, 6, 9)
        ),
        GameLevel(
            id: "neon-note-1", name: "Four Note Fun", stageName: "Neon Note City",
            availableNotes: [.C, .D, .E, .F],
            noteSequence: [.C, .D, .E, .F, .E, .D, .C, .F, .E, .C],
            melodyName: "Dance Steps",
            bossName: "Shadow Shuffle",
            stageNumber: 3,
            starThresholds: (4, 7, 10)
        ),
        GameLevel(
            id: "neon-note-2", name: "Five Fingers", stageName: "Neon Note City",
            availableNotes: [.C, .D, .E, .F, .G],
            noteSequence: [.C, .E, .G, .E, .C, .D, .F, .D, .G, .E, .C],
            melodyName: "Pink Parade",
            bossName: "Jiggly Jam",
            stageNumber: 4
        ),
        GameLevel(
            id: "glitter-moon-1", name: "High Notes!", stageName: "Glitter Moon Stage",
            availableNotes: [.C, .D, .E, .F, .G, .A],
            noteSequence: [.G, .A, .G, .F, .E, .D, .C, .E, .G, .A],
            melodyName: "Neon Bounce",
            bossName: "Dizzy Doodle",
            stageNumber: 5
        ),
        GameLevel(
            id: "glitter-moon-2", name: "Almost There!", stageName: "Glitter Moon Stage",
            availableNotes: [.C, .D, .E, .F, .G, .A, .B],
            noteSequence: [.C, .D, .E, .F, .G, .A, .B, .A, .G, .F, .E, .D, .C],
            melodyName: "Star Shower",
            bossName: "Grumble Groove",
            stageNumber: 6
        ),
        GameLevel(
            id: "rainbow-arena-1", name: "K-pop Star!", stageName: "Rainbow Rhythm Arena",
            availableNotes: PianoNote.allCases,
            noteSequence: [.E, .E, .F, .G, .G, .F, .E, .D, .C, .C, .D, .E],
            melodyName: "K-pop Kick",
            bossName: "Mega Blob King",
            stageNumber: 7
        ),
        GameLevel(
            id: "rainbow-arena-2", name: "Neon Legend", stageName: "Rainbow Rhythm Arena",
            availableNotes: PianoNote.allCases,
            noteSequence: [.G, .G, .A, .B, .B, .A, .G, .F, .E, .E, .F, .G, .G, .F, .F],
            melodyName: "Neon Lights",
            bossName: "Shadow DJ",
            stageNumber: 8
        ),
    ]
}

// MARK: - Characters

struct GameCharacter: Identifiable {
    let id: String
    let name: String
    let emoji: String           // placeholder for sprite
    let description: String
    let role: CharacterRole
}

enum CharacterRole {
    case hero, mascot, boss
}

struct Characters {
    static let djViennaStar = GameCharacter(
        id: "dj-vienna", name: "DJ Vienna Star", emoji: "👩‍🎤",
        description: "A cheerful young piano hero with pink headphones, a glowing keytar, and a sparkly stage outfit!",
        role: .hero
    )
    static let melodyBunny = GameCharacter(
        id: "melody-bunny", name: "Melody Bunny", emoji: "🐰",
        description: "A fluffy pink bunny who dances and cheers when you play notes!", role: .mascot
    )
    static let bassCat = GameCharacter(
        id: "bass-cat", name: "Bass Cat", emoji: "🐱",
        description: "A cool purple cat with neon sunglasses who loves bass notes!", role: .mascot
    )
    static let sparklePanda = GameCharacter(
        id: "sparkle-panda", name: "Sparkle Panda", emoji: "🐼",
        description: "A cuddly panda covered in glitter who rewards you with sparkles!", role: .mascot
    )
    static let rhythmFox = GameCharacter(
        id: "rhythm-fox", name: "Rhythm Fox", emoji: "🦊",
        description: "A quick orange fox who keeps the beat and guides your rhythm!", role: .mascot
    )

    static let allMascots: [GameCharacter] = [melodyBunny, bassCat, sparklePanda, rhythmFox]
}

// MARK: - Shadow Monsters (Bosses)

struct ShadowMonster: Identifiable {
    let id: String
    let name: String
    let emoji: String
    let description: String
    let danceMovesNeeded: Int        // notes to defeat

    static let all: [String: ShadowMonster] = [
        "Blobby Bounce":    ShadowMonster(id: "blobby",   name: "Blobby Bounce",    emoji: "👾", description: "A bouncy purple blob that can't stop hopping!", danceMovesNeeded: 4),
        "Wobbly Woo":       ShadowMonster(id: "wobbly",   name: "Wobbly Woo",       emoji: "🫠", description: "A wiggly shadow that wobbles to the beat!", danceMovesNeeded: 5),
        "Shadow Shuffle":   ShadowMonster(id: "shuffle",  name: "Shadow Shuffle",    emoji: "🕺", description: "A shadowy dancer with two left feet!", danceMovesNeeded: 5),
        "Jiggly Jam":       ShadowMonster(id: "jiggly",   name: "Jiggly Jam",        emoji: "🍮", description: "A jiggly jam monster that loves to wiggle!", danceMovesNeeded: 6),
        "Dizzy Doodle":     ShadowMonster(id: "dizzy",    name: "Dizzy Doodle",      emoji: "😵‍💫", description: "A silly dizzy shadow that spins in circles!", danceMovesNeeded: 6),
        "Grumble Groove":   ShadowMonster(id: "grumble",  name: "Grumble Groove",    emoji: "👻", description: "A grumpy ghost who secretly loves dancing!", danceMovesNeeded: 7),
        "Mega Blob King":   ShadowMonster(id: "megablob", name: "Mega Blob King",    emoji: "👑", description: "The biggest, bounciest blob of them all!", danceMovesNeeded: 8),
        "Shadow DJ":        ShadowMonster(id: "shadowdj", name: "Shadow DJ",         emoji: "🎧", description: "The ultimate shadow DJ — defeat them with music!", danceMovesNeeded: 10),
    ]
}

// MARK: - Rewards / Stickers

enum RewardCategory: String, CaseIterable, Codable {
    case sticker    = "Stickers"
    case badge      = "Badges"
    case crown      = "Crowns"
    case background = "Backgrounds"
    case outfit     = "Outfits"
    case sound      = "Sounds"
}

struct Reward: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let category: RewardCategory
    let emoji: String
    let description: String

    static let allRewards: [Reward] = [
        // Stickers
        Reward(id: "sticker-pink-star",    name: "Pink Star",          category: .sticker,    emoji: "⭐", description: "A shining pink star!"),
        Reward(id: "sticker-neon-heart",   name: "Neon Heart",         category: .sticker,    emoji: "💖", description: "A glowing neon heart!"),
        Reward(id: "sticker-music-note",   name: "Golden Note",        category: .sticker,    emoji: "🎵", description: "A golden music note!"),
        Reward(id: "sticker-rainbow",      name: "Rainbow Sparkle",    category: .sticker,    emoji: "🌈", description: "A beautiful rainbow!"),
        Reward(id: "sticker-diamond",      name: "Diamond Glow",       category: .sticker,    emoji: "💎", description: "A sparkling diamond!"),
        Reward(id: "sticker-butterfly",    name: "Neon Butterfly",     category: .sticker,    emoji: "🦋", description: "A glowing butterfly!"),

        // Badges
        Reward(id: "badge-neon-heart",     name: "Neon Heart Badge",   category: .badge,      emoji: "💝", description: "You earned a Neon Heart!"),
        Reward(id: "badge-first-song",     name: "First Song Badge",   category: .badge,      emoji: "🏅", description: "You played your first song!"),
        Reward(id: "badge-rhythm-star",    name: "Rhythm Star Badge",  category: .badge,      emoji: "🌟", description: "You mastered the rhythm!"),
        Reward(id: "badge-piano-hero",     name: "Piano Hero Badge",   category: .badge,      emoji: "🎖️", description: "Vienna is a Piano Hero!"),

        // Crowns
        Reward(id: "crown-sparkle",        name: "Sparkle Crown",      category: .crown,      emoji: "👑", description: "A sparkly crown for a superstar!"),
        Reward(id: "crown-neon",           name: "Neon Crown",         category: .crown,      emoji: "👑", description: "A glowing neon crown!"),

        // Backgrounds
        Reward(id: "bg-pink-stage",        name: "Pink Concert Stage", category: .background, emoji: "🎪", description: "A pink K-pop concert stage!"),
        Reward(id: "bg-neon-city",         name: "Neon City Night",    category: .background, emoji: "🌃", description: "A neon city at night!"),
        Reward(id: "bg-rainbow-arena",     name: "Rainbow Arena",      category: .background, emoji: "🏟️", description: "A rainbow-lit arena!"),
        Reward(id: "bg-space-stage",       name: "Space Stage",        category: .background, emoji: "🚀", description: "A stage among the stars!"),

        // Outfits
        Reward(id: "outfit-panda-jacket",  name: "Panda's Pink Jacket",   category: .outfit,  emoji: "🧥", description: "Sparkle Panda's pink jacket!"),
        Reward(id: "outfit-bunny-bow",     name: "Bunny's Neon Bow",      category: .outfit,  emoji: "🎀", description: "Melody Bunny's neon bow!"),
        Reward(id: "outfit-cat-shades",    name: "Cat's Star Shades",     category: .outfit,  emoji: "😎", description: "Bass Cat's star sunglasses!"),
        Reward(id: "outfit-fox-cape",      name: "Fox's Glitter Cape",    category: .outfit,  emoji: "🦸", description: "Rhythm Fox's glitter cape!"),

        // Sounds
        Reward(id: "sound-bubble",         name: "Bubble Pop Piano",  category: .sound,      emoji: "🫧", description: "Unlock the Bubble Pop sound!"),
        Reward(id: "sound-synth",          name: "Neon Synth",        category: .sound,      emoji: "🎛️", description: "Unlock the Neon Synth sound!"),
        Reward(id: "sound-musicbox",       name: "Music Box",         category: .sound,      emoji: "🎁", description: "Unlock the Music Box sound!"),
        Reward(id: "sound-kitty",          name: "Kitty Piano",       category: .sound,      emoji: "🐱", description: "Unlock the Kitty Piano sound!"),
    ]
}

// MARK: - Parent Settings

struct ParentSettings: Codable {
    var quietMode: Bool = false
    var practiceMinutes: Int = 10          // 5, 10, or 15
    var difficultyLevel: Int = 1           // 1 = easy, 2 = medium, 3 = hard
    var noteDropSpeed: CGFloat = 3.0       // base speed for falling notes
}
