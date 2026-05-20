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
