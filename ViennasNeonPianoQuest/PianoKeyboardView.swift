import SwiftUI

// MARK: - Piano Keyboard View

struct PianoKeyboardView: View {
    let availableNotes: [PianoNote]
    let highlightedNote: PianoNote?
    let onNoteTap: (PianoNote) -> Void

    @State private var pressedNote: PianoNote?

    init(
        availableNotes: [PianoNote] = PianoNote.allCases,
        highlightedNote: PianoNote? = nil,
        onNoteTap: @escaping (PianoNote) -> Void
    ) {
        self.availableNotes = availableNotes
        self.highlightedNote = highlightedNote
        self.onNoteTap = onNoteTap
    }

    var body: some View {
        GeometryReader { geo in
            let keyWidth = min(geo.size.width / CGFloat(availableNotes.count) - 6, 120)
            let keyHeight = min(geo.size.height, 180)

            HStack(spacing: 5) {
                Spacer(minLength: 0)
                ForEach(availableNotes) { note in
                    PianoKeyView(
                        note: note,
                        isPressed: pressedNote == note,
                        isHighlighted: highlightedNote == note,
                        width: keyWidth,
                        height: keyHeight
                    )
                    .onTapGesture {
                        tapNote(note)
                    }
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                if pressedNote != note {
                                    pressedNote = note
                                }
                            }
                            .onEnded { _ in
                                pressedNote = nil
                            }
                    )
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity)
        }
        .frame(height: 180)
    }

    private func tapNote(_ note: PianoNote) {
        pressedNote = note
        onNoteTap(note)

        // Visual feedback: release after short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            if pressedNote == note {
                pressedNote = nil
            }
        }
    }
}

// MARK: - Individual Piano Key

struct PianoKeyView: View {
    let note: PianoNote
    let isPressed: Bool
    let isHighlighted: Bool
    let width: CGFloat
    let height: CGFloat

    @State private var glowPulse = false

    var body: some View {
        ZStack {
            // Key background
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: isPressed
                            ? [note.neonColor, note.neonColor.opacity(0.7)]
                            : [Color.white, Color.white.opacity(0.9)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: width, height: height)
                .shadow(
                    color: isPressed ? note.neonColor.opacity(0.8) : .clear,
                    radius: isPressed ? 15 : 0
                )
                .shadow(
                    color: isHighlighted ? note.neonColor.opacity(0.6) : .clear,
                    radius: isHighlighted ? 20 : 0
                )

            // Highlight ring for target note
            if isHighlighted {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(note.neonColor, lineWidth: 4)
                    .frame(width: width, height: height)
                    .scaleEffect(glowPulse ? 1.05 : 1.0)
                    .opacity(glowPulse ? 1.0 : 0.5)
                    .animation(
                        .easeInOut(duration: 0.6).repeatForever(autoreverses: true),
                        value: glowPulse
                    )
                    .onAppear { glowPulse = true }
            }

            // Note label
            VStack(spacing: 6) {
                Spacer()

                // Colour dot
                Circle()
                    .fill(note.neonColor)
                    .frame(width: 20, height: 20)
                    .neonGlow(note.neonColor, radius: 4)

                // Note name
                Text(note.rawValue)
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(isPressed ? .white : note.neonColor)

                Spacer().frame(height: 16)
            }
            .frame(width: width, height: height)
        }
        .scaleEffect(isPressed ? 0.93 : 1.0)
        .animation(.spring(response: 0.15, dampingFraction: 0.6), value: isPressed)
        .accessibilityLabel("Piano key \(note.rawValue)")
        .accessibilityHint("Plays the note \(note.rawValue)")
    }
}

