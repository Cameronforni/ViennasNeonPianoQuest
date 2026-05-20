import SwiftUI

// MARK: - Neon Colour Palette

struct NeonColors {
    static let hotPink       = Color(red: 1.0, green: 0.08, blue: 0.58)
    static let bubblegum     = Color(red: 1.0, green: 0.41, blue: 0.71)
    static let purple        = Color(red: 0.69, green: 0.0, blue: 1.0)
    static let cyan          = Color(red: 0.0, green: 1.0, blue: 1.0)
    static let neonBlue      = Color(red: 0.0, green: 0.5, blue: 1.0)
    static let gold          = Color(red: 1.0, green: 0.84, blue: 0.0)
    static let violet        = Color(red: 0.85, green: 0.0, blue: 1.0)
    static let darkStage     = Color(red: 0.06, green: 0.02, blue: 0.15)
    static let darkPurple    = Color(red: 0.12, green: 0.04, blue: 0.25)
    static let softWhite     = Color.white.opacity(0.95)
}

// MARK: - Gradients

struct NeonGradients {
    static let stageBackground = LinearGradient(
        colors: [NeonColors.darkStage, NeonColors.darkPurple, Color.black],
        startPoint: .top, endPoint: .bottom
    )

    static let pinkGlow = LinearGradient(
        colors: [NeonColors.hotPink, NeonColors.bubblegum, NeonColors.violet],
        startPoint: .leading, endPoint: .trailing
    )

    static let rainbow = LinearGradient(
        colors: [NeonColors.hotPink, NeonColors.purple, NeonColors.neonBlue,
                 NeonColors.cyan, NeonColors.gold],
        startPoint: .leading, endPoint: .trailing
    )

    static let candyButton = LinearGradient(
        colors: [NeonColors.hotPink, NeonColors.violet],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    static let progressBar = LinearGradient(
        colors: [NeonColors.hotPink, NeonColors.bubblegum, NeonColors.cyan,
                 NeonColors.neonBlue, NeonColors.violet, NeonColors.gold],
        startPoint: .leading, endPoint: .trailing
    )
}

// MARK: - Neon Glow Modifier

struct NeonGlow: ViewModifier {
    let color: Color
    let radius: CGFloat

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.8), radius: radius)
            .shadow(color: color.opacity(0.4), radius: radius * 2)
    }
}

extension View {
    func neonGlow(_ color: Color, radius: CGFloat = 8) -> some View {
        modifier(NeonGlow(color: color, radius: radius))
    }
}

// MARK: - Neon Button Style

struct NeonButtonStyle: ButtonStyle {
    let color: Color
    let fontSize: CGFloat

    init(color: Color = NeonColors.hotPink, fontSize: CGFloat = 24) {
        self.color = color
        self.fontSize = fontSize
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: fontSize, weight: .heavy, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(color)
                    .shadow(color: color.opacity(0.7), radius: 10)
                    .shadow(color: color.opacity(0.3), radius: 20)
            )
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Big Round Neon Button

struct BigNeonButton: View {
    let title: String
    let emoji: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(emoji)
                    .font(.system(size: 32))
                Text(title)
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
            }
            .foregroundColor(.white)
            .frame(minWidth: 240, minHeight: 64)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(color)
                    .shadow(color: color.opacity(0.6), radius: 12)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Star Display

struct StarDisplay: View {
    let count: Int
    let maxStars: Int

    init(_ count: Int, max: Int = 3) {
        self.count = count
        self.maxStars = max
    }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<maxStars, id: \.self) { i in
                Image(systemName: i < count ? "star.fill" : "star")
                    .font(.title2)
                    .foregroundColor(i < count ? NeonColors.gold : .gray.opacity(0.4))
                    .neonGlow(i < count ? NeonColors.gold : .clear, radius: 4)
            }
        }
    }
}

// MARK: - Feedback Toast

struct FeedbackToast: View {
    let text: String
    let isVisible: Bool

    var body: some View {
        if isVisible {
            Text(text)
                .font(.system(size: 42, weight: .black, design: .rounded))
                .foregroundStyle(NeonGradients.pinkGlow)
                .shadow(color: NeonColors.hotPink.opacity(0.8), radius: 15)
                .shadow(color: NeonColors.violet.opacity(0.5), radius: 30)
                .transition(.scale.combined(with: .opacity))
                .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isVisible)
        }
    }
}

// MARK: - Progress Rainbow Bar

struct RainbowProgressBar: View {
    let progress: CGFloat  // 0.0 – 1.0

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))

                RoundedRectangle(cornerRadius: 12)
                    .fill(NeonGradients.progressBar)
                    .frame(width: geo.size.width * min(max(progress, 0), 1))
                    .animation(.easeInOut(duration: 0.3), value: progress)
                    .shadow(color: NeonColors.hotPink.opacity(0.5), radius: 8)
            }
        }
        .frame(height: 18)
    }
}

// MARK: - Floating Particle

struct FloatingParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    let symbol: String
    let size: CGFloat
    let opacity: Double
    let speed: CGFloat
}

// MARK: - Sparkle Particle Effect

struct SparkleOverlay: View {
    @State private var particles: [FloatingParticle] = []
    let symbols = ["✨", "⭐", "💖", "🎵", "🌟", "💜", "🎶", "💫"]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { p in
                    Text(p.symbol)
                        .font(.system(size: p.size))
                        .opacity(p.opacity)
                        .position(x: p.x, y: p.y)
                }
            }
            .onAppear {
                startEmitting(in: geo.size)
            }
        }
        .allowsHitTesting(false)
    }

    private func startEmitting(in size: CGSize) {
        Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
            let p = FloatingParticle(
                x: CGFloat.random(in: 0...size.width),
                y: size.height + 20,
                symbol: symbols.randomElement()!,
                size: CGFloat.random(in: 14...28),
                opacity: Double.random(in: 0.4...0.9),
                speed: CGFloat.random(in: 1...3)
            )
            particles.append(p)

            // Animate upward
            withAnimation(.linear(duration: Double.random(in: 3...6))) {
                if let idx = particles.firstIndex(where: { $0.id == p.id }) {
                    particles[idx].y = -40
                    particles[idx].x += CGFloat.random(in: -40...40)
                }
            }

            // Remove old particles
            DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                particles.removeAll { $0.id == p.id }
            }
        }
    }
}

// MARK: - Note Hit Burst

struct NoteHitBurst: View {
    let note: PianoNote
    let position: CGPoint
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 1.0

    var body: some View {
        ZStack {
            ForEach(0..<6, id: \.self) { i in
                Text(note.emoji)
                    .font(.system(size: 24))
                    .offset(
                        x: cos(Double(i) * .pi / 3) * 40 * scale,
                        y: sin(Double(i) * .pi / 3) * 40 * scale
                    )
            }
            Circle()
                .fill(note.neonColor)
                .frame(width: 60 * scale, height: 60 * scale)
                .blur(radius: 10)
        }
        .opacity(opacity)
        .position(position)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                scale = 2.0
                opacity = 0
            }
        }
    }
}

// MARK: - Pulsing Mascot

struct PulsingMascot: View {
    let character: GameCharacter
    @State private var bouncing = false

    var body: some View {
        VStack(spacing: 4) {
            Text(character.emoji)
                .font(.system(size: 54))
                .offset(y: bouncing ? -8 : 0)
                .animation(
                    .easeInOut(duration: 0.5).repeatForever(autoreverses: true),
                    value: bouncing
                )
            Text(character.name)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
        }
        .onAppear { bouncing = true }
    }
}

// MARK: - Back Button

struct NeonBackButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "chevron.left")
                    .font(.title2.bold())
                Text("Back")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
            }
            .foregroundColor(NeonColors.bubblegum)
            .padding(10)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.1))
            )
        }
        .buttonStyle(.plain)
    }
}
