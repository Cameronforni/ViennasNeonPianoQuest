import SwiftUI

struct RhythmStageView: View {
    let level: GameLevel
    @EnvironmentObject var gameState: GameState
    @EnvironmentObject var audio: AudioEngine

    @State private var gems: [RhythmGem] = []
    @State private var gameTimer: Timer?
    @State private var isPlaying = false
    @State private var isComplete = false
    @State private var hitCount = 0
    @State private var totalGems = 0
    @State private var lastRating: HitRating?
    @State private var showRating = false

    private let targetLineX: CGFloat = 120       // where gems should be tapped
    private let gemSpeed: CGFloat = 2.5
    private let laneHeight: CGFloat = 60

    var body: some View {
        ZStack {
            NeonGradients.stageBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                header

                // Rhythm lanes
                GeometryReader { geo in
                    ZStack {
                        // Target line
                        Rectangle()
                            .fill(NeonColors.hotPink)
                            .frame(width: 4, height: geo.size.height)
                            .position(x: targetLineX, y: geo.size.height / 2)
                            .neonGlow(NeonColors.hotPink, radius: 8)

                        // Note lanes
                        ForEach(level.availableNotes) { note in
                            let laneY = laneYPosition(for: note, totalHeight: geo.size.height)

                            // Lane background
                            Rectangle()
                                .fill(note.neonColor.opacity(0.08))
                                .frame(height: laneHeight)
                                .position(x: geo.size.width / 2, y: laneY)

                            // Lane label
                            Text(note.rawValue)
                                .font(.system(size: 18, weight: .heavy, design: .rounded))
                                .foregroundColor(note.neonColor.opacity(0.5))
                                .position(x: 40, y: laneY)
                        }

                        // Gems
                        ForEach(gems.filter { $0.isActive }) { gem in
                            let laneY = laneYPosition(for: gem.note, totalHeight: geo.size.height)
                            RhythmGemView(gem: gem)
                                .position(x: gem.xOffset, y: laneY)
                        }

                        // Rating display
                        if showRating, let rating = lastRating {
                            Text(rating.rawValue)
                                .font(.system(size: 36, weight: .black, design: .rounded))
                                .foregroundColor(rating.color)
                                .neonGlow(rating.color, radius: 10)
                                .position(x: geo.size.width / 2, y: geo.size.height / 2)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                }
                .frame(height: 320)

                // Piano keyboard for tapping
                PianoKeyboardView(availableNotes: level.availableNotes) { note in
                    handleTap(note)
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            }

            if !isPlaying && !isComplete {
                startOverlay
            }

            if isComplete {
                completeOverlay
            }
        }
        .onDisappear {
            gameTimer?.invalidate()
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            NeonBackButton { gameState.goHome() }
            Spacer()
            Text("K-pop Rhythm Stage")
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .foregroundStyle(NeonGradients.pinkGlow)
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

    // MARK: - Helpers

    private func laneYPosition(for note: PianoNote, totalHeight: CGFloat) -> CGFloat {
        guard let idx = level.availableNotes.firstIndex(of: note) else { return totalHeight / 2 }
        let count = CGFloat(level.availableNotes.count)
        let spacing = totalHeight / (count + 1)
        return spacing * (CGFloat(idx) + 1)
    }

    // MARK: - Game Logic

    private func startRhythm() {
        isPlaying = true
        hitCount = 0
        gems = []

        let startX: CGFloat = 1200  // start gems off-screen right (works for iPad landscape)

        // Create gems from the level sequence
        for (i, note) in level.noteSequence.enumerated() {
            let gem = RhythmGem(
                note: note,
                beatIndex: i,
                xOffset: startX + CGFloat(i) * 140  // spaced out
            )
            gems.append(gem)
        }
        totalGems = gems.count

        // Animate gems leftward
        gameTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            updateGems()
        }
    }

    private func updateGems() {
        var anyActive = false
        for i in gems.indices {
            guard gems[i].isActive else { continue }
            gems[i].xOffset -= gemSpeed
            anyActive = true

            // Missed
            if gems[i].xOffset < targetLineX - 60 && !gems[i].wasHit {
                gems[i].isActive = false
                gameState.scoreMiss()
            }
        }

        if !anyActive {
            gameTimer?.invalidate()
            isComplete = true
            gameState.completeLevel(level, score: hitCount)
        }
    }

    private func handleTap(_ note: PianoNote) {
        audio.playNote(note)

        // Find closest matching gem near the target line
        guard let idx = gems.indices.first(where: {
            gems[$0].isActive && !gems[$0].wasHit &&
            gems[$0].note == note &&
            abs(gems[$0].xOffset - targetLineX) < 80
        }) else {
            gameState.scoreMiss()
            return
        }

        let distance = abs(gems[idx].xOffset - targetLineX)
        let rating: HitRating
        if distance < 15 { rating = .perfect }
        else if distance < 30 { rating = .amazing }
        else if distance < 50 { rating = .great }
        else { rating = .sparkly }

        gems[idx].wasHit = true
        gems[idx].isActive = false
        gems[idx].rating = rating
        hitCount += 1
        gameState.scoreHit()

        lastRating = rating
        showRating = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            showRating = false
        }
    }

    // MARK: - Overlays

    private var startOverlay: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            VStack(spacing: 20) {
                Text("💃")
                    .font(.system(size: 64))
                Text("K-pop Rhythm Stage")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(NeonGradients.pinkGlow)
                Text("Tap the right note when the gem reaches the pink line!")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                BigNeonButton(title: "Start!", emoji: "🎵", color: NeonColors.hotPink) {
                    startRhythm()
                }
            }
        }
    }

    private var completeOverlay: some View {
        ZStack {
            Color.black.opacity(0.7).ignoresSafeArea()
            VStack(spacing: 20) {
                Text("🎉").font(.system(size: 64))
                Text("Rhythm Complete!")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(NeonGradients.pinkGlow)
                Text("You hit \(hitCount) of \(totalGems) beats!")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                BigNeonButton(title: "Home", emoji: "🏠", color: NeonColors.purple) {
                    gameState.goHome()
                }
            }
        }
    }
}

// MARK: - Rhythm Gem View

struct RhythmGemView: View {
    let gem: RhythmGem

    var body: some View {
        ZStack {
            // Diamond shape
            Diamond()
                .fill(gem.note.neonColor)
                .frame(width: 44, height: 44)
                .shadow(color: gem.note.neonColor.opacity(0.7), radius: 8)
            Diamond()
                .stroke(Color.white.opacity(0.6), lineWidth: 2)
                .frame(width: 44, height: 44)
            Text(gem.note.rawValue)
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Diamond Shape

struct Diamond: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}
