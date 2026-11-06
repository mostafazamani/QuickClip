import SwiftUI
import UIKit

/// Tab that manages snippet categories.
struct CategoryListView: View {
    @EnvironmentObject private var store: SnippetStore

    @State private var editingCategory: SnippetCategory?
    @State private var showAddSheet = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(store.categories) { category in
                        Button {
                            editingCategory = category
                        } label: {
                            row(for: category)
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete { offsets in
                        let toDelete = offsets.compactMap { index in
                            index < store.categories.count ? store.categories[index] : nil
                        }
                        for category in toDelete {
                            store.delete(category)
                        }
                    }
                } header: {
                    Text("Categories")
                } footer: {
                    Text("Snippets in a deleted category are kept and become uncategorized. Tap a category to rename it or change its color and icon.")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Categories")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(item: $editingCategory) { category in
                CategoryEditorView(category: category)
            }
            .sheet(isPresented: $showAddSheet) {
                CategoryEditorView(category: nil)
            }
        }
    }

    private func row(for category: SnippetCategory) -> some View {
        let color = Color(hexString: category.colorHex)
        let count = store.snippets.filter { $0.categoryID == category.id }.count
        return HStack(spacing: 12) {
            Image(systemName: category.systemImage)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(color)
                .frame(width: 34, height: 34)
                .background(color.opacity(0.14),
                            in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            Text(category.name)
                .font(.body)
            Spacer()
            Text("\(count) snippet\(count == 1 ? "" : "s")")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
    }
}
