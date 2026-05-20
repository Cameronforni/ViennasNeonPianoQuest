import SwiftUI
import Combine

// MARK: - Navigation

enum AppScreen: Hashable {
    case home
    case levelSelect
    case tapMagicNote(GameLevel)
    case rhythmStage(GameLevel)
    case rescueMelody
    case freePlay
    case bossBattle(GameLevel)
    case stickerRoom
    case parentSettings
}

// MARK: - Game State

class GameState: ObservableObject {

    // Navigation
    @Published var currentScreen: AppScreen = .home
    @Published var navigationPath: [AppScreen] = []

    // Progress
    @Published var totalStars: Int = 0
    @Published var completedLevelIDs: Set<String> = []
    @Published var levelStars: [String: Int] = [:]       // levelID -> star count

    // Rewards
    @Published var unlockedRewardIDs: Set<String> = []

    // Current session
    @Published var currentScore: Int = 0
    @Published var comboCount: Int = 0
    @Published var feedbackText: String = ""
    @Published var showFeedback: Bool = false

    // Settings
    @Published var settings: ParentSettings = ParentSettings()

    // Encouraging messages
    static let encouragements = [
        "Try again, superstar! ⭐",
        "You're doing great! 💖",
        "Almost there! Keep going! ✨",
        "Music is about having fun! 🎵",
        "You're a natural! 🌟",
        "So close! Try once more! 💜",
    ]

    static let celebrations = [
        "Amazing! 🌟",
        "Perfect! ⭐",
        "Sparkly! ✨",
        "You're a star! 💖",
        "Incredible! 🎵",
        "Superstar! 👑",
        "Wow! 💜",
        "Neon hit! 🎶",
    ]

    // MARK: - Persistence Keys

    private let starsKey          = "viennaPiano.totalStars"
    private let completedKey      = "viennaPiano.completedLevels"
    private let levelStarsKey     = "viennaPiano.levelStars"
    private let rewardsKey        = "viennaPiano.unlockedRewards"
    private let settingsKey       = "viennaPiano.settings"

    init() {
        load()
        // Start with some default rewards unlocked
        if unlockedRewardIDs.isEmpty {
            unlockedRewardIDs.insert("sticker-pink-star")
        }
    }

    // MARK: - Actions

    func navigate(to screen: AppScreen) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            currentScreen = screen
        }
    }

    func goHome() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            currentScreen = .home
            resetSession()
        }
    }

    func resetSession() {
        currentScore = 0
        comboCount = 0
        feedbackText = ""
        showFeedback = false
    }

    // MARK: - Scoring

    func scoreHit() {
        currentScore += 1
        comboCount += 1
        showCelebration()
    }

    func scoreMiss() {
        comboCount = 0
        showEncouragement()
    }

    func showCelebration() {
        feedbackText = Self.celebrations.randomElement() ?? "Great!"
        showFeedback = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.showFeedback = false
        }
    }

    func showEncouragement() {
        feedbackText = Self.encouragements.randomElement() ?? "Try again!"
        showFeedback = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.showFeedback = false
        }
    }

    // MARK: - Level Completion

    func completeLevel(_ level: GameLevel, score: Int) {
        completedLevelIDs.insert(level.id)

        // Calculate stars
        let stars: Int
        if score >= level.starThresholds.2 {
            stars = 3
        } else if score >= level.starThresholds.1 {
            stars = 2
        } else {
            stars = 1
        }

        let previousStars = levelStars[level.id] ?? 0
        if stars > previousStars {
            let newStars = stars - previousStars
            totalStars += newStars
            levelStars[level.id] = stars
        }

        // Check for reward unlocks
        checkRewardUnlocks()
        save()
    }

    // MARK: - Reward System

    func checkRewardUnlocks() {
        let completed = completedLevelIDs.count

        // Unlock stickers based on progress
        if completed >= 1 { unlockedRewardIDs.insert("sticker-neon-heart") }
        if completed >= 2 { unlockedRewardIDs.insert("badge-first-song") }
        if completed >= 3 { unlockedRewardIDs.insert("sticker-music-note") }
        if completed >= 4 { unlockedRewardIDs.insert("outfit-bunny-bow") }
        if completed >= 5 { unlockedRewardIDs.insert("sticker-rainbow") }
        if completed >= 5 { unlockedRewardIDs.insert("sound-bubble") }
        if completed >= 6 { unlockedRewardIDs.insert("badge-rhythm-star") }
        if completed >= 6 { unlockedRewardIDs.insert("outfit-panda-jacket") }
        if completed >= 7 { unlockedRewardIDs.insert("crown-sparkle") }
        if completed >= 7 { unlockedRewardIDs.insert("sound-synth") }
        if completed >= 8 { unlockedRewardIDs.insert("badge-piano-hero") }
        if completed >= 8 { unlockedRewardIDs.insert("crown-neon") }

        // Star-based unlocks
        if totalStars >= 5  { unlockedRewardIDs.insert("bg-pink-stage") }
        if totalStars >= 10 { unlockedRewardIDs.insert("bg-neon-city") }
        if totalStars >= 10 { unlockedRewardIDs.insert("sound-musicbox") }
        if totalStars >= 15 { unlockedRewardIDs.insert("bg-rainbow-arena") }
        if totalStars >= 15 { unlockedRewardIDs.insert("outfit-cat-shades") }
        if totalStars >= 20 { unlockedRewardIDs.insert("bg-space-stage") }
        if totalStars >= 20 { unlockedRewardIDs.insert("sound-kitty") }
        if totalStars >= 20 { unlockedRewardIDs.insert("outfit-fox-cape") }
        if totalStars >= 3  { unlockedRewardIDs.insert("sticker-diamond") }
        if totalStars >= 8  { unlockedRewardIDs.insert("sticker-butterfly") }
        if totalStars >= 12 { unlockedRewardIDs.insert("badge-neon-heart") }
    }

    func isRewardUnlocked(_ reward: Reward) -> Bool {
        unlockedRewardIDs.contains(reward.id)
    }

    func isLevelUnlocked(_ level: GameLevel) -> Bool {
        if level.stageNumber == 1 { return true }
        // Unlock next level when the previous one is completed
        let previousID = GameLevel.allLevels.first { $0.stageNumber == level.stageNumber - 1 }?.id
        if let prevID = previousID {
            return completedLevelIDs.contains(prevID)
        }
        return false
    }

    func starsForLevel(_ level: GameLevel) -> Int {
        levelStars[level.id] ?? 0
    }

    // MARK: - Persistence

    func save() {
        UserDefaults.standard.set(totalStars, forKey: starsKey)
        if let data = try? JSONEncoder().encode(Array(completedLevelIDs)) {
            UserDefaults.standard.set(data, forKey: completedKey)
        }
        if let data = try? JSONEncoder().encode(levelStars) {
            UserDefaults.standard.set(data, forKey: levelStarsKey)
        }
        if let data = try? JSONEncoder().encode(Array(unlockedRewardIDs)) {
            UserDefaults.standard.set(data, forKey: rewardsKey)
        }
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: settingsKey)
        }
    }

    func load() {
        totalStars = UserDefaults.standard.integer(forKey: starsKey)

        if let data = UserDefaults.standard.data(forKey: completedKey),
           let ids = try? JSONDecoder().decode([String].self, from: data) {
            completedLevelIDs = Set(ids)
        }
        if let data = UserDefaults.standard.data(forKey: levelStarsKey),
           let dict = try? JSONDecoder().decode([String: Int].self, from: data) {
            levelStars = dict
        }
        if let data = UserDefaults.standard.data(forKey: rewardsKey),
           let ids = try? JSONDecoder().decode([String].self, from: data) {
            unlockedRewardIDs = Set(ids)
        }
        if let data = UserDefaults.standard.data(forKey: settingsKey),
           let s = try? JSONDecoder().decode(ParentSettings.self, from: data) {
            settings = s
        }
    }
}
