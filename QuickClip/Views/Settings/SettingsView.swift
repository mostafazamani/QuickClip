import SwiftUI
import UIKit

/// Settings tab: copying behavior, organizing options and data tools.
struct SettingsView: View {
    @EnvironmentObject private var store: SnippetStore

    @State private var showDeleteSnippetsConfirm = false
    @State private var showResetConfirm = false

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        return version ?? "1.0"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Copy on Tap", isOn: $store.settings.copyOnTap)
                    Toggle("Haptic Feedback", isOn: $store.settings.hapticsEnabled)
                    Toggle("Confirmation Toast", isOn: $store.settings.showToast)
                    Picker("Auto-clear Clipboard", selection: $store.settings.autoClearSeconds) {
                        Text("Never").tag(0)
                        Text("After 30 Seconds").tag(30)
                        Text("After 1 Minute").tag(60)
                        Text("After 5 Minutes").tag(300)
                    }
                } header: {
                    Text("Copying")
                } footer: {
                    Text("Copy on Tap copies a snippet the moment you tap it — no menus needed. Auto-clear removes the clipboard content after the chosen time for extra privacy.")
                }

                Section {
                    Picker("Sort Snippets By", selection: $store.settings.sortOption) {
                        ForEach(SnippetSort.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                } header: {
                    Text("Organize")
                }

                Section {
                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label("Open iOS Settings", systemImage: "gear")
                    }
                } header: {
                    Text("QuickClip Keyboard")
                } footer: {
                    Text("Type faster anywhere: once, add the keyboard under Settings → General → Keyboard → Keyboards → Add New Keyboard… → QuickClip. Then in any app, tap a snippet on the QuickClip bar and its text is inserted instantly — no copy & paste needed. Tap ＋ on the keyboard to save a new snippet right there: from the clipboard (needs Allow Full Access) or from the text you just typed.")
                }

                Section {
                    Button {
                        store.clearClipboard()
                    } label: {
                        Label("Clear Clipboard Now", systemImage: "trash")
                    }
                    Button(role: .destructive) {
                        showDeleteSnippetsConfirm = true
                    } label: {
                        Label("Delete All Snippets", systemImage: "xmark.bin")
                    }
                    Button(role: .destructive) {
                        showResetConfirm = true
                    } label: {
                        Label("Reset App to Defaults", systemImage: "arrow.counterclockwise")
                    }
                } header: {
                    Text("Data")
                } footer: {
                    Text("Everything is stored locally on this device in a single JSON file. Nothing ever leaves your phone.")
                }

                Section {
                    LabeledContent("Version", value: appVersion)
                    LabeledContent("Snippets", value: "\(store.snippets.count)")
                    LabeledContent("Categories", value: "\(store.categories.count)")
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .confirmationDialog("Delete all snippets?",
                                isPresented: $showDeleteSnippetsConfirm,
                                titleVisibility: .visible) {
                Button("Delete All Snippets", role: .destructive) {
                    store.deleteAll()
                    store.showToast("All snippets deleted", icon: "trash.circle.fill")
                }
                Button("Cancel", role: .cancel) {}
            }
            .confirmationDialog("Reset everything?",
                                isPresented: $showResetConfirm,
                                titleVisibility: .visible) {
                Button("Reset App to Defaults", role: .destructive) {
                    store.resetAll()
                    store.showToast("App reset to defaults")
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Snippets, categories and settings go back to the original sample data.")
            }
        }
    }
}
