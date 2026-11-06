import SwiftUI

/// Visual representation of one snippet inside the list.
struct SnippetRowView: View {
    let snippet: Snippet
    let category: SnippetCategory?

    private var categoryColor: Color {
        Color(hexString: category?.colorHex ?? "#8E8E93")
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: category?.systemImage ?? "doc.plaintext")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(categoryColor)
                .frame(width: 34, height: 34)
                .background(categoryColor.opacity(0.14),
                            in: RoundedRectangle(cornerRadius: 9, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 5) {
                    if snippet.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                    Text(snippet.title)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                }

                Text(snippet.preview)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Image(systemName: "doc.on.doc")
                        .font(.caption2)
                    Text("\(snippet.copyCount)")
                    Text("·")
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text(snippet.createdAt, style: .relative)
                }
                .font(.caption2)
                .foregroundStyle(.tertiary)
            }

            Spacer(minLength: 8)
        }
        .padding(.vertical, 2)
    }
}
