import SwiftUI

struct TapMagicNoteView: View {
    let level: GameLevel
    @EnvironmentObject var gameState: GameState
    @EnvironmentObject var audio: AudioEngine

    // Game state
    @State private var fallingNotes: [FallingNote] = []
    @State private var nextNoteIndex = 0
    @State private var hitBursts: [(id: UUID, note: PianoNote, pos: CGPoint)] = []
    @State private var gameTimer: Timer?
    @State private var spawnTimer: Timer?
    @State private var isGameOver = false
    @State private var totalNotes = 0
    @State private var hitCount = 0
    @State private var currentTargetNote: PianoNote?

    // Layout
    private let gameAreaHeight: CGFloat = 420
    private let hitZoneY: CGFloat = 370      // where notes should be tapped
    private let missZoneY: CGFloat = 440     // below this = missed

    var body: some View {
        ZStack {
            NeonGradients.stageBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar
                topBar

                // Game area
                ZStack {
                    // Hit zone line
                    hitZoneLine

                    // Falling note bubbles
                    ForEach(fallingNotes.filter { $0.isActive }) { note in
                        NoteBubble(note: note, gameAreaHeight: gameAreaHeight)
                    }

                    // Hit burst effects
                    ForEach(hitBursts, id: \.id) { burst in
                        NoteHitBurst(note: burst.note, position: burst.pos)
                    }

                    // Mascot
                    mascotCheerer

                    // Feedback overlay
                    FeedbackToast(text: gameState.feedbackText, isVisible: gameState.showFeedback)
                }
                .frame(height: gameAreaHeight)
                .clipped()

                // Piano keyboard
                PianoKeyboardView(
                    availableNotes: level.availableNotes,
                    highlightedNote: currentTargetNote
                ) { note in
                    handleNoteTap(note)
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            }

            // Game over overlay
            if isGameOver {
                gameOverOverlay
            }
        }
        .onAppear { startGame() }
        .onDisappear { stopGame() }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            NeonBackButton {
                stopGame()
                gameState.goHome()
            }

            Spacer()

            VStack(spacing: 2) {
                Text(level.name)
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                Text(level.stageName)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(NeonColors.bubblegum)
            }

            Spacer()

            // Score as stars
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .foregroundColor(NeonColors.gold)
                Text("\(hitCount)")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundColor(NeonColors.gold)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    // MARK: - Hit Zone

    private var hitZoneLine: some View {
        GeometryReader { geo in
            Rectangle()
                .fill(NeonGradients.rainbow)
                .frame(height: 4)
                .blur(radius: 2)
                .neonGlow(NeonColors.hotPink, radius: 6)
                .position(x: geo.size.width / 2, y: hitZoneY)
        }
    }

    // MARK: - Mascot

    private var mascotCheerer: some View {
        VStack {
            HStack {
                Spacer()
                PulsingMascot(character: Characters.allMascots.randomElement()!)
                    .scaleEffect(0.7)
            }
            Spacer()
        }
        .padding()
        .allowsHitTesting(false)
    }

    // MARK: - Game Logic

    private func startGame() {
        gameState.resetSession()
        isGameOver = false
        hitCount = 0
        totalNotes = 0
        nextNoteIndex = 0
        fallingNotes = []

        let speed = gameState.settings.noteDropSpeed

        // Spawn notes periodically
        spawnTimer = Timer.scheduledTimer(withTimeInterval: 1.2, repeats: true) { _ in
            spawnNote(speed: speed)
        }

        // Game loop: move notes downward
        gameTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            updateNotes()
        }
    }

    private func stopGame() {
        gameTimer?.invalidate()
        spawnTimer?.invalidate()
        gameTimer = nil
        spawnTimer = nil
    }

    private func spawnNote(speed: CGFloat) {
        guard nextNoteIndex < level.noteSequence.count else {
            // All notes spawned – check if game should end
            if fallingNotes.allSatisfy({ !$0.isActive }) {
                endGame()
            }
            return
        }

        let note = level.noteSequence[nextNoteIndex]
        let fallingNote = FallingNote(note: note, speed: speed)
        fallingNotes.append(fallingNote)
        totalNotes += 1
        nextNoteIndex += 1
        currentTargetNote = note
    }

    private func updateNotes() {
        var anyActive = false
        for i in fallingNotes.indices {
            guard fallingNotes[i].isActive else { continue }
            fallingNotes[i].yOffset += fallingNotes[i].speed
            anyActive = true

            // Missed the hit zone
            if fallingNotes[i].yOffset > missZoneY && !fallingNotes[i].wasHit {
                fallingNotes[i].isActive = false
                gameState.scoreMiss()
            }
        }

        // Update current target to nearest active note
        if let nearest = fallingNotes.filter({ $0.isActive && !$0.wasHit })
            .min(by: { abs($0.yOffset - hitZoneY) < abs($1.yOffset - hitZoneY) }) {
            currentTargetNote = nearest.note
        } else {
            currentTargetNote = nil
        }

        // Check if all notes done
        if !anyActive && nextNoteIndex >= level.noteSequence.count {
            endGame()
        }
    }

    private func handleNoteTap(_ tappedNote: PianoNote) {
        audio.playNote(tappedNote)

        // Find the closest active falling note matching this key
        guard let idx = fallingNotes.indices.first(where: {
            fallingNotes[$0].isActive &&
            !fallingNotes[$0].wasHit &&
            fallingNotes[$0].note == tappedNote &&
            fallingNotes[$0].yOffset > hitZoneY - 80 &&
            fallingNotes[$0].yOffset < hitZoneY + 40
        }) else {
            // Wrong note or no note in range
            gameState.scoreMiss()
            return
        }

        // Hit!
        fallingNotes[idx].wasHit = true
        fallingNotes[idx].isActive = false
        hitCount += 1
        gameState.scoreHit()

        // Spawn burst effect — estimate position from key index
        let burstID = UUID()
        let estimatedWidth: CGFloat = 900  // reasonable iPad landscape width
        let xPos = CGFloat(tappedNote.keyIndex) / CGFloat(max(level.availableNotes.count - 1, 1))
            * (estimatedWidth - 60) + 30
        hitBursts.append((id: burstID, note: tappedNote, pos: CGPoint(x: xPos, y: hitZoneY)))

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            hitBursts.removeAll { $0.id == burstID }
        }
    }

    private func endGame() {
        guard !isGameOver else { return }
        stopGame()
        isGameOver = true
        gameState.completeLevel(level, score: hitCount)
    }

    // MARK: - Game Over Overlay

    private var gameOverOverlay: some View {
        ZStack {
            Color.black.opacity(0.7).ignoresSafeArea()

            VStack(spacing: 20) {
                Text("🎉")
                    .font(.system(size: 72))

                Text("Level Complete!")
                    .font(.system(size: 38, weight: .black, design: .rounded))
                    .foregroundStyle(NeonGradients.pinkGlow)

                StarDisplay(gameState.starsForLevel(level))
                    .scaleEffect(1.5)

                Text("You hit \(hitCount) out of \(totalNotes) notes!")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text(hitCount == totalNotes ? "PERFECT! You're a superstar! ⭐" : "Great job! 💖")
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundColor(NeonColors.bubblegum)

                HStack(spacing: 20) {
                    BigNeonButton(title: "Home", emoji: "🏠", color: NeonColors.purple) {
                        gameState.goHome()
                    }

                    BigNeonButton(title: "Next", emoji: "➡️", color: NeonColors.hotPink) {
                        goToNextLevel()
                    }
                }
            }
            .padding(40)
        }
        .transition(.opacity)
    }

    private func goToNextLevel() {
        let nextStage = level.stageNumber + 1
        if let next = GameLevel.allLevels.first(where: { $0.stageNumber == nextStage }) {
            gameState.resetSession()
            gameState.navigate(to: .tapMagicNote(next))
        } else {
            gameState.goHome()
        }
    }
}

// MARK: - Note Bubble

struct NoteBubble: View {
    let note: FallingNote
    let gameAreaHeight: CGFloat

    var body: some View {
        GeometryReader { geo in
            let xPos = CGFloat(note.note.keyIndex) / 6.0
                * (geo.size.width - 80) + 40

            ZStack {
                // Glow circle
                Circle()
                    .fill(note.note.neonColor.opacity(0.3))
                    .frame(width: 70, height: 70)
                    .blur(radius: 10)

                // Main bubble
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [note.note.neonColor, note.note.neonColor.opacity(0.6)],
                            center: .center, startRadius: 5, endRadius: 30
                        )
                    )
                    .frame(width: 56, height: 56)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.5), lineWidth: 2)
                    )

                // Note label
                Text(note.note.rawValue)
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundColor(.white)
            }
            .position(x: xPos, y: note.yOffset)
            .opacity(note.isActive ? 1.0 : 0.0)
        }
    }
}
