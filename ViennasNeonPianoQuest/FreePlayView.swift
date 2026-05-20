import SwiftUI

struct FreePlayView: View {
    @EnvironmentObject var gameState: GameState
    @EnvironmentObject var audio: AudioEngine

    @State private var sparkles: [(id: UUID, note: PianoNote, pos: CGPoint)] = []
    @State private var selectedInstrument: InstrumentType = .grandPiano

    var body: some View {
        ZStack {
            NeonGradients.stageBackground.ignoresSafeArea()

            // Sparkle effects from played notes
            ForEach(sparkles, id: \.id) { sparkle in
                FreePlaySparkle(note: sparkle.note, position: sparkle.pos)
            }

            VStack(spacing: 0) {
                // Header
                header

                // Instrument picker
                instrumentPicker

                Spacer()

                // Visual area: mascots and dancing effects
                HStack(spacing: 30) {
                    ForEach(Characters.allMascots) { mascot in
                        PulsingMascot(character: mascot)
                            .scaleEffect(0.7)
                    }
                }
                .padding()

                Text("Play anything you like! 🎵")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(NeonColors.bubblegum)

                Spacer()

                // Full piano keyboard
                PianoKeyboardView(availableNotes: PianoNote.allCases) { note in
                    handleNoteTap(note)
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            NeonBackButton { gameState.goHome() }
            Spacer()
            Text("Free Play Piano")
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundStyle(NeonGradients.pinkGlow)
            Spacer()
            Text("🎹")
                .font(.system(size: 28))
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    // MARK: - Instrument Picker

    private var instrumentPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(InstrumentType.allCases) { instrument in
                    let isSelected = selectedInstrument == instrument
                    let isUnlocked = isInstrumentUnlocked(instrument)

                    Button {
                        if isUnlocked {
                            selectedInstrument = instrument
                            audio.currentInstrument = instrument
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Text(instrument.icon)
                                .font(.system(size: 24))
                            Text(instrument.rawValue)
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        .foregroundColor(isUnlocked ? .white : .white.opacity(0.3))
                        .frame(width: 90, height: 60)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(isSelected ? NeonColors.hotPink : Color.white.opacity(0.1))
                                .shadow(color: isSelected ? NeonColors.hotPink.opacity(0.5) : .clear, radius: 6)
                        )
                        .overlay(
                            Group {
                                if !isUnlocked {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(Color.black.opacity(0.5))
                                        Image(systemName: "lock.fill")
                                            .foregroundColor(.white.opacity(0.5))
                                    }
                                }
                            }
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(!isUnlocked)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }

    private func isInstrumentUnlocked(_ instrument: InstrumentType) -> Bool {
        switch instrument {
        case .grandPiano: return true  // always available
        case .bubblePop:  return gameState.unlockedRewardIDs.contains("sound-bubble")
        case .neonSynth:  return gameState.unlockedRewardIDs.contains("sound-synth")
        case .musicBox:   return gameState.unlockedRewardIDs.contains("sound-musicbox")
        case .kittyPiano: return gameState.unlockedRewardIDs.contains("sound-kitty")
        }
    }

    // MARK: - Note Handling

    private func handleNoteTap(_ note: PianoNote) {
        audio.playNote(note)

        // Add sparkle at a semi-random position in the visual area
        let sparkleID = UUID()
        let x = CGFloat.random(in: 80...800)  // safe range for iPad landscape
        let y = CGFloat.random(in: 200...400)
        sparkles.append((id: sparkleID, note: note, pos: CGPoint(x: x, y: y)))

        // Clean up after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            sparkles.removeAll { $0.id == sparkleID }
        }
    }
}

// MARK: - Free Play Sparkle Effect

struct FreePlaySparkle: View {
    let note: PianoNote
    let position: CGPoint
    @State private var scale: CGFloat = 0.3
    @State private var opacity: Double = 1.0
    @State private var rotation: Double = 0

    private let symbols = ["✨", "⭐", "💖", "🌟", "🎵", "💜", "🎶", "💫", "🦋", "🌈"]

    var body: some View {
        ZStack {
            // Central glow
            Circle()
                .fill(note.neonColor)
                .frame(width: 50 * scale, height: 50 * scale)
                .blur(radius: 15)

            // Scattered emojis
            ForEach(0..<5, id: \.self) { i in
                Text(symbols.randomElement()!)
                    .font(.system(size: 20))
                    .offset(
                        x: cos(Double(i) * .pi * 2 / 5 + rotation) * 30 * scale,
                        y: sin(Double(i) * .pi * 2 / 5 + rotation) * 30 * scale
                    )
            }

            // Note name
            Text(note.emoji)
                .font(.system(size: 32))
        }
        .opacity(opacity)
        .position(position)
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) {
                scale = 2.5
                opacity = 0
                rotation = .pi
            }
        }
    }
}
