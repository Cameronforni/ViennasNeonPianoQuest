import SwiftUI

struct StickerRoomView: View {
    @EnvironmentObject var gameState: GameState

    @State private var selectedCategory: RewardCategory = .sticker
    @State private var celebratingReward: Reward?
    @State private var showCelebration = false
    @State private var posterStickers: [PosterSticker] = []

    var body: some View {
        ZStack {
            NeonGradients.stageBackground.ignoresSafeArea()

            VStack(spacing: 12) {
                // Header
                header

                // Category tabs
                categoryTabs

                // Content area
                HStack(spacing: 16) {
                    // Reward grid
                    rewardGrid
                        .frame(maxWidth: .infinity)

                    // Concert poster
                    concertPoster
                        .frame(width: 280)
                }
                .padding(.horizontal)
            }
            .padding(.top, 8)

            // Celebration overlay
            if showCelebration, let reward = celebratingReward {
                rewardCelebration(reward)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            NeonBackButton { gameState.goHome() }
            Spacer()
            Text("Sticker Room")
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundStyle(NeonGradients.pinkGlow)
            Spacer()
            HStack(spacing: 6) {
                Image(systemName: "star.fill").foregroundColor(NeonColors.gold)
                Text("\(gameState.totalStars)")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundColor(NeonColors.gold)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Category Tabs

    private var categoryTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(RewardCategory.allCases, id: \.self) { category in
                    let isSelected = selectedCategory == category
                    let count = rewardsIn(category).filter { gameState.isRewardUnlocked($0) }.count
                    let total = rewardsIn(category).count

                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            selectedCategory = category
                        }
                    } label: {
                        VStack(spacing: 2) {
                            Text(category.rawValue)
                                .font(.system(size: 14, weight: .heavy, design: .rounded))
                            Text("\(count)/\(total)")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(isSelected ? NeonColors.hotPink : Color.white.opacity(0.1))
                                .shadow(color: isSelected ? NeonColors.hotPink.opacity(0.5) : .clear, radius: 6)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Reward Grid

    private var rewardGrid: some View {
        let rewards = rewardsIn(selectedCategory)

        return ScrollView {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 100, maximum: 130), spacing: 12)
            ], spacing: 12) {
                ForEach(rewards) { reward in
                    RewardCard(
                        reward: reward,
                        isUnlocked: gameState.isRewardUnlocked(reward),
                        onTap: {
                            if gameState.isRewardUnlocked(reward) {
                                addToPoster(reward)
                            }
                        }
                    )
                }
            }
            .padding(.vertical, 8)
        }
    }

    // MARK: - Concert Poster

    private var concertPoster: some View {
        VStack(spacing: 8) {
            Text("Your Concert Poster")
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundColor(NeonColors.bubblegum)

            ZStack {
                // Poster background
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [NeonColors.darkPurple, NeonColors.darkStage],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(NeonColors.hotPink.opacity(0.5), lineWidth: 2)
                    )

                // Poster title
                VStack {
                    Text("⭐ Vienna's Piano Concert ⭐")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(NeonColors.gold)
                        .padding(.top, 12)

                    Spacer()
                }

                // Placed stickers
                ForEach(posterStickers) { sticker in
                    Text(sticker.emoji)
                        .font(.system(size: sticker.size))
                        .position(x: sticker.x, y: sticker.y)
                        .rotationEffect(.degrees(sticker.rotation))
                }

                // Hint text
                if posterStickers.isEmpty {
                    Text("Tap unlocked stickers\nto decorate!")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.4))
                        .multilineTextAlignment(.center)
                }
            }
            .frame(height: 340)

            // Clear button
            if !posterStickers.isEmpty {
                Button {
                    withAnimation { posterStickers.removeAll() }
                } label: {
                    Text("Clear Poster")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color.white.opacity(0.1)))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Helpers

    private func rewardsIn(_ category: RewardCategory) -> [Reward] {
        Reward.allRewards.filter { $0.category == category }
    }

    private func addToPoster(_ reward: Reward) {
        let sticker = PosterSticker(
            emoji: reward.emoji,
            x: CGFloat.random(in: 40...240),
            y: CGFloat.random(in: 50...300),
            size: CGFloat.random(in: 24...40),
            rotation: Double.random(in: -20...20)
        )
        withAnimation(.spring(response: 0.3)) {
            posterStickers.append(sticker)
        }
    }

    // MARK: - Celebration

    private func rewardCelebration(_ reward: Reward) -> some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    showCelebration = false
                }

            VStack(spacing: 16) {
                Text(reward.emoji)
                    .font(.system(size: 80))

                Text("New Reward!")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(NeonGradients.pinkGlow)

                Text(reward.name)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text(reward.description)
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(NeonColors.bubblegum)

                BigNeonButton(title: "Yay!", emoji: "🎉", color: NeonColors.hotPink) {
                    showCelebration = false
                }
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 30)
                    .fill(NeonColors.darkPurple)
                    .shadow(color: NeonColors.hotPink.opacity(0.5), radius: 20)
            )
        }
        .transition(.scale.combined(with: .opacity))
    }
}

// MARK: - Poster Sticker

struct PosterSticker: Identifiable {
    let id = UUID()
    let emoji: String
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let rotation: Double
}

// MARK: - Reward Card

struct RewardCard: View {
    let reward: Reward
    let isUnlocked: Bool
    let onTap: () -> Void

    @State private var bounce = false

    var body: some View {
        Button(action: {
            if isUnlocked {
                bounce = true
                onTap()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    bounce = false
                }
            }
        }) {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(isUnlocked ? cardColor : Color.white.opacity(0.05))
                        .frame(width: 80, height: 80)
                        .shadow(color: isUnlocked ? cardColor.opacity(0.5) : .clear, radius: 6)

                    if isUnlocked {
                        Text(reward.emoji)
                            .font(.system(size: 36))
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.3))
                    }
                }

                Text(reward.name)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(isUnlocked ? .white : .white.opacity(0.3))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(height: 28)
            }
            .scaleEffect(bounce ? 1.15 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.5), value: bounce)
        }
        .buttonStyle(.plain)
    }

    private var cardColor: Color {
        switch reward.category {
        case .sticker:    return NeonColors.hotPink.opacity(0.3)
        case .badge:      return NeonColors.gold.opacity(0.3)
        case .crown:      return NeonColors.violet.opacity(0.3)
        case .background: return NeonColors.neonBlue.opacity(0.3)
        case .outfit:     return NeonColors.bubblegum.opacity(0.3)
        case .sound:      return NeonColors.cyan.opacity(0.3)
        }
    }
}
