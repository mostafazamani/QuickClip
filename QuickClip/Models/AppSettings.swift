import Foundation

/// How the snippet list is ordered.
enum SnippetSort: String, CaseIterable, Codable, Identifiable {
    case dateAdded = "Date Added"
    case title = "Title"
    case mostCopied = "Most Copied"
    case recentlyCopied = "Recently Copied"

    var id: String { rawValue }
}

/// User preferences, persisted together with the data.
struct AppSettings: Codable, Equatable {
    /// Tapping a snippet copies it instantly instead of opening the editor.
    var copyOnTap = true
    var hapticsEnabled = true
    var showToast = true
    /// 0 = never clear; otherwise seconds until the clipboard expires.
    var autoClearSeconds = 0
    var sortOption: SnippetSort = .dateAdded
}
