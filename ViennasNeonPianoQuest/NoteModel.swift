import SwiftUI

// MARK: - Piano Note

enum PianoNote: String, CaseIterable, Identifiable, Codable, Hashable {
    case C, D, E, F, G, A, B

    var id: String { rawValue }

    /// Frequency in Hz (octave 4)
    var frequency: Double {
        switch self {
        case .C: return 261.63
        case .D: return 293.66
        case .E: return 329.63
        case .F: return 349.23
        case .G: return 392.00
        case .A: return 440.00
        case .B: return 493.88
        }
    }

    /// Neon colour for each note
    var neonColor: Color {
        switch self {
        case .C: return Color(red: 1.0, green: 0.08, blue: 0.58)   // Hot pink
        case .D: return Color(red: 1.0, green: 0.41, blue: 0.71)   // Bubblegum pink
        case .E: return Color(red: 0.69, green: 0.0, blue: 1.0)    // Purple
        case .F: return Color(red: 0.0, green: 1.0, blue: 1.0)     // Cyan
        case .G: return Color(red: 0.0, green: 0.5, blue: 1.0)     // Neon blue
        case .A: return Color(red: 0.85, green: 0.0, blue: 1.0)    // Violet
        case .B: return Color(red: 1.0, green: 0.84, blue: 0.0)    // Gold
        }
    }

    var glowColor: Color { neonColor.opacity(0.6) }

    /// Keyboard position index 0–6
    var keyIndex: Int {
        switch self {
        case .C: return 0; case .D: return 1; case .E: return 2
        case .F: return 3; case .G: return 4; case .A: return 5; case .B: return 6
        }
    }

    /// Emoji decoration shown beside note bubble
    var emoji: String {
        switch self {
        case .C: return "💖"; case .D: return "⭐"; case .E: return "🎵"
        case .F: return "✨"; case .G: return "🌟"; case .A: return "💜"; case .B: return "🎶"
        }
    }
}

// MARK: - Falling Note Bubble (Tap the Magic Note)

struct FallingNote: Identifiable {
    let id = UUID()
    let note: PianoNote
    var yOffset: CGFloat = -80       // starts above the visible area
    let speed: CGFloat               // points per tick
    var isActive: Bool = true
    var wasHit: Bool = false

    init(note: PianoNote, speed: CGFloat = 3.0) {
        self.note = note
        self.speed = speed
    }
}

// MARK: - Rhythm Gem (K-pop Rhythm Stage)

struct RhythmGem: Identifiable {
    let id = UUID()
    let note: PianoNote
    let beatIndex: Int               // position in the sequence
    var xOffset: CGFloat             // horizontal travel remaining
    var isActive: Bool = true
    var wasHit: Bool = false
    var rating: HitRating?
}

// MARK: - Hit Rating

enum HitRating: String, CaseIterable {
    case perfect  = "Perfect! ⭐"
    case great    = "Great! 💖"
    case sparkly  = "Sparkly! ✨"
    case amazing  = "Amazing! 🌟"

    var color: Color {
        switch self {
        case .perfect: return .yellow
        case .great:   return .pink
        case .sparkly: return .cyan
        case .amazing: return .purple
        }
    }
}

// MARK: - Melody Sequence (Rescue the Melody)

struct MelodySequence: Identifiable {
    let id = UUID()
    let name: String
    let notes: [PianoNote]
    let difficulty: Int              // 1–5

    static let beginnerMelodies: [MelodySequence] = [
        MelodySequence(name: "Twinkle Star",   notes: [.C, .C, .G, .G, .A, .A, .G], difficulty: 1),
        MelodySequence(name: "Happy March",     notes: [.C, .D, .E, .C, .C, .D, .E, .C], difficulty: 1),
        MelodySequence(name: "Dance Steps",     notes: [.E, .D, .C, .D, .E, .E, .E], difficulty: 2),
        MelodySequence(name: "Pink Parade",     notes: [.C, .E, .G, .E, .C], difficulty: 2),
        MelodySequence(name: "Neon Bounce",     notes: [.G, .A, .B, .A, .G, .F, .E], difficulty: 3),
        MelodySequence(name: "Star Shower",     notes: [.C, .D, .E, .F, .G, .A, .B], difficulty: 3),
        MelodySequence(name: "K-pop Kick",      notes: [.E, .E, .F, .G, .G, .F, .E, .D], difficulty: 4),
        MelodySequence(name: "Neon Lights",     notes: [.G, .G, .A, .B, .B, .A, .G, .F, .E], difficulty: 4),
    ]
}
