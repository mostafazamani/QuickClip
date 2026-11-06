import Foundation

/// A user-defined group used to organize snippets.
struct SnippetCategory: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var colorHex: String      // e.g. "#0A84FF"
    var systemImage: String   // SF Symbol name, e.g. "briefcase"

    static let defaultCategories: [SnippetCategory] = [
        SnippetCategory(name: "Personal", colorHex: "#0A84FF", systemImage: "person.crop.circle"),
        SnippetCategory(name: "Work", colorHex: "#FF9F0A", systemImage: "briefcase"),
        SnippetCategory(name: "Finance", colorHex: "#30D158", systemImage: "banknote"),
        SnippetCategory(name: "Links", colorHex: "#BF5AF2", systemImage: "link")
    ]
}
