import SwiftUI

struct BossBattleView: View {
    let level: GameLevel
    @EnvironmentObject var gameState: GameState
    @EnvironmentObject var audio: AudioEngine

    @State private var boss: ShadowMonster?
    @State private var sequenceIndex = 0
    @State private var highlightedNote: PianoNote?
    @State private var bossScale: CGFloat = 1.0
    @State private var bossRotation: Double = 0
    @State private var bossOffset: CGFloat = 0
    @State private var stageBrightness: Double = 0.3
    @State private var isVictory = false
    @State private var hitCount = 0
    @State private var showSparkles = false
    @State private var dancePhase = 0

    private var sequence: [PianoNote] { level.noteSequence }

    var body: some View {
        ZStack {
            // Dynamic stage background
            stageBackground

            VStack(spacing: 16) {
                // Header
                header

                Spacer()

                // Boss display
                bossDisplay

                // Progress
                if !isVictory {
                    progressSection
                }

                Spacer()

                // Piano
                PianoKeyboardView(
                    availableNotes: level.availableNotes,
                    highlightedNote: highlightedNote
                ) { note in
                    handleTap(note)
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
                .allowsHitTesting(!isVictory)
            }

            // Victory overlay
            if isVictory {
                victoryOverlay
            }

            // Sparkles
            if showSparkles {
                SparkleOverlay()
            }

            FeedbackToast(text: gameState.feedbackText, isVisible: gameState.showFeedback)
        }
        .onAppear {
            boss = ShadowMonster.all[level.bossName]
            highlightedNote = sequence.first
        }
    }

    // MARK: - Stage Background

    private var stageBackground: some View {
        ZStack {
            NeonGradients.stageBackground.ignoresSafeArea()

            // Dynamic spotlights that get brighter with each hit
            GeometryReader { geo in
                ZStack {
                    Circle()
                        .fill(NeonColors.hotPink.opacity(stageBrightness * 0.3))
                        .frame(width: 400)
                        .blur(radius: 80)
                        .position(x: geo.size.width * 0.3, y: geo.size.height * 0.4)

                    Circle()
                        .fill(NeonColors.violet.opacity(stageBrightness * 0.25))
                        .frame(width: 350)
                        .blur(radius: 70)
                        .position(x: geo.size.width * 0.7, y: geo.size.height * 0.5)

                    Circle()
                        .fill(NeonColors.cyan.opacity(stageBrightness * 0.2))
                        .frame(width: 300)
                        .blur(radius: 60)
                        .position(x: geo.size.width * 0.5, y: geo.size.height * 0.3)
                }
            }
            .allowsHitTesting(false)
            .animation(.easeInOut(duration: 0.5), value: stageBrightness)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            NeonBackButton { gameState.goHome() }
            Spacer()
            VStack(spacing: 2) {
                Text("Boss Dance Battle!")
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundStyle(NeonGradients.pinkGlow)
                Text(level.stageName)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(NeonColors.bubblegum)
            }
            Spacer()
            HStack(spacing: 4) {
                Image(systemName: "star.fill").foregroundColor(NeonColors.gold)
                Text("\(hitCount)")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundColor(NeonColors.gold)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    // MARK: - Boss Display

    private var bossDisplay: some View {
        VStack(spacing: 12) {
            if let boss = boss {
                // Boss emoji with dance animation
                Text(boss.emoji)
                    .font(.system(size: 80))
                    .scaleEffect(bossScale)
                    .rotationEffect(.degrees(bossRotation))
                    .offset(x: bossOffset)
                    .animation(.spring(response: 0.3, dampingFraction: 0.4), value: dancePhase)

                Text(boss.name)
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .neonGlow(NeonColors.violet, radius: 6)

                Text(boss.description)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }

            // DJ Vienna Star cheering
            HStack {
                PulsingMascot(character: Characters.djViennaStar)
                    .scaleEffect(0.6)
                Text(isVictory ? "You did it! 🎉" : "Play the notes to make them dance!")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(NeonColors.bubblegum)
            }
        }
    }

    // MARK: - Progress

    private var progressSection: some View {
        VStack(spacing: 8) {
            // Note sequence indicator
            HStack(spacing: 6) {
                ForEach(Array(sequence.prefix(12).enumerated()), id: \.offset) { idx, note in
                    Circle()
                        .fill(idx < sequenceIndex ? .green : (idx == sequenceIndex ? note.neonColor : note.neonColor.opacity(0.3)))
                        .frame(width: 28, height: 28)
                        .overlay(
                            Text(note.rawValue)
                                .font(.system(size: 12, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                        )
                        .scaleEffect(idx == sequenceIndex ? 1.2 : 1.0)
                }
            }

            RainbowProgressBar(progress: CGFloat(sequenceIndex) / CGFloat(sequence.count))
                .padding(.horizontal, 40)
        }
    }

    // MARK: - Logic

    private func handleTap(_ note: PianoNote) {
        guard !isVictory, sequenceIndex < sequence.count else { return }
        audio.playNote(note)

        let expected = sequence[sequenceIndex]
        if note == expected {
            // Correct hit!
            sequenceIndex += 1
            hitCount += 1
            gameState.scoreHit()

            // Make boss dance
            triggerBossDance()

            // Brighten stage
            stageBrightness = min(1.0, stageBrightness + 0.08)

            // Update highlighted note
            if sequenceIndex < sequence.count {
                highlightedNote = sequence[sequenceIndex]
            } else {
                // Victory!
                highlightedNote = nil
                isVictory = true
                showSparkles = true
                gameState.completeLevel(level, score: hitCount)
            }
        } else {
            gameState.scoreMiss()
        }
    }

    private func triggerBossDance() {
        dancePhase += 1
        let moves = [
            { bossScale = 1.3; bossRotation = 15; bossOffset = 20 },
            { bossScale = 0.8; bossRotation = -10; bossOffset = -25 },
            { bossScale = 1.2; bossRotation = 20; bossOffset = 15 },
            { bossScale = 0.9; bossRotation = -15; bossOffset = -20 },
        ]
        moves[dancePhase % moves.count]()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.spring(response: 0.3)) {
                bossScale = 1.0
                bossRotation = 0
                bossOffset = 0
            }
        }
    }

    // MARK: - Victory Overlay

    private var victoryOverlay: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()

            VStack(spacing: 20) {
                Text("🎉🏆🎉")
                    .font(.system(size: 64))

                Text("You defeated \(boss?.name ?? "the boss")!")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(NeonGradients.pinkGlow)
                    .multilineTextAlignment(.center)

                Text("The stage is saved! 🌟")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(NeonColors.gold)

                StarDisplay(gameState.starsForLevel(level))
                    .scaleEffect(1.5)

                HStack(spacing: 20) {
                    BigNeonButton(title: "Home", emoji: "🏠", color: NeonColors.purple) {
                        gameState.goHome()
                    }
                    BigNeonButton(title: "Level Map", emoji: "🗺️", color: NeonColors.hotPink) {
                        gameState.navigate(to: .levelSelect)
                    }
                }
            }
            .padding(40)
        }
        .transition(.opacity)
    }
}
