import SwiftUI

@main
struct QuickClipApp: App {
    @StateObject private var store = SnippetStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(store)
        }
        .onChange(of: scenePhase) { phase in
            // Pick up snippets saved from the QuickClip keyboard while away.
            if phase == .active {
                store.importKeyboardInbox()
            }
        }
    }
}
