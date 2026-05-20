import SwiftUI

struct HomeScreenView: View {
    @EnvironmentObject var gameState: GameState
    @State private var titleScale: CGFloat = 0.8
    @State private var titleGlow = false
    @State private var showStars = false

    var body: some View {
        ZStack {
            // Background
            NeonGradients.stageBackground.ignoresSafeArea()

            // Sparkle overlay
            SparkleOverlay()

            // Stage spotlights (decorative circles)
            spotlights

            VStack(spacing: 20) {
                // Title
                titleSection

                // Mascots row
                mascotRow

                // Star count
                HStack(spacing: 8) {
                    Image(systemName: "star.fill")
                        .foregroundColor(NeonColors.gold)
                        .font(.title2)
                    Text("\(gameState.totalStars)")
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundColor(NeonColors.gold)
                    Text("Stars")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                }
                .neonGlow(NeonColors.gold, radius: 6)

                // Main buttons
                buttonGrid
            }
            .padding()
        }
    }

    // MARK: - Title

    private var titleSection: some View {
        VStack(spacing: 4) {
            Text("🎹")
                .font(.system(size: 48))

            Text("Vienna's")
                .font(.system(size: 32, weight: .heavy, design: .rounded))
                .foregroundStyle(NeonGradients.pinkGlow)

            Text("Neon Piano Quest")
                .font(.system(size: 42, weight: .black, design: .rounded))
                .foregroundStyle(NeonGradients.rainbow)
                .shadow(color: NeonColors.hotPink.opacity(0.7), radius: 10)
                .shadow(color: NeonColors.violet.opacity(0.4), radius: 20)
        }
        .scaleEffect(titleScale)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                titleScale = 1.0
            }
        }
    }

    // MARK: - Mascots

    private var mascotRow: some View {
        HStack(spacing: 24) {
            PulsingMascot(character: Characters.djViennaStar)
            ForEach(Characters.allMascots) { mascot in
                PulsingMascot(character: mascot)
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Buttons

    private var buttonGrid: some View {
        let buttons: [(String, String, Color, AppScreen)] = [
            ("Play",         "🎮", NeonColors.hotPink,  .levelSelect),
            ("Learn Notes",  "🎵", NeonColors.purple,   .rescueMelody),
            ("Rhythm Stage", "💃", NeonColors.neonBlue,  .rhythmStage(GameLevel.allLevels[0])),
            ("Free Play",    "🎹", NeonColors.cyan,     .freePlay),
            ("Stickers",     "⭐", NeonColors.gold,     .stickerRoom),
        ]

        return VStack(spacing: 14) {
            // Top row: Play (big)
            BigNeonButton(title: "Play", emoji: "🎮", color: NeonColors.hotPink) {
                gameState.navigate(to: .levelSelect)
            }

            // Bottom row: other buttons
            HStack(spacing: 12) {
                ForEach(buttons.dropFirst(), id: \.0) { item in
                    SmallMenuButton(title: item.0, emoji: item.1, color: item.2) {
                        gameState.navigate(to: item.3)
                    }
                }
            }

            // Parent settings (small, subtle)
            Button {
                gameState.navigate(to: .parentSettings)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "gearshape.fill")
                    Text("Parent Settings")
                }
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.4))
                .padding(8)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Spotlights

    private var spotlights: some View {
        GeometryReader { geo in
            ZStack {
                Circle()
                    .fill(NeonColors.hotPink.opacity(0.08))
                    .frame(width: 300, height: 300)
                    .blur(radius: 60)
                    .position(x: geo.size.width * 0.2, y: geo.size.height * 0.3)

                Circle()
                    .fill(NeonColors.violet.opacity(0.08))
                    .frame(width: 250, height: 250)
                    .blur(radius: 50)
                    .position(x: geo.size.width * 0.8, y: geo.size.height * 0.4)

                Circle()
                    .fill(NeonColors.cyan.opacity(0.06))
                    .frame(width: 200, height: 200)
                    .blur(radius: 40)
                    .position(x: geo.size.width * 0.5, y: geo.size.height * 0.7)
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Small Menu Button

struct SmallMenuButton: View {
    let title: String
    let emoji: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(emoji)
                    .font(.system(size: 28))
                Text(title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundColor(.white)
            .frame(width: 110, height: 80)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(color.opacity(0.8))
                    .shadow(color: color.opacity(0.5), radius: 8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
