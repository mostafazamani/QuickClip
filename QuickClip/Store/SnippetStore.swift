import Foundation
import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// A short confirmation message shown as a floating capsule.
struct ToastData: Equatable, Identifiable {
    var id = UUID()
    var text: String
    var icon: String
}

/// Central observable store owning all app data.
/// Persists everything to a single JSON file in the Documents directory.
final class SnippetStore: ObservableObject {
    @Published private(set) var snippets: [Snippet] = []
    @Published private(set) var categories: [SnippetCategory] = []
    @Published var settings = AppSettings()
    @Published var toast: ToastData?

    private struct PersistedData: Codable {
        var snippets: [Snippet]
        var categories: [SnippetCategory]
        var settings: AppSettings
    }

    /// Lightweight payload published for the QuickClip keyboard extension.
    private struct KeyboardSnippet: Codable {
        var id: UUID
        var title: String
        var content: String
        var colorHex: String?
        var isPinned: Bool
        var copyCount: Int
    }

    private var fileURL: URL {
        let documents = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent("quickclip-data.json")
    }

    init() {
        load()
        importKeyboardInbox()
    }

    // MARK: - Persistence

    private func load() {
        if let data = try? Data(contentsOf: fileURL),
           let decoded = try? JSONDecoder().decode(PersistedData.self, from: data) {
            snippets = decoded.snippets
            categories = decoded.categories
            settings = decoded.settings
        } else {
            categories = SnippetCategory.defaultCategories
            snippets = Snippet.seedSnippets(categories: categories)
            save()
        }
    }

    func save() {
        let data = PersistedData(snippets: snippets,
                                 categories: categories,
                                 settings: settings)
        if let encoded = try? JSONEncoder().encode(data) {
            try? encoded.write(to: fileURL, options: .atomic)
        }
        syncKeyboardSnippets()
    }

    /// Publishes the most useful snippets to the shared App Group so the
    /// QuickClip keyboard extension can offer them above the system keyboard.
    private func syncKeyboardSnippets() {
        guard let shared = UserDefaults(suiteName: "group.com.quickclip.app") else { return }
        let keyboardSnippets = snippets
            .map { snippet in
                KeyboardSnippet(id: snippet.id,
                                title: snippet.title,
                                content: snippet.content,
                                colorHex: snippet.categoryID.flatMap { category(withID: $0)?.colorHex },
                                isPinned: snippet.isPinned,
                                copyCount: snippet.copyCount)
            }
            .sorted { lhs, rhs in
                if lhs.isPinned != rhs.isPinned { return lhs.isPinned }
                if lhs.copyCount != rhs.copyCount { return lhs.copyCount > rhs.copyCount }
                return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
            }
            .prefix(24)
        if let encoded = try? JSONEncoder().encode(Array(keyboardSnippets)) {
            shared.set(encoded, forKey: "keyboard.snippets.v1")
        }
    }

    /// Imports snippets saved inside the keyboard extension (its ＋ button)
    /// from the shared inbox, then clears the inbox and republishes.
    func importKeyboardInbox() {
        guard let shared = UserDefaults(suiteName: "group.com.quickclip.app") else { return }
        guard let data = shared.data(forKey: "keyboard.inbox.v1") else { return }
        struct InboxItem: Codable { var id: UUID; var content: String }
        guard let items = try? JSONDecoder().decode([InboxItem].self, from: data),
              !items.isEmpty else { return }

        let existingContents = Set(snippets.map { $0.content.trimmingCharacters(in: .whitespacesAndNewlines) })
        var added = 0
        for item in items {
            let trimmed = item.content.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, !existingContents.contains(trimmed) else { continue }
            var title = String(trimmed.prefix(32))
            if title.isEmpty { title = "Untitled" }
            snippets.insert(Snippet(title: title,
                                    content: item.content,
                                    categoryID: nil,
                                    isPinned: false),
                            at: 0)
            existingContents.insert(trimmed)
            added += 1
        }
        shared.removeObject(forKey: "keyboard.inbox.v1")
        if added > 0 {
            save()
        }
    }

    // MARK: - Snippets

    func add(title: String, content: String, categoryID: UUID?, isPinned: Bool) {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        var resolvedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if resolvedTitle.isEmpty {
            resolvedTitle = String(trimmedContent.prefix(32))
        }
        if resolvedTitle.isEmpty { resolvedTitle = "Untitled" }

        let snippet = Snippet(title: resolvedTitle,
                              content: content,
                              categoryID: categoryID,
                              isPinned: isPinned)
        snippets.insert(snippet, at: 0)
        save()
    }

    func update(_ snippet: Snippet) {
        guard let index = snippets.firstIndex(where: { $0.id == snippet.id }) else { return }
        var updated = snippet
        updated.updatedAt = Date()
        snippets[index] = updated
        save()
    }

    func delete(_ snippet: Snippet) {
        snippets.removeAll { $0.id == snippet.id }
        save()
    }

    func deleteAll() {
        snippets.removeAll()
        save()
    }

    func togglePin(_ snippet: Snippet) {
        guard let index = snippets.firstIndex(where: { $0.id == snippet.id }) else { return }
        snippets[index].isPinned.toggle()
        save()
    }

    func category(withID id: UUID?) -> SnippetCategory? {
        guard let id = id else { return nil }
        return categories.first { $0.id == id }
    }

    // MARK: - Clipboard

    /// Writes the snippet content to the system clipboard instantly.
    func copy(_ snippet: Snippet) {
        let content = snippet.content
        if settings.autoClearSeconds > 0 {
            let expiration = Date().addingTimeInterval(TimeInterval(settings.autoClearSeconds))
            let options: [UIPasteboard.OptionsKey: Any] = [.expirationDate: expiration]
            UIPasteboard.general.setItems([[UTType.plainText.identifier: content]],
                                          options: options)
        } else {
            UIPasteboard.general.string = content
        }

        if let index = snippets.firstIndex(where: { $0.id == snippet.id }) {
            snippets[index].copyCount += 1
            snippets[index].lastCopiedAt = Date()
            save()
        }
        if settings.hapticsEnabled { Haptics.success() }
        showToast("Copied to clipboard")
    }

    func clearClipboard() {
        UIPasteboard.general.items = []
        if settings.hapticsEnabled { Haptics.light() }
        showToast("Clipboard cleared", icon: "trash.circle.fill")
    }

    // MARK: - Categories

    func addCategory(name: String, colorHex: String, systemImage: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        categories.append(SnippetCategory(name: trimmed,
                                          colorHex: colorHex,
                                          systemImage: systemImage))
        save()
    }

    func update(_ category: SnippetCategory) {
        guard let index = categories.firstIndex(where: { $0.id == category.id }) else { return }
        categories[index] = category
        save()
    }

    func delete(_ category: SnippetCategory) {
        categories.removeAll { $0.id == category.id }
        for index in snippets.indices where snippets[index].categoryID == category.id {
            snippets[index].categoryID = nil
        }
        save()
    }

    // MARK: - Sorting

    func sorted(_ items: [Snippet]) -> [Snippet] {
        switch settings.sortOption {
        case .dateAdded:
            return items.sorted { $0.createdAt > $1.createdAt }
        case .title:
            return items.sorted {
                $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
            }
        case .mostCopied:
            return items.sorted { $0.copyCount > $1.copyCount }
        case .recentlyCopied:
            return items.sorted {
                ($0.lastCopiedAt ?? .distantPast) > ($1.lastCopiedAt ?? .distantPast)
            }
        }
    }

    // MARK: - Toast

    func showToast(_ text: String, icon: String = "checkmark.circle.fill") {
        guard settings.showToast else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            toast = ToastData(text: text, icon: icon)
        }
    }

    func dismissToast() {
        withAnimation(.easeOut(duration: 0.25)) {
            toast = nil
        }
    }

    // MARK: - Reset

    func resetAll() {
        categories = SnippetCategory.defaultCategories
        snippets = Snippet.seedSnippets(categories: categories)
        settings = AppSettings()
        save()
    }
}
