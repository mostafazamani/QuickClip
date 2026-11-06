import SwiftUI
import UIKit

/// Sheet for creating or editing a snippet.
struct SnippetEditorView: View {
    @EnvironmentObject private var store: SnippetStore
    @Environment(\.dismiss) private var dismiss

    private let original: Snippet?

    @State private var title: String
    @State private var content: String
    @State private var categoryID: UUID?
    @State private var isPinned: Bool

    private var isNew: Bool { original == nil }

    init(snippet: Snippet?, fromClipboard: Bool = false) {
        let base: Snippet
        if let snippet = snippet {
            base = snippet
        } else {
            var fresh = Snippet(title: "", content: "")
            if fromClipboard {
                fresh.content = UIPasteboard.general.string ?? ""
                let firstLine = fresh.content
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .components(separatedBy: .newlines).first ?? ""
                if !firstLine.isEmpty {
                    fresh.title = String(firstLine.prefix(32))
                }
            }
            base = fresh
        }
        self.original = snippet
        _title = State(initialValue: base.title)
        _content = State(initialValue: base.content)
        _categoryID = State(initialValue: base.categoryID)
        _isPinned = State(initialValue: base.isPinned)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title (optional)", text: $title)
                    TextField("Your text…", text: $content, axis: .vertical)
                        .lineLimit(6...14)
                } header: {
                    Text("Snippet")
                } footer: {
                    Text("Leave the title empty and the first words of the content will be used.")
                }

                Section("Organization") {
                    Picker("Category", selection: $categoryID) {
                        Text("None").tag(UUID?.none)
                        ForEach(store.categories) { category in
                            Label(category.name, systemImage: category.systemImage)
                                .tag(UUID?.some(category.id))
                        }
                    }
                    Toggle("Pin to Top", isOn: $isPinned)
                }

                Section {
                    Button {
                        pasteFromClipboard()
                    } label: {
                        Label("Paste from Clipboard", systemImage: "doc.on.clipboard")
                    }
                }

                if !content.isEmpty {
                    Section {
                        HStack {
                            Text("Characters")
                            Spacer()
                            Text("\(content.count)")
                                .foregroundStyle(.secondary)
                        }
                        .font(.footnote)
                    }
                }
            }
            .navigationTitle(isNew ? "New Snippet" : "Edit Snippet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { save() }
                        .font(.body.weight(.semibold))
                        .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func pasteFromClipboard() {
        if let text = UIPasteboard.general.string, !text.isEmpty {
            content = text
            if title.isEmpty {
                let firstLine = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    .components(separatedBy: .newlines).first ?? ""
                title = String(firstLine.prefix(32))
            }
        } else {
            if store.settings.hapticsEnabled { Haptics.warning() }
            store.showToast("Clipboard is empty", icon: "exclamationmark.circle.fill")
        }
    }

    private func save() {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        var resolvedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if resolvedTitle.isEmpty {
            resolvedTitle = String(trimmedContent.prefix(32))
        }
        if resolvedTitle.isEmpty { resolvedTitle = "Untitled" }

        if let original = original {
            var updated = original
            updated.title = resolvedTitle
            updated.content = content
            updated.categoryID = categoryID
            updated.isPinned = isPinned
            store.update(updated)
        } else {
            store.add(title: resolvedTitle,
                      content: content,
                      categoryID: categoryID,
                      isPinned: isPinned)
        }
        dismiss()
    }
}
