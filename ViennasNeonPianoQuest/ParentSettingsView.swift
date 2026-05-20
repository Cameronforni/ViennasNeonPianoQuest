import SwiftUI

struct ParentSettingsView: View {
    @EnvironmentObject var gameState: GameState
    @EnvironmentObject var audio: AudioEngine

    @State private var showResetConfirm = false

    var body: some View {
        ZStack {
            NeonGradients.stageBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                header

                ScrollView {
                    VStack(spacing: 24) {
                        // Sound settings
                        settingsSection("Sound") {
                            toggleRow(
                                title: "Quiet Mode",
                                subtitle: "Lower volume for bedtime practice",
                                icon: "speaker.wave.1.fill",
                                isOn: Binding(
                                    get: { gameState.settings.quietMode },
                                    set: {
                                        gameState.settings.quietMode = $0
                                        audio.setQuietMode($0)
                                        gameState.save()
                                    }
                                )
                            )
                        }

                        // Practice settings
                        settingsSection("Practice") {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Practice Length")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)

                                HStack(spacing: 12) {
                                    ForEach([5, 10, 15], id: \.self) { minutes in
                                        let isSelected = gameState.settings.practiceMinutes == minutes
                                        Button {
                                            gameState.settings.practiceMinutes = minutes
                                            gameState.save()
                                        } label: {
                                            Text("\(minutes) min")
                                                .font(.system(size: 16, weight: .heavy, design: .rounded))
                                                .foregroundColor(.white)
                                                .frame(width: 80, height: 44)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .fill(isSelected ? NeonColors.hotPink : Color.white.opacity(0.1))
                                                )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }

                        // Difficulty settings
                        settingsSection("Difficulty") {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Note Speed")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)

                                HStack(spacing: 12) {
                                    ForEach([(1, "Easy", 2.0), (2, "Medium", 3.0), (3, "Hard", 4.5)], id: \.0) { item in
                                        let isSelected = gameState.settings.difficultyLevel == item.0
                                        Button {
                                            gameState.settings.difficultyLevel = item.0
                                            gameState.settings.noteDropSpeed = CGFloat(item.2)
                                            gameState.save()
                                        } label: {
                                            VStack(spacing: 2) {
                                                Text(item.1)
                                                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                                                Text(difficultyEmoji(item.0))
                                                    .font(.system(size: 20))
                                            }
                                            .foregroundColor(.white)
                                            .frame(width: 90, height: 56)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(isSelected ? NeonColors.violet : Color.white.opacity(0.1))
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }

                        // Safety info
                        settingsSection("Safety") {
                            VStack(alignment: .leading, spacing: 10) {
                                safetyRow(icon: "xmark.circle", text: "No advertisements")
                                safetyRow(icon: "xmark.circle", text: "No external links")
                                safetyRow(icon: "xmark.circle", text: "No in-app purchases")
                                safetyRow(icon: "checkmark.circle", text: "100% kid-safe content")
                                safetyRow(icon: "checkmark.circle", text: "All original characters & music")
                            }
                        }

                        // Progress
                        settingsSection("Progress") {
                            VStack(alignment: .leading, spacing: 10) {
                                infoRow(label: "Total Stars", value: "\(gameState.totalStars) ⭐")
                                infoRow(label: "Levels Completed", value: "\(gameState.completedLevelIDs.count) / \(GameLevel.allLevels.count)")
                                infoRow(label: "Rewards Unlocked", value: "\(gameState.unlockedRewardIDs.count) / \(Reward.allRewards.count)")

                                Button {
                                    showResetConfirm = true
                                } label: {
                                    Text("Reset All Progress")
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .foregroundColor(.red.opacity(0.8))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            Capsule().fill(Color.red.opacity(0.15))
                                        )
                                }
                                .buttonStyle(.plain)
                                .padding(.top, 4)
                            }
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                }
            }

            // Reset confirmation
            if showResetConfirm {
                resetConfirmation
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            NeonBackButton { gameState.goHome() }
            Spacer()
            Text("Parent Settings")
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
            Spacer()
            Image(systemName: "gearshape.fill")
                .font(.title2)
                .foregroundColor(NeonColors.bubblegum)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }

    // MARK: - Section Builder

    private func settingsSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundStyle(NeonGradients.pinkGlow)

            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }

    // MARK: - Row Components

    private func toggleRow(title: String, subtitle: String, icon: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(NeonColors.bubblegum)
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
            }
            Spacer()
            Toggle("", isOn: isOn)
                .tint(NeonColors.hotPink)
                .labelsHidden()
        }
    }

    private func safetyRow(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(icon.starts(with: "check") ? .green : .red.opacity(0.7))
            Text(text)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
        }
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
            Spacer()
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
    }

    private func difficultyEmoji(_ level: Int) -> String {
        switch level {
        case 1: return "🐢"
        case 2: return "🐰"
        case 3: return "🚀"
        default: return "🐰"
        }
    }

    // MARK: - Reset Confirmation

    private var resetConfirmation: some View {
        ZStack {
            Color.black.opacity(0.7).ignoresSafeArea()

            VStack(spacing: 20) {
                Text("⚠️")
                    .font(.system(size: 48))

                Text("Reset All Progress?")
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)

                Text("This will erase all stars, completed levels, and unlocked rewards. This cannot be undone.")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                HStack(spacing: 16) {
                    BigNeonButton(title: "Cancel", emoji: "↩️", color: NeonColors.purple) {
                        showResetConfirm = false
                    }
                    BigNeonButton(title: "Reset", emoji: "🗑️", color: .red.opacity(0.8)) {
                        resetProgress()
                    }
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(NeonColors.darkPurple)
            )
        }
    }

    private func resetProgress() {
        gameState.totalStars = 0
        gameState.completedLevelIDs.removeAll()
        gameState.levelStars.removeAll()
        gameState.unlockedRewardIDs = ["sticker-pink-star"]
        gameState.save()
        showResetConfirm = false
    }
}
