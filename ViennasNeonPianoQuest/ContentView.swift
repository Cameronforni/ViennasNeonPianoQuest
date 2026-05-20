import SwiftUI

struct ContentView: View {
    @EnvironmentObject var gameState: GameState
    @EnvironmentObject var audio: AudioEngine

    var body: some View {
        ZStack {
            // Route to the correct screen
            screenView
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .id(screenID)  // force view identity change for transitions
        }
        .animation(.easeInOut(duration: 0.3), value: screenID)
        .onAppear {
            audio.setQuietMode(gameState.settings.quietMode)
        }
    }

    // MARK: - Screen Router

    @ViewBuilder
    private var screenView: some View {
        switch gameState.currentScreen {
        case .home:
            HomeScreenView()

        case .levelSelect:
            LevelSelectView()

        case .tapMagicNote(let level):
            TapMagicNoteView(level: level)

        case .rhythmStage(let level):
            RhythmStageView(level: level)

        case .rescueMelody:
            RescueMelodyView()

        case .freePlay:
            FreePlayView()

        case .bossBattle(let level):
            BossBattleView(level: level)

        case .stickerRoom:
            StickerRoomView()

        case .parentSettings:
            ParentSettingsView()
        }
    }

    /// A stable ID for each screen to drive transitions
    private var screenID: String {
        switch gameState.currentScreen {
        case .home:                 return "home"
        case .levelSelect:          return "levelSelect"
        case .tapMagicNote(let l):  return "tap-\(l.id)"
        case .rhythmStage(let l):   return "rhythm-\(l.id)"
        case .rescueMelody:         return "rescueMelody"
        case .freePlay:             return "freePlay"
        case .bossBattle(let l):    return "boss-\(l.id)"
        case .stickerRoom:          return "stickerRoom"
        case .parentSettings:       return "parentSettings"
        }
    }
}
