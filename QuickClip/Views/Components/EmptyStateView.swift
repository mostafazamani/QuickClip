import SwiftUI

/// Friendly placeholder shown when a collection is empty.
struct EmptyStateView: View {
    var systemImage: String = "doc.on.doc"
    var title: String = "No Snippets Yet"
    var message: String = "Tap + to add your first snippet, or use the ••• menu to capture whatever is currently on your clipboard."

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 52, weight: .light))
                .foregroundStyle(.tertiary)
            Text(title)
                .font(.title3.weight(.semibold))
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
