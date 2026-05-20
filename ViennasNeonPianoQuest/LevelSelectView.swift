import SwiftUI

struct LevelSelectView: View {
    @EnvironmentObject var gameState: GameState

    // Group levels by stage name
    private var stages: [(String, [GameLevel])] {
        let ordered = ["Pink Pop Palace", "Neon Note City", "Glitter Moon Stage", "Rainbow Rhythm Arena"]
        var grouped: [String: [GameLevel]] = [:]
        for level in GameLevel.allLevels {
            grouped[level.stageName, default: []].append(level)
        }
        return ordered.compactMap { name in
            guard let levels = grouped[name] else { return nil }
            return (name, levels)
        }
    }

    private let stageColors: [Color] = [
        NeonColors.hotPink, NeonColors.violet, NeonColors.cyan, NeonColors.gold
    ]
    private let stageEmojis = ["🏰", "🌆", "🌙", "🌈"]

    var body: some View {
        ZStack {
            NeonGradients.stageBackground.ignoresSafeArea()

            VStack(spacing: 16) {
                // Header
                HStack {
                    NeonBackButton { gameState.goHome() }
                    Spacer()
                    Text("Choose Your Stage!")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundStyle(NeonGradients.pinkGlow)
                    Spacer()
                    // Star counter
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(NeonColors.gold)
                        Text("\(gameState.totalStars)")
                            .font(.system(size: 20, weight: .heavy, design: .rounded))
                            .foregroundColor(NeonColors.gold)
                    }
                }
                .padding(.horizontal)

                // Stages scroll
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 24) {
                        ForEach(Array(stages.enumerated()), id: \.0) { index, stage in
                            StageCard(
                                stageName: stage.0,
                                levels: stage.1,
                                color: stageColors[index % stageColors.count],
                                emoji: stageEmojis[index % stageEmojis.count],
                                gameState: gameState
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                }

                Spacer()
            }
            .padding(.top)
        }
    }
}

// MARK: - Stage Card

struct StageCard: View {
    let stageName: String
    let levels: [GameLevel]
    let color: Color
    let emoji: String
    @ObservedObject var gameState: GameState

    var body: some View {
        VStack(spacing: 12) {
            // Stage header
            Text(emoji)
                .font(.system(size: 42))
            Text(stageName)
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
                .neonGlow(color, radius: 6)

            // Level buttons
            VStack(spacing: 10) {
                ForEach(levels) { level in
                    LevelButton(level: level, color: color, gameState: gameState)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(color.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(color.opacity(0.4), lineWidth: 2)
                )
        )
        .frame(width: 260)
    }
}

// MARK: - Level Button

struct LevelButton: View {
    let level: GameLevel
    let color: Color
    @ObservedObject var gameState: GameState

    private var isUnlocked: Bool { gameState.isLevelUnlocked(level) }
    private var stars: Int { gameState.starsForLevel(level) }
    private var isCompleted: Bool { gameState.completedLevelIDs.contains(level.id) }

    var body: some View {
        Button {
            if isUnlocked {
                gameState.resetSession()
                gameState.navigate(to: .tapMagicNote(level))
            }
        } label: {
            HStack {
                // Level number
                ZStack {
                    Circle()
                        .fill(isUnlocked ? color : .gray.opacity(0.3))
                        .frame(width: 44, height: 44)
                    if isUnlocked {
                        Text("\(level.stageNumber)")
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.5))
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(level.name)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(isUnlocked ? .white : .white.opacity(0.4))

                    if isCompleted {
                        StarDisplay(stars)
                    } else if isUnlocked {
                        Text("Tap to play!")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }

                Spacer()

                if isCompleted {
                    Text("✅")
                        .font(.title3)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isUnlocked ? color.opacity(0.25) : Color.white.opacity(0.05))
            )
        }
        .buttonStyle(.plain)
        .disabled(!isUnlocked)
    }
}
