import AVFoundation
import SwiftUI

// MARK: - Audio Engine

class AudioEngine: ObservableObject {

    @Published var currentInstrument: InstrumentType = .grandPiano
    @Published var volume: Float = 0.7

    private let engine = AVAudioEngine()
    private var playerNodes: [AVAudioPlayerNode] = []
    private var bufferCache: [String: AVAudioPCMBuffer] = [:]   // "instrument-note" -> buffer
    private let poolSize = 12  // concurrent notes
    private var nextPlayerIndex = 0
    private let sampleRate: Double = 44100
    private let duration: Double = 1.2  // note duration in seconds

    init() {
        setupAudioSession()
        setupEngine()
        precacheAllBuffers()
    }

    // MARK: - Setup

    private func setupAudioSession() {
        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
        #endif
    }

    private func setupEngine() {
        // Create a pool of player nodes for concurrent playback
        for _ in 0..<poolSize {
            let player = AVAudioPlayerNode()
            engine.attach(player)
            let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
            engine.connect(player, to: engine.mainMixerNode, format: format)
            playerNodes.append(player)
        }

        engine.mainMixerNode.outputVolume = volume

        do {
            try engine.start()
        } catch {
            print("AudioEngine: failed to start – \(error)")
        }
    }

    // MARK: - Pre-cache

    private func precacheAllBuffers() {
        for instrument in InstrumentType.allCases {
            for note in PianoNote.allCases {
                let key = cacheKey(instrument: instrument, note: note)
                bufferCache[key] = generateBuffer(note: note, instrument: instrument)
            }
        }
    }

    private func cacheKey(instrument: InstrumentType, note: PianoNote) -> String {
        "\(instrument.rawValue)-\(note.rawValue)"
    }

    // MARK: - Buffer Generation

    private func generateBuffer(note: PianoNote, instrument: InstrumentType) -> AVAudioPCMBuffer {
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount

        let data = buffer.floatChannelData![0]
        let freq = note.frequency
        let attack = instrument.attack
        let decay = instrument.decay
        let harmonics = instrument.harmonics
        let useVibrato = instrument.vibrato

        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate

            // ADSR envelope: fast attack, exponential decay
            let attackEnv = min(t / attack, 1.0)
            let decayEnv = exp(-t * decay)
            let envelope = attackEnv * decayEnv

            // Additive synthesis
            var sample: Double = 0
            for (harmonic, amplitude) in harmonics {
                var f = freq * harmonic
                // Vibrato for Kitty Piano
                if useVibrato {
                    f += 3.0 * sin(2.0 * .pi * 5.5 * t)  // 5.5 Hz vibrato, ±3 Hz
                }
                sample += amplitude * sin(2.0 * .pi * f * t)
            }

            // Normalise and apply envelope
            let totalAmp = harmonics.reduce(0.0) { $0 + $1.1 }
            sample = (sample / totalAmp) * envelope * 0.45

            data[frame] = Float(sample)
        }

        return buffer
    }

    // MARK: - Playback

    func playNote(_ note: PianoNote) {
        let key = cacheKey(instrument: currentInstrument, note: note)
        guard let buffer = bufferCache[key] else { return }

        let player = playerNodes[nextPlayerIndex % poolSize]
        nextPlayerIndex += 1

        player.stop()
        player.scheduleBuffer(buffer, at: nil, options: .interrupts)
        player.volume = volume
        player.play()
    }

    /// Play a note with a specific instrument (ignoring currentInstrument)
    func playNote(_ note: PianoNote, instrument: InstrumentType) {
        let key = cacheKey(instrument: instrument, note: note)
        guard let buffer = bufferCache[key] else { return }

        let player = playerNodes[nextPlayerIndex % poolSize]
        nextPlayerIndex += 1

        player.stop()
        player.scheduleBuffer(buffer, at: nil, options: .interrupts)
        player.volume = volume
        player.play()
    }

    /// Play a sequence of notes with a delay between each
    func playSequence(_ notes: [PianoNote], interval: TimeInterval = 0.5,
                      completion: (() -> Void)? = nil) {
        for (index, note) in notes.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + interval * Double(index)) { [weak self] in
                self?.playNote(note)
            }
        }
        // Callback after entire sequence
        if let completion = completion {
            let totalTime = interval * Double(notes.count) + 0.3
            DispatchQueue.main.asyncAfter(deadline: .now() + totalTime) {
                completion()
            }
        }
    }

    // MARK: - Volume

    func setVolume(_ newVolume: Float) {
        volume = max(0, min(1, newVolume))
        engine.mainMixerNode.outputVolume = volume
    }

    func setQuietMode(_ quiet: Bool) {
        setVolume(quiet ? 0.25 : 0.7)
    }

    // MARK: - Cleanup

    func stop() {
        for player in playerNodes {
            player.stop()
        }
    }

    deinit {
        engine.stop()
    }
}
