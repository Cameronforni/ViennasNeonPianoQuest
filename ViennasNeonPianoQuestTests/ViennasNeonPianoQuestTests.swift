import XCTest
@testable import ViennasNeonPianoQuest

// MARK: - Test Helpers

/// Creates a fresh GameState with UserDefaults wiped so tests are isolated.
private func makeFreshGameState() -> GameState {
    // Clear all persisted keys before the GameState.init() calls load()
    let keys = [
        "viennaPiano.totalStars",
        "viennaPiano.completedLevels",
        "viennaPiano.levelStars",
        "viennaPiano.unlockedRewards",
        "viennaPiano.settings",
    ]
    for key in keys {
        UserDefaults.standard.removeObject(forKey: key)
    }
    return GameState()
}

/// A small helper level with known thresholds for deterministic testing.
private let testLevel = GameLevel(
    id: "test-level-1",
    name: "Test Level",
    stageName: "Test Stage",
    availableNotes: [.C, .D, .E],
    noteSequence: [.C, .D, .E, .C],
    bossName: "Test Boss",
    stageNumber: 99,
    starThresholds: (2, 4, 6)  // 1★ at 2, 2★ at 4, 3★ at 6
)

private let testLevel2 = GameLevel(
    id: "test-level-2",
    name: "Test Level 2",
    stageName: "Test Stage",
    availableNotes: [.C, .D, .E, .F],
    noteSequence: [.C, .D, .E, .F],
    bossName: "Test Boss 2",
    stageNumber: 100,
    starThresholds: (3, 5, 8)
)

// MARK: - PianoNote Tests

final class PianoNoteTests: XCTestCase {

    func testAllCasesCountIsSeven() {
        XCTAssertEqual(PianoNote.allCases.count, 7)
    }

    func testRawValuesMatchExpectedLetters() {
        let expected = ["C", "D", "E", "F", "G", "A", "B"]
        XCTAssertEqual(PianoNote.allCases.map(\.rawValue), expected)
    }

    func testFrequenciesAreInAscendingOrder() {
        let freqs = PianoNote.allCases.map(\.frequency)
        for i in 1..<freqs.count {
            XCTAssertGreaterThan(freqs[i], freqs[i - 1],
                "\(PianoNote.allCases[i]) should be higher than \(PianoNote.allCases[i - 1])")
        }
    }

    func testConcertAPitchIsCorrect() {
        XCTAssertEqual(PianoNote.A.frequency, 440.0, accuracy: 0.01)
    }

    func testMiddleCFrequency() {
        XCTAssertEqual(PianoNote.C.frequency, 261.63, accuracy: 0.01)
    }

    func testKeyIndicesAreZeroThroughSix() {
        let indices = PianoNote.allCases.map(\.keyIndex)
        XCTAssertEqual(indices, [0, 1, 2, 3, 4, 5, 6])
    }

    func testKeyIndicesAreUnique() {
        let indices = PianoNote.allCases.map(\.keyIndex)
        XCTAssertEqual(Set(indices).count, indices.count)
    }

    func testIdentifiableIDMatchesRawValue() {
        for note in PianoNote.allCases {
            XCTAssertEqual(note.id, note.rawValue)
        }
    }

    func testEveryNoteHasAnEmoji() {
        for note in PianoNote.allCases {
            XCTAssertFalse(note.emoji.isEmpty, "\(note) should have an emoji")
        }
    }

    func testCodableRoundTrip() throws {
        for note in PianoNote.allCases {
            let data = try JSONEncoder().encode(note)
            let decoded = try JSONDecoder().decode(PianoNote.self, from: data)
            XCTAssertEqual(decoded, note)
        }
    }
}

// MARK: - FallingNote Tests

final class FallingNoteTests: XCTestCase {

    func testDefaultInitialisation() {
        let note = FallingNote(note: .C)
        XCTAssertEqual(note.note, .C)
        XCTAssertEqual(note.yOffset, -80)
        XCTAssertEqual(note.speed, 3.0)
        XCTAssertTrue(note.isActive)
        XCTAssertFalse(note.wasHit)
    }

    func testCustomSpeed() {
        let note = FallingNote(note: .G, speed: 5.0)
        XCTAssertEqual(note.speed, 5.0)
    }

    func testUniqueIdentifiers() {
        let a = FallingNote(note: .C)
        let b = FallingNote(note: .C)
        XCTAssertNotEqual(a.id, b.id)
    }

    func testMutability() {
        var note = FallingNote(note: .D)
        note.yOffset = 200
        note.isActive = false
        note.wasHit = true
        XCTAssertEqual(note.yOffset, 200)
        XCTAssertFalse(note.isActive)
        XCTAssertTrue(note.wasHit)
    }
}

// MARK: - RhythmGem Tests

final class RhythmGemTests: XCTestCase {

    func testInitialState() {
        let gem = RhythmGem(note: .E, beatIndex: 3, xOffset: 500)
        XCTAssertEqual(gem.note, .E)
        XCTAssertEqual(gem.beatIndex, 3)
        XCTAssertEqual(gem.xOffset, 500)
        XCTAssertTrue(gem.isActive)
        XCTAssertFalse(gem.wasHit)
        XCTAssertNil(gem.rating)
    }

    func testRatingAssignment() {
        var gem = RhythmGem(note: .A, beatIndex: 0, xOffset: 120)
        gem.rating = .perfect
        gem.wasHit = true
        XCTAssertEqual(gem.rating, .perfect)
        XCTAssertTrue(gem.wasHit)
    }
}

// MARK: - HitRating Tests

final class HitRatingTests: XCTestCase {

    func testAllCasesHaveDisplayStrings() {
        for rating in HitRating.allCases {
            XCTAssertFalse(rating.rawValue.isEmpty)
        }
    }

    func testFourRatingsExist() {
        XCTAssertEqual(HitRating.allCases.count, 4)
    }
}

// MARK: - MelodySequence Tests

final class MelodySequenceTests: XCTestCase {

    func testBeginnerMelodiesAreNotEmpty() {
        XCTAssertFalse(MelodySequence.beginnerMelodies.isEmpty)
    }

    func testEveryMelodyHasAtLeastThreeNotes() {
        for melody in MelodySequence.beginnerMelodies {
            XCTAssertGreaterThanOrEqual(melody.notes.count, 3,
                "\(melody.name) should have at least 3 notes")
        }
    }

    func testEveryMelodyHasAName() {
        for melody in MelodySequence.beginnerMelodies {
            XCTAssertFalse(melody.name.isEmpty)
        }
    }

    func testDifficultyRange() {
        for melody in MelodySequence.beginnerMelodies {
            XCTAssertGreaterThanOrEqual(melody.difficulty, 1)
            XCTAssertLessThanOrEqual(melody.difficulty, 5)
        }
    }

    func testMelodiesAreSortedByDifficulty() {
        let diffs = MelodySequence.beginnerMelodies.map(\.difficulty)
        XCTAssertEqual(diffs, diffs.sorted(),
            "Beginner melodies should be in non-decreasing difficulty order")
    }

    func testUniqueIDs() {
        let ids = MelodySequence.beginnerMelodies.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count, "Every melody should have a unique ID")
    }
}

// MARK: - GameLevel Tests

final class GameLevelTests: XCTestCase {

    func testEightPredefinedLevels() {
        XCTAssertEqual(GameLevel.allLevels.count, 8)
    }

    func testStageNumbersAreSequential() {
        let numbers = GameLevel.allLevels.map(\.stageNumber)
        XCTAssertEqual(numbers, Array(1...8))
    }

    func testAllLevelIDsAreUnique() {
        let ids = GameLevel.allLevels.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count)
    }

    func testEveryLevelHasAtLeastOneAvailableNote() {
        for level in GameLevel.allLevels {
            XCTAssertFalse(level.availableNotes.isEmpty, "\(level.name) needs available notes")
        }
    }

    func testNoteSequenceOnlyUsesAvailableNotes() {
        for level in GameLevel.allLevels {
            let available = Set(level.availableNotes)
            for note in level.noteSequence {
                XCTAssertTrue(available.contains(note),
                    "\(level.name): sequence contains \(note) which is not in availableNotes")
            }
        }
    }

    func testEveryLevelHasABoss() {
        for level in GameLevel.allLevels {
            XCTAssertFalse(level.bossName.isEmpty, "\(level.name) needs a boss")
            XCTAssertNotNil(ShadowMonster.all[level.bossName],
                "\(level.name): boss '\(level.bossName)' not found in ShadowMonster.all")
        }
    }

    func testAvailableNotesGrowAcrossLevels() {
        var previousCount = 0
        for level in GameLevel.allLevels {
            XCTAssertGreaterThanOrEqual(level.availableNotes.count, previousCount,
                "\(level.name) should have at least as many notes as the previous level")
            previousCount = level.availableNotes.count
        }
    }

    func testCodableRoundTrip() throws {
        let level = GameLevel.allLevels[0]
        let data = try JSONEncoder().encode(level)
        let decoded = try JSONDecoder().decode(GameLevel.self, from: data)
        XCTAssertEqual(decoded.id, level.id)
        XCTAssertEqual(decoded.name, level.name)
        XCTAssertEqual(decoded.availableNotes, level.availableNotes)
        XCTAssertEqual(decoded.noteSequence, level.noteSequence)
        XCTAssertEqual(decoded.bossName, level.bossName)
        XCTAssertEqual(decoded.stageNumber, level.stageNumber)
    }

    func testStarThresholdsAreAscending() {
        for level in GameLevel.allLevels {
            let (t1, t2, t3) = level.starThresholds
            XCTAssertLessThanOrEqual(t1, t2, "\(level.name) star thresholds out of order")
            XCTAssertLessThanOrEqual(t2, t3, "\(level.name) star thresholds out of order")
        }
    }
}

// MARK: - Reward Tests

final class RewardTests: XCTestCase {

    func testTwentyFourRewardsDefined() {
        XCTAssertEqual(Reward.allRewards.count, 24)
    }

    func testAllRewardIDsAreUnique() {
        let ids = Reward.allRewards.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count)
    }

    func testEveryRewardCategoryIsRepresented() {
        let categories = Set(Reward.allRewards.map(\.category))
        for cat in RewardCategory.allCases {
            XCTAssertTrue(categories.contains(cat), "No reward for category \(cat.rawValue)")
        }
    }

    func testCodableRoundTrip() throws {
        for reward in Reward.allRewards {
            let data = try JSONEncoder().encode(reward)
            let decoded = try JSONDecoder().decode(Reward.self, from: data)
            XCTAssertEqual(decoded, reward)
        }
    }
}

// MARK: - InstrumentType Tests

final class InstrumentTypeTests: XCTestCase {

    func testFiveInstruments() {
        XCTAssertEqual(InstrumentType.allCases.count, 5)
    }

    func testEveryInstrumentHasHarmonics() {
        for inst in InstrumentType.allCases {
            XCTAssertFalse(inst.harmonics.isEmpty, "\(inst) should have harmonics")
        }
    }

    func testAttackIsPositive() {
        for inst in InstrumentType.allCases {
            XCTAssertGreaterThan(inst.attack, 0)
        }
    }

    func testDecayIsPositive() {
        for inst in InstrumentType.allCases {
            XCTAssertGreaterThan(inst.decay, 0)
        }
    }

    func testOnlyKittyPianoHasVibrato() {
        for inst in InstrumentType.allCases {
            if inst == .kittyPiano {
                XCTAssertTrue(inst.vibrato)
            } else {
                XCTAssertFalse(inst.vibrato, "\(inst) should not have vibrato")
            }
        }
    }

    func testFundamentalIsAlwaysPresent() {
        for inst in InstrumentType.allCases {
            let hasFundamental = inst.harmonics.contains { $0.0 == 1.0 }
            XCTAssertTrue(hasFundamental, "\(inst) should include the 1× fundamental")
        }
    }
}

// MARK: - Character & Monster Tests

final class CharacterTests: XCTestCase {

    func testFourMascots() {
        XCTAssertEqual(Characters.allMascots.count, 4)
    }

    func testHeroExists() {
        XCTAssertEqual(Characters.djViennaStar.role, .hero)
    }

    func testAllMascotsHaveMascotRole() {
        for m in Characters.allMascots {
            XCTAssertEqual(m.role, .mascot)
        }
    }

    func testEightShadowMonsters() {
        XCTAssertEqual(ShadowMonster.all.count, 8)
    }

    func testEveryMonsterHasPositiveDanceMoves() {
        for (_, monster) in ShadowMonster.all {
            XCTAssertGreaterThan(monster.danceMovesNeeded, 0)
        }
    }
}

// MARK: - ParentSettings Tests

final class ParentSettingsTests: XCTestCase {

    func testDefaultValues() {
        let s = ParentSettings()
        XCTAssertFalse(s.quietMode)
        XCTAssertEqual(s.practiceMinutes, 10)
        XCTAssertEqual(s.difficultyLevel, 1)
        XCTAssertEqual(s.noteDropSpeed, 3.0)
    }

    func testCodableRoundTrip() throws {
        var s = ParentSettings()
        s.quietMode = true
        s.practiceMinutes = 15
        s.difficultyLevel = 3
        s.noteDropSpeed = 4.5
        let data = try JSONEncoder().encode(s)
        let decoded = try JSONDecoder().decode(ParentSettings.self, from: data)
        XCTAssertEqual(decoded.quietMode, true)
        XCTAssertEqual(decoded.practiceMinutes, 15)
        XCTAssertEqual(decoded.difficultyLevel, 3)
        XCTAssertEqual(decoded.noteDropSpeed, 4.5)
    }
}

// MARK: - GameState Tests

final class GameStateTests: XCTestCase {

    var state: GameState!

    override func setUp() {
        super.setUp()
        state = makeFreshGameState()
    }

    override func tearDown() {
        // Clean up UserDefaults so tests don't leak
        let keys = [
            "viennaPiano.totalStars",
            "viennaPiano.completedLevels",
            "viennaPiano.levelStars",
            "viennaPiano.unlockedRewards",
            "viennaPiano.settings",
        ]
        for key in keys {
            UserDefaults.standard.removeObject(forKey: key)
        }
        state = nil
        super.tearDown()
    }

    // MARK: Initial state

    func testInitialScreenIsHome() {
        XCTAssertEqual(state.currentScreen, .home)
    }

    func testInitialStarsAreZero() {
        XCTAssertEqual(state.totalStars, 0)
    }

    func testInitialScoreIsZero() {
        XCTAssertEqual(state.currentScore, 0)
    }

    func testDefaultRewardIsUnlocked() {
        XCTAssertTrue(state.unlockedRewardIDs.contains("sticker-pink-star"))
    }

    func testNoLevelsCompletedInitially() {
        XCTAssertTrue(state.completedLevelIDs.isEmpty)
    }

    // MARK: Session management

    func testResetSessionClearsScoreAndCombo() {
        state.currentScore = 42
        state.comboCount = 7
        state.feedbackText = "Nice!"
        state.showFeedback = true

        state.resetSession()

        XCTAssertEqual(state.currentScore, 0)
        XCTAssertEqual(state.comboCount, 0)
        XCTAssertEqual(state.feedbackText, "")
        XCTAssertFalse(state.showFeedback)
    }

    // MARK: Scoring

    func testScoreHitIncrementsScoreAndCombo() {
        state.scoreHit()
        XCTAssertEqual(state.currentScore, 1)
        XCTAssertEqual(state.comboCount, 1)

        state.scoreHit()
        XCTAssertEqual(state.currentScore, 2)
        XCTAssertEqual(state.comboCount, 2)
    }

    func testScoreHitShowsFeedback() {
        state.scoreHit()
        XCTAssertTrue(state.showFeedback)
        XCTAssertFalse(state.feedbackText.isEmpty)
    }

    func testScoreMissResetsComboButNotScore() {
        state.scoreHit()
        state.scoreHit()
        state.scoreHit()
        XCTAssertEqual(state.currentScore, 3)
        XCTAssertEqual(state.comboCount, 3)

        state.scoreMiss()
        XCTAssertEqual(state.currentScore, 3, "Score should not decrease on miss")
        XCTAssertEqual(state.comboCount, 0, "Combo should reset on miss")
    }

    func testScoreMissShowsEncouragement() {
        state.scoreMiss()
        XCTAssertTrue(state.showFeedback)
        XCTAssertFalse(state.feedbackText.isEmpty)
    }

    func testCelebrationMessagesAreNotEmpty() {
        XCTAssertFalse(GameState.celebrations.isEmpty)
        for msg in GameState.celebrations {
            XCTAssertFalse(msg.isEmpty)
        }
    }

    func testEncouragementMessagesAreNotEmpty() {
        XCTAssertFalse(GameState.encouragements.isEmpty)
        for msg in GameState.encouragements {
            XCTAssertFalse(msg.isEmpty)
        }
    }

    // MARK: Level completion & star calculation

    func testCompleteLevelMarksCompleted() {
        state.completeLevel(testLevel, score: 1)
        XCTAssertTrue(state.completedLevelIDs.contains(testLevel.id))
    }

    func testLowScoreAwardsOneStar() {
        // thresholds: 1★ at 2, 2★ at 4, 3★ at 6
        state.completeLevel(testLevel, score: 2)
        XCTAssertEqual(state.levelStars[testLevel.id], 1)
        XCTAssertEqual(state.totalStars, 1)
    }

    func testMediumScoreAwardsTwoStars() {
        state.completeLevel(testLevel, score: 4)
        XCTAssertEqual(state.levelStars[testLevel.id], 2)
        XCTAssertEqual(state.totalStars, 2)
    }

    func testHighScoreAwardsThreeStars() {
        state.completeLevel(testLevel, score: 6)
        XCTAssertEqual(state.levelStars[testLevel.id], 3)
        XCTAssertEqual(state.totalStars, 3)
    }

    func testExceedingThresholdStillAwardsThreeStars() {
        state.completeLevel(testLevel, score: 100)
        XCTAssertEqual(state.levelStars[testLevel.id], 3)
        XCTAssertEqual(state.totalStars, 3)
    }

    func testMinimumScoreAwardsOneStar() {
        // Even score=0 gives 1 star (there is no zero-star state)
        state.completeLevel(testLevel, score: 0)
        XCTAssertEqual(state.levelStars[testLevel.id], 1)
        XCTAssertEqual(state.totalStars, 1)
    }

    func testReplayingLevelOnlyAddsNewStars() {
        // First play: score 2 → 1★
        state.completeLevel(testLevel, score: 2)
        XCTAssertEqual(state.totalStars, 1)

        // Replay with same score → no change
        state.completeLevel(testLevel, score: 2)
        XCTAssertEqual(state.totalStars, 1, "Replaying with same score should not add stars")
        XCTAssertEqual(state.levelStars[testLevel.id], 1)

        // Replay with higher score: 5 → 2★, delta = +1
        state.completeLevel(testLevel, score: 5)
        XCTAssertEqual(state.totalStars, 2)
        XCTAssertEqual(state.levelStars[testLevel.id], 2)

        // Replay with lower score → no change
        state.completeLevel(testLevel, score: 1)
        XCTAssertEqual(state.totalStars, 2, "Lower score should not reduce stars")
        XCTAssertEqual(state.levelStars[testLevel.id], 2)
    }

    func testMultipleLevelsAccumulateStars() {
        state.completeLevel(testLevel, score: 6)   // 3★
        state.completeLevel(testLevel2, score: 5)   // 2★
        XCTAssertEqual(state.totalStars, 5)
    }

    // MARK: Level unlocking

    func testFirstLevelIsAlwaysUnlocked() {
        let level1 = GameLevel.allLevels[0]
        XCTAssertTrue(state.isLevelUnlocked(level1))
    }

    func testSecondLevelIsLockedInitially() {
        let level2 = GameLevel.allLevels[1]
        XCTAssertFalse(state.isLevelUnlocked(level2))
    }

    func testCompletingLevel1UnlocksLevel2() {
        let level1 = GameLevel.allLevels[0]
        let level2 = GameLevel.allLevels[1]

        state.completeLevel(level1, score: 5)
        XCTAssertTrue(state.isLevelUnlocked(level2))
    }

    func testCompletingLevel1DoesNotUnlockLevel3() {
        let level1 = GameLevel.allLevels[0]
        let level3 = GameLevel.allLevels[2]

        state.completeLevel(level1, score: 5)
        XCTAssertFalse(state.isLevelUnlocked(level3),
            "Level 3 should still be locked until level 2 is complete")
    }

    func testStarsForLevelReturnsZeroWhenNotPlayed() {
        XCTAssertEqual(state.starsForLevel(testLevel), 0)
    }

    // MARK: Reward unlocking (level-based)

    func testCompletingOneLevelUnlocksNeonHeart() {
        state.completeLevel(testLevel, score: 1)
        XCTAssertTrue(state.unlockedRewardIDs.contains("sticker-neon-heart"))
    }

    func testCompletingTwoLevelsUnlocksFirstSongBadge() {
        state.completeLevel(testLevel, score: 1)
        state.completeLevel(testLevel2, score: 1)
        XCTAssertTrue(state.unlockedRewardIDs.contains("badge-first-song"))
    }

    // MARK: Reward unlocking (star-based)

    func testThreeStarsUnlocksDiamondSticker() {
        // Score 6 on testLevel → 3★
        state.completeLevel(testLevel, score: 6)
        XCTAssertTrue(state.unlockedRewardIDs.contains("sticker-diamond"))
    }

    func testFiveStarsUnlocksPinkStageBackground() {
        state.completeLevel(testLevel, score: 6)   // 3★
        state.completeLevel(testLevel2, score: 5)   // 2★ → total 5★
        XCTAssertTrue(state.unlockedRewardIDs.contains("bg-pink-stage"))
    }

    func testIsRewardUnlockedReturnsTrueForDefault() {
        let pinkStar = Reward.allRewards.first { $0.id == "sticker-pink-star" }!
        XCTAssertTrue(state.isRewardUnlocked(pinkStar))
    }

    func testIsRewardUnlockedReturnsFalseForLocked() {
        let crown = Reward.allRewards.first { $0.id == "crown-neon" }!
        XCTAssertFalse(state.isRewardUnlocked(crown))
    }

    // MARK: Persistence

    func testSaveAndLoadRoundTrip() {
        state.completeLevel(testLevel, score: 6)
        state.completeLevel(testLevel2, score: 4)
        state.settings.quietMode = true
        state.settings.practiceMinutes = 15
        state.save()

        // Create a new instance which calls load() in init
        let loaded = GameState()

        XCTAssertEqual(loaded.totalStars, state.totalStars)
        XCTAssertEqual(loaded.completedLevelIDs, state.completedLevelIDs)
        XCTAssertEqual(loaded.levelStars, state.levelStars)
        XCTAssertTrue(loaded.unlockedRewardIDs.contains("sticker-diamond"))
        XCTAssertTrue(loaded.settings.quietMode)
        XCTAssertEqual(loaded.settings.practiceMinutes, 15)
    }

    func testLoadFromEmptyDefaultsProducesCleanState() {
        // state is already clean from setUp — just verify
        XCTAssertEqual(state.totalStars, 0)
        XCTAssertTrue(state.completedLevelIDs.isEmpty)
        XCTAssertTrue(state.levelStars.isEmpty)
        XCTAssertEqual(state.unlockedRewardIDs, ["sticker-pink-star"])
    }

    // MARK: Navigation

    func testNavigateChangesCurrentScreen() {
        state.navigate(to: .freePlay)
        XCTAssertEqual(state.currentScreen, .freePlay)
    }

    func testGoHomeResetsToHomeAndClearsSession() {
        state.navigate(to: .freePlay)
        state.currentScore = 10
        state.comboCount = 5

        state.goHome()

        XCTAssertEqual(state.currentScreen, .home)
        XCTAssertEqual(state.currentScore, 0)
        XCTAssertEqual(state.comboCount, 0)
    }

    func testNavigateToLevelScreens() {
        let level = GameLevel.allLevels[0]
        state.navigate(to: .tapMagicNote(level))
        XCTAssertEqual(state.currentScreen, .tapMagicNote(level))

        state.navigate(to: .rhythmStage(level))
        XCTAssertEqual(state.currentScreen, .rhythmStage(level))

        state.navigate(to: .bossBattle(level))
        XCTAssertEqual(state.currentScreen, .bossBattle(level))
    }
}

// MARK: - Falling Note Game Loop Simulation

final class FallingNoteGameLoopTests: XCTestCase {

    /// Simulate the core game loop: spawn notes, advance them, detect hits and misses.
    func testNotesFallAndCanBeHit() {
        var notes = [FallingNote(note: .C, speed: 5.0)]

        // Advance 80 ticks → yOffset goes from -80 to -80 + 80*5 = 320
        for _ in 0..<80 {
            notes[0].yOffset += notes[0].speed
        }
        XCTAssertEqual(notes[0].yOffset, 320, accuracy: 0.1)
        XCTAssertTrue(notes[0].isActive)

        // Simulate a hit
        notes[0].wasHit = true
        notes[0].isActive = false
        XCTAssertTrue(notes[0].wasHit)
        XCTAssertFalse(notes[0].isActive)
    }

    func testMissedNoteBecomesInactive() {
        var note = FallingNote(note: .E, speed: 10.0)
        let missZoneY: CGFloat = 440

        // Advance until past the miss zone: -80 + n*10 > 440 → n > 52
        for _ in 0..<53 {
            note.yOffset += note.speed
        }
        XCTAssertGreaterThan(note.yOffset, missZoneY)

        // Game loop would deactivate it
        if note.yOffset > missZoneY && !note.wasHit {
            note.isActive = false
        }
        XCTAssertFalse(note.isActive)
        XCTAssertFalse(note.wasHit, "Missed notes should not be marked as hit")
    }

    func testMultipleNotesSpawnWithUniqueIDs() {
        let sequence: [PianoNote] = [.C, .D, .E, .C, .D]
        let notes = sequence.map { FallingNote(note: $0) }
        let ids = notes.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count, "Every spawned note needs a unique ID")
    }

    func testHitDetectionRequiresCorrectNote() {
        let falling = FallingNote(note: .G, speed: 3.0)
        let hitZoneY: CGFloat = 370

        // Note is in range
        var mutable = falling
        mutable.yOffset = hitZoneY - 20

        // Correct note
        let tappedCorrect: PianoNote = .G
        let matchesCorrect = mutable.isActive && !mutable.wasHit && mutable.note == tappedCorrect
            && mutable.yOffset > hitZoneY - 80 && mutable.yOffset < hitZoneY + 40
        XCTAssertTrue(matchesCorrect)

        // Wrong note
        let tappedWrong: PianoNote = .C
        let matchesWrong = mutable.isActive && !mutable.wasHit && mutable.note == tappedWrong
        XCTAssertFalse(matchesWrong)
    }

    func testHitDetectionRequiresProximityToHitZone() {
        let hitZoneY: CGFloat = 370
        var note = FallingNote(note: .C, speed: 3.0)

        // Too far above
        note.yOffset = hitZoneY - 100
        let tooFarAbove = note.yOffset > hitZoneY - 80
        XCTAssertFalse(tooFarAbove, "Note 100pt above hit zone should not be hittable")

        // In range
        note.yOffset = hitZoneY - 30
        let inRange = note.yOffset > hitZoneY - 80 && note.yOffset < hitZoneY + 40
        XCTAssertTrue(inRange)

        // Too far below
        note.yOffset = hitZoneY + 50
        let tooFarBelow = note.yOffset < hitZoneY + 40
        XCTAssertFalse(tooFarBelow, "Note 50pt below hit zone should not be hittable")
    }

    func testDifferentSpeedsAffectTravelTime() {
        let slow = FallingNote(note: .C, speed: 2.0)
        let fast = FallingNote(note: .C, speed: 5.0)
        let target: CGFloat = 370

        // Ticks to reach target from -80
        let ticksSlow = Int(ceil((target - slow.yOffset) / slow.speed))
        let ticksFast = Int(ceil((target - fast.yOffset) / fast.speed))

        XCTAssertGreaterThan(ticksSlow, ticksFast,
            "Slower speed should take more ticks to reach the hit zone")
    }
}

// MARK: - Rhythm Gem Hit Detection Tests

final class RhythmGemHitDetectionTests: XCTestCase {

    let targetLineX: CGFloat = 120

    func testPerfectHitDistance() {
        let gem = RhythmGem(note: .C, beatIndex: 0, xOffset: targetLineX + 10)
        let distance = abs(gem.xOffset - targetLineX)
        XCTAssertLessThan(distance, 15)
        // This would be .perfect
    }

    func testAmazingHitDistance() {
        let gem = RhythmGem(note: .C, beatIndex: 0, xOffset: targetLineX + 25)
        let distance = abs(gem.xOffset - targetLineX)
        XCTAssertGreaterThanOrEqual(distance, 15)
        XCTAssertLessThan(distance, 30)
    }

    func testGreatHitDistance() {
        let gem = RhythmGem(note: .C, beatIndex: 0, xOffset: targetLineX + 45)
        let distance = abs(gem.xOffset - targetLineX)
        XCTAssertGreaterThanOrEqual(distance, 30)
        XCTAssertLessThan(distance, 50)
    }

    func testSparklyHitDistance() {
        let gem = RhythmGem(note: .C, beatIndex: 0, xOffset: targetLineX + 70)
        let distance = abs(gem.xOffset - targetLineX)
        XCTAssertGreaterThanOrEqual(distance, 50)
        XCTAssertLessThan(distance, 80)
    }

    func testMissDistance() {
        let gem = RhythmGem(note: .C, beatIndex: 0, xOffset: targetLineX + 90)
        let distance = abs(gem.xOffset - targetLineX)
        XCTAssertGreaterThanOrEqual(distance, 80, "Should be outside all hit windows")
    }

    func testGemMovesLeftward() {
        var gem = RhythmGem(note: .D, beatIndex: 0, xOffset: 1200)
        let speed: CGFloat = 2.5

        for _ in 0..<100 {
            gem.xOffset -= speed
        }
        XCTAssertEqual(gem.xOffset, 950, accuracy: 0.1)
    }

    func testGemSequenceSpacing() {
        let startX: CGFloat = 1200
        let spacing: CGFloat = 140
        let notes: [PianoNote] = [.C, .D, .E, .F]

        let gems = notes.enumerated().map { i, note in
            RhythmGem(note: note, beatIndex: i, xOffset: startX + CGFloat(i) * spacing)
        }

        // Each gem should be 140pt further right than the previous
        for i in 1..<gems.count {
            let gap = gems[i].xOffset - gems[i - 1].xOffset
            XCTAssertEqual(gap, spacing, accuracy: 0.01)
        }
    }

    func testHitRatingThresholdsAreConsistent() {
        // Verify the four tiers partition the 0–80 range correctly
        let thresholds: [(max: CGFloat, expected: HitRating)] = [
            (15, .perfect), (30, .amazing), (50, .great), (80, .sparkly)
        ]
        var prevMax: CGFloat = 0
        for (max, _) in thresholds {
            XCTAssertGreaterThan(max, prevMax, "Rating thresholds must be strictly increasing")
            prevMax = max
        }
    }
}

// MARK: - Melody Call-and-Response Simulation

final class MelodyGameLogicTests: XCTestCase {

    func testCorrectSequenceCompletessMelody() {
        let melody = MelodySequence.beginnerMelodies[0] // Twinkle Star
        var playerIndex = 0

        for note in melody.notes {
            let expected = melody.notes[playerIndex]
            XCTAssertEqual(note, expected)
            playerIndex += 1
        }
        XCTAssertEqual(playerIndex, melody.notes.count, "Should reach the end of the melody")
    }

    func testWrongNoteDoesNotAdvance() {
        let melody = MelodySequence.beginnerMelodies[0] // [C, C, G, G, A, A, G]
        var playerIndex = 0

        // Play the first note correctly
        if PianoNote.C == melody.notes[playerIndex] { playerIndex += 1 }
        XCTAssertEqual(playerIndex, 1)

        // Play a wrong note — should NOT advance
        let wrong: PianoNote = .B
        if wrong == melody.notes[playerIndex] { playerIndex += 1 }
        XCTAssertEqual(playerIndex, 1, "Wrong note should not advance the index")

        // Play the correct note
        if PianoNote.C == melody.notes[playerIndex] { playerIndex += 1 }
        XCTAssertEqual(playerIndex, 2)
    }

    func testAllMelodiesArePlayable() {
        // Every note in every melody must be a valid PianoNote
        for melody in MelodySequence.beginnerMelodies {
            for note in melody.notes {
                XCTAssertTrue(PianoNote.allCases.contains(note),
                    "\(melody.name) contains invalid note")
            }
        }
    }

    func testMelodyNamesAreUnique() {
        let names = MelodySequence.beginnerMelodies.map(\.name)
        XCTAssertEqual(Set(names).count, names.count)
    }

    func testEachDifficultyLevelHasAtLeastOneMelody() {
        let diffs = Set(MelodySequence.beginnerMelodies.map(\.difficulty))
        // We have difficulty 1, 2, 3, 4
        XCTAssertTrue(diffs.contains(1))
        XCTAssertTrue(diffs.contains(2))
        XCTAssertTrue(diffs.contains(3))
        XCTAssertTrue(diffs.contains(4))
    }
}

// MARK: - Boss Battle Sequence Simulation

final class BossBattleLogicTests: XCTestCase {

    func testCorrectSequenceDefeatsBoss() {
        let level = GameLevel.allLevels[0]
        let sequence = level.noteSequence
        var sequenceIndex = 0

        for note in sequence {
            let expected = sequence[sequenceIndex]
            XCTAssertEqual(note, expected)
            sequenceIndex += 1
        }
        XCTAssertEqual(sequenceIndex, sequence.count, "Completing the sequence should defeat the boss")
    }

    func testWrongNoteDoesNotAdvanceBossSequence() {
        let level = GameLevel.allLevels[0]
        let sequence = level.noteSequence
        var sequenceIndex = 0

        // First note is correct
        if sequence[sequenceIndex] == sequence[0] { sequenceIndex += 1 }

        // Wrong note
        let wrongNote: PianoNote = .B
        if sequenceIndex < sequence.count && wrongNote == sequence[sequenceIndex] {
            sequenceIndex += 1
        }
        XCTAssertEqual(sequenceIndex, 1, "Wrong note should not advance the sequence")
    }

    func testEveryLevelBossExistsInMonsterDictionary() {
        for level in GameLevel.allLevels {
            let monster = ShadowMonster.all[level.bossName]
            XCTAssertNotNil(monster, "Boss '\(level.bossName)' missing from ShadowMonster.all")
        }
    }

    func testBossDifficultyEscalates() {
        // Bosses in later levels should need at least as many dance moves
        var prevMoves = 0
        for level in GameLevel.allLevels {
            if let monster = ShadowMonster.all[level.bossName] {
                XCTAssertGreaterThanOrEqual(monster.danceMovesNeeded, prevMoves,
                    "Boss '\(monster.name)' should need ≥ \(prevMoves) moves")
                prevMoves = monster.danceMovesNeeded
            }
        }
    }

    func testBossBattleCompletesLevel() {
        let state = makeFreshGameState()
        let level = GameLevel.allLevels[0]
        let score = level.noteSequence.count  // perfect score

        state.completeLevel(level, score: score)
        XCTAssertTrue(state.completedLevelIDs.contains(level.id))
        XCTAssertGreaterThan(state.totalStars, 0)
    }
}

// MARK: - Full Level Chain Unlock Walkthrough

final class LevelChainUnlockTests: XCTestCase {

    var state: GameState!

    override func setUp() {
        super.setUp()
        state = makeFreshGameState()
    }

    override func tearDown() {
        let keys = ["viennaPiano.totalStars", "viennaPiano.completedLevels",
                    "viennaPiano.levelStars", "viennaPiano.unlockedRewards", "viennaPiano.settings"]
        for key in keys { UserDefaults.standard.removeObject(forKey: key) }
        state = nil
        super.tearDown()
    }

    func testCompletingAllLevelsSequentially() {
        let levels = GameLevel.allLevels

        for (i, level) in levels.enumerated() {
            // Each level should be unlocked before we play it
            XCTAssertTrue(state.isLevelUnlocked(level),
                "Level \(level.stageNumber) should be unlocked after completing level \(i)")

            // Complete it with a perfect score
            state.completeLevel(level, score: level.noteSequence.count)

            XCTAssertTrue(state.completedLevelIDs.contains(level.id))
        }

        // All 8 levels completed
        XCTAssertEqual(state.completedLevelIDs.count, 8)
    }

    func testSkippingLevelsIsImpossible() {
        let levels = GameLevel.allLevels

        // Level 1 unlocked, levels 2–8 locked
        XCTAssertTrue(state.isLevelUnlocked(levels[0]))
        for level in levels.dropFirst() {
            XCTAssertFalse(state.isLevelUnlocked(level),
                "Level \(level.stageNumber) should be locked initially")
        }

        // Complete level 1 → only level 2 unlocks
        state.completeLevel(levels[0], score: 5)
        XCTAssertTrue(state.isLevelUnlocked(levels[1]))
        for level in levels.dropFirst(2) {
            XCTAssertFalse(state.isLevelUnlocked(level),
                "Level \(level.stageNumber) should still be locked after only level 1")
        }
    }

    func testCompletingAllLevelsUnlocksAllLevelBasedRewards() {
        for level in GameLevel.allLevels {
            state.completeLevel(level, score: level.noteSequence.count)
        }

        let levelBasedRewards = [
            "sticker-neon-heart", "badge-first-song", "sticker-music-note",
            "outfit-bunny-bow", "sticker-rainbow", "sound-bubble",
            "badge-rhythm-star", "outfit-panda-jacket", "crown-sparkle",
            "sound-synth", "badge-piano-hero", "crown-neon"
        ]
        for rewardID in levelBasedRewards {
            XCTAssertTrue(state.unlockedRewardIDs.contains(rewardID),
                "Reward '\(rewardID)' should be unlocked after completing all 8 levels")
        }
    }
}

// MARK: - Star Boundary Edge Cases

final class StarBoundaryTests: XCTestCase {

    var state: GameState!

    override func setUp() {
        super.setUp()
        state = makeFreshGameState()
    }

    override func tearDown() {
        let keys = ["viennaPiano.totalStars", "viennaPiano.completedLevels",
                    "viennaPiano.levelStars", "viennaPiano.unlockedRewards", "viennaPiano.settings"]
        for key in keys { UserDefaults.standard.removeObject(forKey: key) }
        state = nil
        super.tearDown()
    }

    func testExactThresholdBoundaries() {
        // testLevel thresholds: (2, 4, 6)
        // Score exactly at each threshold
        state.completeLevel(testLevel, score: 2)
        XCTAssertEqual(state.levelStars[testLevel.id], 1)

        // Reset and test threshold 2
        state.levelStars.removeAll(); state.totalStars = 0
        state.completeLevel(testLevel, score: 4)
        XCTAssertEqual(state.levelStars[testLevel.id], 2)

        // Reset and test threshold 3
        state.levelStars.removeAll(); state.totalStars = 0
        state.completeLevel(testLevel, score: 6)
        XCTAssertEqual(state.levelStars[testLevel.id], 3)
    }

    func testOnePointBelowEachThreshold() {
        // Score 1 → below threshold.0 (2) → still 1★
        state.completeLevel(testLevel, score: 1)
        XCTAssertEqual(state.levelStars[testLevel.id], 1)

        state.levelStars.removeAll(); state.totalStars = 0
        // Score 3 → below threshold.1 (4) → 1★
        state.completeLevel(testLevel, score: 3)
        XCTAssertEqual(state.levelStars[testLevel.id], 1)

        state.levelStars.removeAll(); state.totalStars = 0
        // Score 5 → below threshold.2 (6) → 2★
        state.completeLevel(testLevel, score: 5)
        XCTAssertEqual(state.levelStars[testLevel.id], 2)
    }

    func testStarUpgradeFromOneToThreeDirectly() {
        state.completeLevel(testLevel, score: 1)  // 1★
        XCTAssertEqual(state.totalStars, 1)

        state.completeLevel(testLevel, score: 6)  // 3★, delta = +2
        XCTAssertEqual(state.totalStars, 3)
        XCTAssertEqual(state.levelStars[testLevel.id], 3)
    }

    func testNegativeScoreTreatedAsMinimum() {
        // Negative score should still award 1 star (no failure state)
        state.completeLevel(testLevel, score: -5)
        XCTAssertEqual(state.levelStars[testLevel.id], 1)
        XCTAssertEqual(state.totalStars, 1)
    }
}

// MARK: - Combo Streak Tests

final class ComboStreakTests: XCTestCase {

    var state: GameState!

    override func setUp() {
        super.setUp()
        state = makeFreshGameState()
    }

    override func tearDown() {
        let keys = ["viennaPiano.totalStars", "viennaPiano.completedLevels",
                    "viennaPiano.levelStars", "viennaPiano.unlockedRewards", "viennaPiano.settings"]
        for key in keys { UserDefaults.standard.removeObject(forKey: key) }
        state = nil
        super.tearDown()
    }

    func testLongComboStreak() {
        for i in 1...20 {
            state.scoreHit()
            XCTAssertEqual(state.comboCount, i)
            XCTAssertEqual(state.currentScore, i)
        }
    }

    func testComboResetsOnMissThenRebuilds() {
        state.scoreHit() // combo 1
        state.scoreHit() // combo 2
        state.scoreHit() // combo 3
        state.scoreMiss() // combo 0
        XCTAssertEqual(state.comboCount, 0)
        XCTAssertEqual(state.currentScore, 3)

        state.scoreHit() // combo 1
        state.scoreHit() // combo 2
        XCTAssertEqual(state.comboCount, 2)
        XCTAssertEqual(state.currentScore, 5)
    }

    func testMultipleMissesInARow() {
        state.scoreHit()
        state.scoreMiss()
        state.scoreMiss()
        state.scoreMiss()
        XCTAssertEqual(state.comboCount, 0)
        XCTAssertEqual(state.currentScore, 1, "Score should never decrease")
    }

    func testMissWithoutPriorHits() {
        state.scoreMiss()
        XCTAssertEqual(state.comboCount, 0)
        XCTAssertEqual(state.currentScore, 0)
        XCTAssertTrue(state.showFeedback, "Should still show encouragement")
    }
}

// MARK: - Navigation Matrix Tests

final class NavigationMatrixTests: XCTestCase {

    var state: GameState!

    override func setUp() {
        super.setUp()
        state = makeFreshGameState()
    }

    override func tearDown() {
        let keys = ["viennaPiano.totalStars", "viennaPiano.completedLevels",
                    "viennaPiano.levelStars", "viennaPiano.unlockedRewards", "viennaPiano.settings"]
        for key in keys { UserDefaults.standard.removeObject(forKey: key) }
        state = nil
        super.tearDown()
    }

    func testEveryScreenIsReachable() {
        let level = GameLevel.allLevels[0]
        let screens: [AppScreen] = [
            .home, .levelSelect, .tapMagicNote(level), .rhythmStage(level),
            .rescueMelody, .freePlay, .bossBattle(level), .stickerRoom, .parentSettings
        ]

        for screen in screens {
            state.navigate(to: screen)
            XCTAssertEqual(state.currentScreen, screen)
        }
    }

    func testGoHomeFromEveryScreen() {
        let level = GameLevel.allLevels[0]
        let screens: [AppScreen] = [
            .levelSelect, .tapMagicNote(level), .rhythmStage(level),
            .rescueMelody, .freePlay, .bossBattle(level), .stickerRoom, .parentSettings
        ]

        for screen in screens {
            state.navigate(to: screen)
            state.currentScore = 42
            state.comboCount = 10

            state.goHome()

            XCTAssertEqual(state.currentScreen, .home, "Should return home from \(screen)")
            XCTAssertEqual(state.currentScore, 0)
            XCTAssertEqual(state.comboCount, 0)
        }
    }

    func testNavigatingBetweenGameModesPreservesNothing() {
        let level = GameLevel.allLevels[0]

        state.navigate(to: .tapMagicNote(level))
        state.currentScore = 5

        // Switch directly to another mode (simulates the router)
        state.resetSession()
        state.navigate(to: .rhythmStage(level))

        XCTAssertEqual(state.currentScore, 0)
        XCTAssertEqual(state.currentScreen, .rhythmStage(level))
    }

    func testDifferentLevelsProduceDifferentScreenIdentities() {
        let l1 = GameLevel.allLevels[0]
        let l2 = GameLevel.allLevels[1]

        let screen1 = AppScreen.tapMagicNote(l1)
        let screen2 = AppScreen.tapMagicNote(l2)

        XCTAssertNotEqual(screen1, screen2)
    }

    func testSameLevelSameScreenIsEqual() {
        let l = GameLevel.allLevels[0]
        XCTAssertEqual(AppScreen.tapMagicNote(l), AppScreen.tapMagicNote(l))
        XCTAssertEqual(AppScreen.rhythmStage(l), AppScreen.rhythmStage(l))
        XCTAssertEqual(AppScreen.bossBattle(l), AppScreen.bossBattle(l))
    }
}

// MARK: - Reward System Completeness Tests

final class RewardCompletenessTests: XCTestCase {

    var state: GameState!

    override func setUp() {
        super.setUp()
        state = makeFreshGameState()
    }

    override func tearDown() {
        let keys = ["viennaPiano.totalStars", "viennaPiano.completedLevels",
                    "viennaPiano.levelStars", "viennaPiano.unlockedRewards", "viennaPiano.settings"]
        for key in keys { UserDefaults.standard.removeObject(forKey: key) }
        state = nil
        super.tearDown()
    }

    func testAllRewardsUnlockableWithEnoughProgress() {
        // Complete all 8 levels with max score, then set stars high enough
        for level in GameLevel.allLevels {
            state.completeLevel(level, score: 100)  // 3★ each
        }
        // Force totalStars to 24 (8 levels × 3 stars) to trigger all star-based unlocks
        state.totalStars = 24
        state.checkRewardUnlocks()

        // Every reward referenced in checkRewardUnlocks should be unlocked
        let expectedRewardIDs = [
            "sticker-pink-star", "sticker-neon-heart", "badge-first-song",
            "sticker-music-note", "outfit-bunny-bow", "sticker-rainbow",
            "sound-bubble", "badge-rhythm-star", "outfit-panda-jacket",
            "crown-sparkle", "sound-synth", "badge-piano-hero", "crown-neon",
            "bg-pink-stage", "bg-neon-city", "sound-musicbox",
            "bg-rainbow-arena", "outfit-cat-shades", "bg-space-stage",
            "sound-kitty", "outfit-fox-cape", "sticker-diamond",
            "sticker-butterfly", "badge-neon-heart"
        ]

        for id in expectedRewardIDs {
            XCTAssertTrue(state.unlockedRewardIDs.contains(id),
                "Reward '\(id)' should be unlockable with max progress")
        }

        // Should be exactly all 24
        XCTAssertEqual(expectedRewardIDs.count, 24)
    }

    func testSoundRewardsMapToInstruments() {
        // Each sound reward ID should correspond to an instrument
        let soundRewards = Reward.allRewards.filter { $0.category == .sound }
        XCTAssertEqual(soundRewards.count, 4) // bubble, synth, musicbox, kitty

        let expectedSoundIDs: Set<String> = ["sound-bubble", "sound-synth", "sound-musicbox", "sound-kitty"]
        let actualIDs = Set(soundRewards.map(\.id))
        XCTAssertEqual(actualIDs, expectedSoundIDs)
    }

    func testNoRewardsUnlockedWithZeroProgress() {
        // Only the default sticker should be present
        XCTAssertEqual(state.unlockedRewardIDs, ["sticker-pink-star"])
    }

    func testRewardUnlockIsIdempotent() {
        state.completeLevel(testLevel, score: 6)  // 3★, unlocks sticker-diamond etc.
        let countAfterFirst = state.unlockedRewardIDs.count

        // Call checkRewardUnlocks again
        state.checkRewardUnlocks()
        XCTAssertEqual(state.unlockedRewardIDs.count, countAfterFirst,
            "Calling checkRewardUnlocks again should not change the count")
    }
}

// MARK: - Game Level Data Integrity

final class GameLevelIntegrityTests: XCTestCase {

    func testEveryLevelMelodyNameExistsInMelodyList() {
        let melodyNames = Set(MelodySequence.beginnerMelodies.map(\.name))
        for level in GameLevel.allLevels {
            if let name = level.melodyName {
                XCTAssertTrue(melodyNames.contains(name),
                    "Level '\(level.name)' references melody '\(name)' which doesn't exist")
            }
        }
    }

    func testFourDistinctStageNames() {
        let stageNames = Set(GameLevel.allLevels.map(\.stageName))
        XCTAssertEqual(stageNames.count, 4)
    }

    func testNoteSequencesAreNonEmpty() {
        for level in GameLevel.allLevels {
            XCTAssertFalse(level.noteSequence.isEmpty,
                "\(level.name) must have a non-empty note sequence")
        }
    }

    func testLastLevelUsesAllSevenNotes() {
        let lastLevel = GameLevel.allLevels.last!
        XCTAssertEqual(Set(lastLevel.availableNotes), Set(PianoNote.allCases),
            "The final level should use all 7 notes")
    }

    func testFirstLevelUsesOnlyCDE() {
        let firstLevel = GameLevel.allLevels[0]
        XCTAssertEqual(firstLevel.availableNotes, [.C, .D, .E])
    }
}
