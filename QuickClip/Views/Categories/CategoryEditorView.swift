import SwiftUI
import UIKit

/// Sheet for creating or editing a category with live preview,
/// a preset color palette and an SF Symbol picker.
struct CategoryEditorView: View {
    @EnvironmentObject private var store: SnippetStore
    @Environment(\.dismiss) private var dismiss

    private let original: SnippetCategory?

    @State private var name: String
    @State private var colorHex: String
    @State private var systemImage: String

    static let palette = ["#0A84FF", "#FF9F0A", "#30D158", "#BF5AF2",
                          "#FF375F", "#64D2FF", "#FFD60A", "#8E8E93"]
    static let symbols = ["folder", "person.crop.circle", "briefcase", "banknote",
                          "link", "house", "heart", "cart", "gamecontroller",
                          "airplane", "book", "bolt.fill"]

    init(category: SnippetCategory?) {
        self.original = category
        _name = State(initialValue: category?.name ?? "")
        _colorHex = State(initialValue: category?.colorHex ?? Self.palette[0])
        _systemImage = State(initialValue: category?.systemImage ?? "folder")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Preview") {
                    HStack(spacing: 12) {
                        Image(systemName: systemImage)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(Color(hexString: colorHex))
                            .frame(width: 44, height: 44)
                            .background(Color(hexString: colorHex).opacity(0.14),
                                        in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                        Text(name.isEmpty ? "Category Name" : name)
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Section("Name") {
                    TextField("Category Name", text: $name)
                }

                Section("Color") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44), spacing: 12)],
                              spacing: 12) {
                        ForEach(Self.palette, id: \.self) { hex in
                            Button {
                                colorHex = hex
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(Color(hexString: hex))
                                        .frame(width: 36, height: 36)
                                    if colorHex == hex {
                                        Image(systemName: "checkmark")
                                            .font(.caption.weight(.bold))
                                            .foregroundStyle(.white)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Icon") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44), spacing: 12)],
                              spacing: 12) {
                        ForEach(Self.symbols, id: \.self) { symbol in
                            Button {
                                systemImage = symbol
                            } label: {
                                Image(systemName: symbol)
                                    .font(.system(size: 17))
                                    .frame(width: 38, height: 38)
                                    .background(systemImage == symbol
                                                ? Color.accentColor.opacity(0.18)
                                                : Color(uiColor: .secondarySystemFill),
                                                in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                                    .foregroundStyle(systemImage == symbol
                                                     ? Color.accentColor
                                                     : Color.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle(original == nil ? "New Category" : "Edit Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { save() }
                        .font(.body.weight(.semibold))
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if var category = original {
            category.name = trimmed
            category.colorHex = colorHex
            category.systemImage = systemImage
            store.update(category)
        } else {
            store.addCategory(name: trimmed, colorHex: colorHex, systemImage: systemImage)
        }
        dismiss()
    }
}
