import SwiftUI

/// Root of the app: three tabs + a floating toast overlay.
struct RootTabView: View {
    @EnvironmentObject private var store: SnippetStore

    var body: some View {
        TabView {
            SnippetListView()
                .tabItem { Label("Snippets", systemImage: "doc.on.doc.fill") }

            CategoryListView()
                .tabItem { Label("Categories", systemImage: "folder.fill") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .overlay(alignment: .bottom) {
            ToastView()
                .padding(.bottom, 64)
        }
        .onChange(of: store.settings) { _ in
            store.save()
        }
    }
}
