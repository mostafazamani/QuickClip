import Foundation

/// A single piece of text the user wants to keep for quick copying.
struct Snippet: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var content: String
    var categoryID: UUID?
    var isPinned = false
    var copyCount = 0
    var lastCopiedAt: Date?
    var createdAt = Date()
    var updatedAt = Date()

    /// Short single-line preview of the content for list rows.
    var preview: String {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "Empty snippet" }
        if trimmed.count <= 80 { return trimmed }
        return String(trimmed.prefix(80)) + "…"
    }
}

extension Snippet {
    /// Friendly sample data shown on first launch so the app is not empty.
    static func seedSnippets(categories: [SnippetCategory]) -> [Snippet] {
        func categoryID(named name: String) -> UUID? {
            categories.first { $0.name == name }?.id
        }

        var email = Snippet(title: "Email Address",
                            content: "john.doe@example.com",
                            categoryID: categoryID(named: "Personal"))
        email.isPinned = true
        email.copyCount = 14
        email.createdAt = Date(timeIntervalSinceNow: -6 * 86400)
        email.updatedAt = email.createdAt

        var phone = Snippet(title: "Phone Number",
                            content: "+1 (555) 123-4567",
                            categoryID: categoryID(named: "Personal"))
        phone.copyCount = 6
        phone.createdAt = Date(timeIntervalSinceNow: -5 * 86400)
        phone.updatedAt = phone.createdAt

        var address = Snippet(title: "Shipping Address",
                              content: "221B Baker Street\nLondon NW1 6XE\nUnited Kingdom",
                              categoryID: categoryID(named: "Personal"))
        address.copyCount = 3
        address.createdAt = Date(timeIntervalSinceNow: -4 * 86400)
        address.updatedAt = address.createdAt

        var wifi = Snippet(title: "Wi-Fi Password",
                           content: "HomeNetwork-2024!",
                           categoryID: categoryID(named: "Personal"))
        wifi.copyCount = 9
        wifi.createdAt = Date(timeIntervalSinceNow: -3 * 86400)
        wifi.updatedAt = wifi.createdAt

        var meeting = Snippet(title: "Meeting Notes Template",
                              content: "Agenda:\n- \n\nNotes:\n- \n\nAction items:\n- ",
                              categoryID: categoryID(named: "Work"))
        meeting.copyCount = 2
        meeting.createdAt = Date(timeIntervalSinceNow: -2 * 86400)
        meeting.updatedAt = meeting.createdAt

        var github = Snippet(title: "GitHub Profile",
                             content: "https://github.com/yourusername",
                             categoryID: categoryID(named: "Links"))
        github.copyCount = 4
        github.createdAt = Date(timeIntervalSinceNow: -1 * 86400)
        github.updatedAt = github.createdAt

        var card = Snippet(title: "Bank Card Number",
                           content: "**** **** **** 1234",
                           categoryID: categoryID(named: "Finance"))
        card.copyCount = 1
        card.createdAt = Date(timeIntervalSinceNow: -12 * 3600)
        card.updatedAt = card.createdAt

        return [email, phone, address, wifi, meeting, github, card]
    }
}
