import SwiftUI

@main
struct ViennasNeonPianoQuestApp: App {
    @StateObject private var gameState = GameState()
    @StateObject private var audio = AudioEngine()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(gameState)
                .environmentObject(audio)
                .preferredColorScheme(.dark)
                #if os(iOS)
                .statusBarHidden(true)
                #endif
        }
    }
}
