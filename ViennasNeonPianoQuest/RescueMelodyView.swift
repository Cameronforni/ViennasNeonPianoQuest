import SwiftUI

struct RescueMelodyView: View {
    @EnvironmentObject var gameState: GameState
    @EnvironmentObject var audio: AudioEngine

    @State private var currentMelodyIndex = 0
    @State private var phase: MelodyPhase = .intro
    @State private var playerIndex = 0            // which note the player is on
    @State private var highlightedNote: PianoNote?
    @State private var playbackIndex = -1         // which note is being played back
    @State private var correctCount = 0
    @State private var showSparkle = false

    private var melodies: [MelodySequence] { MelodySequence.beginnerMelodies }
    private var currentMelody: MelodySequence { melodies[currentMelodyIndex % melodies.count] }

    enum MelodyPhase {
        case intro, listening, playing, success, allDone
    }

    var body: some View {
        ZStack {
            NeonGradients.stageBackground.ignoresSafeArea()

            VStack(spacing: 16) {
                // Header
                header

                Spacer()

                // Melody display
                melodyDisplay

                // Phase instructions
                instructionText

                // Note sequence indicator
                noteSequenceBar

                Spacer()

                // Piano
                PianoKeyboardView(
                    availableNotes: PianoNote.allCases,
                    highlightedNote: highlightedNote
                ) { note in
                    handleTap(note)
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
                .allowsHitTesting(phase == .playing)
            }

            // Sparkle celebration
            if showSparkle {
                SparkleOverlay()
            }

            FeedbackToast(text: gameState.feedbackText, isVisible: gameState.showFeedback)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            NeonBackButton { gameState.goHome() }
            Spacer()
            Text("Rescue the Melody")
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundStyle(NeonGradients.pinkGlow)
            Spacer()
            Text("🎵 \(currentMelodyIndex + 1)/\(melodies.count)")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(NeonColors.gold)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    // MARK: - Melody Display

    private var melodyDisplay: some View {
        VStack(spacing: 12) {
            Text(currentMelody.name)
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundColor(.white)

            // Mascot
            HStack(spacing: 16) {
                PulsingMascot(character: Characters.melodyBunny)
                    .scaleEffect(0.8)

                VStack(alignment: .leading, spacing: 4) {
                    Text(phaseMessage)
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
    }

    private var phaseMessage: String {
        switch phase {
        case .intro:    return "Let's learn a melody! Tap 'Listen' to hear it."
        case .listening: return "Listen carefully... 🎧"
        case .playing:   return "Your turn! Play the notes! 🎹"
        case .success:   return "Amazing! You played it perfectly! 🌟"
        case .allDone:   return "You learned all the melodies! 🎉"
        }
    }

    // MARK: - Instructions

    private var instructionText: some View {
        Group {
            switch phase {
            case .intro:
                BigNeonButton(title: "Listen", emoji: "🎧", color: NeonColors.violet) {
                    startListening()
                }
            case .listening:
                Text("♪ ♪ ♪")
                    .font(.system(size: 32))
                    .foregroundColor(NeonColors.bubblegum)
            case .playing:
                Text("Note \(playerIndex + 1) of \(currentMelody.notes.count)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(NeonColors.cyan)
            case .success:
                HStack(spacing: 16) {
                    if currentMelodyIndex < melodies.count - 1 {
                        BigNeonButton(title: "Next Melody", emoji: "➡️", color: NeonColors.hotPink) {
                            nextMelody()
                        }
                    }
                    BigNeonButton(title: "Listen Again", emoji: "🔁", color: NeonColors.purple) {
                        startListening()
                    }
                }
            case .allDone:
                BigNeonButton(title: "Play Again", emoji: "🔄", color: NeonColors.hotPink) {
                    currentMelodyIndex = 0
                    phase = .intro
                }
            }
        }
    }

    // MARK: - Note Sequence Bar

    private var noteSequenceBar: some View {
        HStack(spacing: 8) {
            ForEach(Array(currentMelody.notes.enumerated()), id: \.offset) { idx, note in
                ZStack {
                    Circle()
                        .fill(noteCircleColor(for: idx, note: note))
                        .frame(width: 40, height: 40)
                        .shadow(
                            color: playbackIndex == idx ? note.neonColor.opacity(0.8) : .clear,
                            radius: 8
                        )

                    Text(note.rawValue)
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                }
                .scaleEffect(playbackIndex == idx ? 1.2 : 1.0)
                .animation(.spring(response: 0.2), value: playbackIndex)
            }
        }
        .padding(.horizontal)
    }

    private func noteCircleColor(for idx: Int, note: PianoNote) -> Color {
        if phase == .playing && idx < playerIndex {
            return .green.opacity(0.7)     // correctly played
        }
        if phase == .playing && idx == playerIndex {
            return note.neonColor           // current target
        }
        if playbackIndex == idx {
            return note.neonColor           // being played back
        }
        return note.neonColor.opacity(0.3)  // upcoming
    }

    // MARK: - Logic

    private func startListening() {
        phase = .listening
        playbackIndex = -1

        // Play the melody with visual feedback
        for (i, note) in currentMelody.notes.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6 * Double(i)) {
                playbackIndex = i
                highlightedNote = note
                audio.playNote(note)
            }
        }

        // After playback, switch to playing phase
        let totalTime = 0.6 * Double(currentMelody.notes.count) + 0.5
        DispatchQueue.main.asyncAfter(deadline: .now() + totalTime) {
            playbackIndex = -1
            highlightedNote = currentMelody.notes.first
            playerIndex = 0
            phase = .playing
        }
    }

    private func handleTap(_ note: PianoNote) {
        guard phase == .playing else { return }
        audio.playNote(note)

        let expected = currentMelody.notes[playerIndex]
        if note == expected {
            // Correct!
            playerIndex += 1
            correctCount += 1
            gameState.scoreHit()

            if playerIndex >= currentMelody.notes.count {
                // Melody complete!
                phase = .success
                highlightedNote = nil
                showSparkle = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    showSparkle = false
                }
            } else {
                highlightedNote = currentMelody.notes[playerIndex]
            }
        } else {
            // Wrong note — encourage and let them try again
            gameState.scoreMiss()
            // Don't advance, keep highlighting the same note
        }
    }

    private func nextMelody() {
        currentMelodyIndex += 1
        playerIndex = 0
        playbackIndex = -1
        highlightedNote = nil

        if currentMelodyIndex >= melodies.count {
            phase = .allDone
        } else {
            phase = .intro
        }
    }
}
