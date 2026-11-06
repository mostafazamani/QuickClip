import SwiftUI

/// Floating confirmation capsule shown after actions like copying.
struct ToastView: View {
    @EnvironmentObject private var store: SnippetStore

    var body: some View {
        if let toast = store.toast {
            HStack(spacing: 8) {
                Image(systemName: toast.icon)
                    .foregroundStyle(.green)
                Text(toast.text)
                    .font(.subheadline.weight(.medium))
            }
            .foregroundStyle(.primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.regularMaterial, in: Capsule())
            .overlay(Capsule().strokeBorder(Color.black.opacity(0.06)))
            .shadow(color: .black.opacity(0.14), radius: 14, x: 0, y: 5)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .task(id: toast.id) {
                try? await Task.sleep(nanoseconds: 1_600_000_000)
                if store.toast?.id == toast.id {
                    store.dismissToast()
                }
            }
        }
    }
}
