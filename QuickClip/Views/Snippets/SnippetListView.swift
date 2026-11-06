import SwiftUI
import UIKit

/// Main screen: searchable, filterable list of snippets with one-tap copy.
struct SnippetListView: View {
    @EnvironmentObject private var store: SnippetStore

    @State private var searchText = ""
    @State private var filterCategoryID: UUID?
    @State private var activeSheet: ActiveSheet?
    @State private var showDeleteAllConfirm = false

    private enum ActiveSheet: Identifiable {
        case new(fromClipboard: Bool)
        case edit(Snippet)

        var id: String {
            switch self {
            case .new(let fromClipboard):
                return "new-\(fromClipboard)"
            case .edit(let snippet):
                return "edit-\(snippet.id.uuidString)"
            }
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if store.snippets.isEmpty {
                    EmptyStateView()
                } else {
                    VStack(spacing: 0) {
                        filterChips
                        snippetList
                    }
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("QuickClip")
            .searchable(text: $searchText, prompt: "Search snippets")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    sortMenu
                    addButton
                }
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .new(let fromClipboard):
                    SnippetEditorView(snippet: nil, fromClipboard: fromClipboard)
                case .edit(let snippet):
                    SnippetEditorView(snippet: snippet)
                }
            }
            .confirmationDialog("Delete all snippets?",
                                isPresented: $showDeleteAllConfirm,
                                titleVisibility: .visible) {
                Button("Delete All Snippets", role: .destructive) {
                    store.deleteAll()
                    store.showToast("All snippets deleted", icon: "trash.circle.fill")
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This removes every snippet from the app. It cannot be undone.")
            }
        }
    }

    // MARK: - Toolbar

    private var sortMenu: some View {
        Menu {
            Picker("Sort By", selection: $store.settings.sortOption) {
                ForEach(SnippetSort.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            Divider()
            Button {
                activeSheet = .new(fromClipboard: true)
            } label: {
                Label("New from Clipboard", systemImage: "arrow.down.doc")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }

    private var addButton: some View {
        Button {
            activeSheet = .new(fromClipboard: false)
        } label: {
            Image(systemName: "plus")
        }
    }

    // MARK: - Filtering

    private var filteredSnippets: [Snippet] {
        var items = store.snippets
        if let id = filterCategoryID {
            items = items.filter { $0.categoryID == id }
        }
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !query.isEmpty {
            items = items.filter {
                $0.title.localizedCaseInsensitiveContains(query) ||
                $0.content.localizedCaseInsensitiveContains(query)
            }
        }
        return store.sorted(items)
    }

    private var pinnedSnippets: [Snippet] {
        filteredSnippets.filter { $0.isPinned }
    }

    private var regularSnippets: [Snippet] {
        filteredSnippets.filter { !$0.isPinned }
    }

    // MARK: - Views

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(title: "All", icon: "square.grid.2x2", id: nil)
                ForEach(store.categories) { category in
                    chip(title: category.name,
                         icon: category.systemImage,
                         id: category.id)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    private func chip(title: String, icon: String, id: UUID?) -> some View {
        let isSelected = filterCategoryID == id
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                filterCategoryID = id
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.footnote.weight(.medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(isSelected ? Color.accentColor : Color(uiColor: .secondarySystemFill),
                        in: Capsule())
            .foregroundStyle(isSelected ? Color.white : Color.primary)
        }
        .buttonStyle(.plain)
    }

    private var snippetList: some View {
        List {
            let pinned = pinnedSnippets
            let regular = regularSnippets

            if pinned.isEmpty && regular.isEmpty {
                Section {
                    Text("No snippets match your search or filter.")
                        .foregroundStyle(.secondary)
                }
            }

            if !pinned.isEmpty {
                Section("Pinned") {
                    ForEach(pinned) { snippet in
                        row(for: snippet)
                    }
                }
            }

            if !regular.isEmpty {
                Section(pinned.isEmpty ? "All Snippets" : "Others") {
                    ForEach(regular) { snippet in
                        row(for: snippet)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func row(for snippet: Snippet) -> some View {
        HStack(spacing: 10) {
            SnippetRowView(snippet: snippet,
                           category: store.category(withID: snippet.categoryID))
            Button {
                store.copy(snippet)
            } label: {
                Image(systemName: "doc.on.doc")
                    .font(.body)
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Copy \(snippet.title)")
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if store.settings.copyOnTap {
                store.copy(snippet)
            } else {
                activeSheet = .edit(snippet)
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                store.copy(snippet)
            } label: {
                Label("Copy", systemImage: "doc.on.doc.fill")
            }
            .tint(Color.accentColor)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button {
                activeSheet = .edit(snippet)
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.orange)
            Button(role: .destructive) {
                store.delete(snippet)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .contextMenu {
            Button {
                store.copy(snippet)
            } label: {
                Label("Copy to Clipboard", systemImage: "doc.on.doc")
            }
            Button {
                store.togglePin(snippet)
            } label: {
                Label(snippet.isPinned ? "Unpin" : "Pin to Top",
                      systemImage: snippet.isPinned ? "pin.slash" : "pin")
            }
            Button {
                activeSheet = .edit(snippet)
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            ShareLink(item: snippet.content) {
                Label("Share", systemImage: "square.and.arrow.up")
            }
            Divider()
            Button(role: .destructive) {
                store.delete(snippet)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
