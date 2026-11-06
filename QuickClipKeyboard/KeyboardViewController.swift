import UIKit

/// QuickClip keyboard extension.
/// Shows the user's snippets as a bar above the text field in any app.
/// Tapping a snippet inserts its text directly — no copy & paste needed.
/// The ＋ button saves new snippets right from the keyboard: either from the
/// clipboard (needs Allow Full Access) or from the text currently in the field.
/// Requires no network access: data travels through the shared App Group.
final class KeyboardViewController: UIInputViewController {

    // MARK: - Data model (mirrors what the main app publishes)

    private struct KeyboardSnippet: Codable {
        var id: UUID
        var title: String
        var content: String
        var colorHex: String?
        var isPinned: Bool
        var copyCount: Int
    }

    /// A snippet saved inside the keyboard, waiting for the app to import it.
    private struct InboxItem: Codable {
        var id: UUID
        var content: String
    }

    private enum Shared {
        static let suiteName = "group.com.quickclip.app"
        static let snippetsKey = "keyboard.snippets.v1"
        static let inboxKey = "keyboard.inbox.v1"
    }

    // MARK: - State

    private var snippets: [KeyboardSnippet] = []
    private var inbox: [InboxItem] = []
    private var showsList = false
    private var showsSavePanel = false
    private var heightConstraint: NSLayoutConstraint?
    private var flashWork: DispatchWorkItem?

    // MARK: - Views

    private let contentStack = UIStackView()
    private let headerBar = UIStackView()
    private let switcherButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let plusButton = UIButton(type: .system)
    private let modeButton = UIButton(type: .system)
    private let chipsScroll = UIScrollView()
    private let chipsStack = UIStackView()
    private let listScroll = UIScrollView()
    private let listStack = UIStackView()
    private let emptyLabel = UILabel()
    private let savePanel = UIView()
    private let hintLabel = UILabel()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        buildInterface()
        reloadSnippets()
        updateHeight()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadSnippets()
    }

    // MARK: - Interface building

    private func buildInterface() {
        switcherButton.setImage(UIImage(systemName: "globe"), for: .normal)
        switcherButton.tintColor = .secondaryLabel
        switcherButton.accessibilityLabel = "Next keyboard"
        switcherButton.addAction(UIAction { [weak self] _ in
            self?.advanceToNextInputMode()
        }, for: .touchUpInside)

        titleLabel.text = "QuickClip"
        titleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        titleLabel.textColor = .secondaryLabel

        plusButton.setImage(UIImage(systemName: "plus"), for: .normal)
        plusButton.tintColor = .secondaryLabel
        plusButton.accessibilityLabel = "Save a new snippet"
        plusButton.addAction(UIAction { [weak self] _ in
            self?.toggleSavePanel()
        }, for: .touchUpInside)

        modeButton.setImage(UIImage(systemName: "list.bullet"), for: .normal)
        modeButton.tintColor = .secondaryLabel
        modeButton.accessibilityLabel = "Toggle snippet list"
        modeButton.addAction(UIAction { [weak self] _ in
            self?.toggleMode()
        }, for: .touchUpInside)

        headerBar.axis = .horizontal
        headerBar.alignment = .center
        headerBar.spacing = 10
        headerBar.isLayoutMarginsRelativeArrangement = true
        headerBar.layoutMargins = UIEdgeInsets(top: 2, left: 8, bottom: 2, right: 8)
        headerBar.addArrangedSubview(switcherButton)
        headerBar.addArrangedSubview(titleLabel)
        headerBar.addArrangedSubview(makeSpacer())
        headerBar.addArrangedSubview(plusButton)
        headerBar.addArrangedSubview(modeButton)

        chipsScroll.showsHorizontalScrollIndicator = false
        chipsScroll.showsVerticalScrollIndicator = false
        chipsStack.axis = .horizontal
        chipsStack.alignment = .center
        chipsStack.spacing = 8
        chipsScroll.addSubview(chipsStack)
        chipsStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            chipsStack.leadingAnchor.constraint(
                equalTo: chipsScroll.contentLayoutGuide.leadingAnchor, constant: 10),
            chipsStack.trailingAnchor.constraint(
                equalTo: chipsScroll.contentLayoutGuide.trailingAnchor, constant: -10),
            chipsStack.topAnchor.constraint(
                equalTo: chipsScroll.contentLayoutGuide.topAnchor, constant: 4),
            chipsStack.bottomAnchor.constraint(
                equalTo: chipsScroll.contentLayoutGuide.bottomAnchor, constant: -4),
        ])

        listScroll.showsVerticalScrollIndicator = true
        listStack.axis = .vertical
        listStack.spacing = 2
        listScroll.addSubview(listStack)
        listStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            listStack.leadingAnchor.constraint(
                equalTo: listScroll.contentLayoutGuide.leadingAnchor, constant: 6),
            listStack.trailingAnchor.constraint(
                equalTo: listScroll.contentLayoutGuide.trailingAnchor, constant: -6),
            listStack.topAnchor.constraint(
                equalTo: listScroll.contentLayoutGuide.topAnchor, constant: 2),
            listStack.bottomAnchor.constraint(
                equalTo: listScroll.contentLayoutGuide.bottomAnchor, constant: -2),
            listStack.widthAnchor.constraint(
                equalTo: listScroll.frameLayoutGuide.widthAnchor, constant: -12),
        ])

        emptyLabel.text = "No snippets yet.\nTap ＋ to save one right here, or open QuickClip."
        emptyLabel.numberOfLines = 0
        emptyLabel.textAlignment = .center
        emptyLabel.font = .systemFont(ofSize: 13)
        emptyLabel.textColor = .secondaryLabel

        buildSavePanel()

        contentStack.axis = .vertical
        contentStack.distribution = .fill
        contentStack.spacing = 4
        contentStack.addArrangedSubview(headerBar)
        contentStack.addArrangedSubview(chipsScroll)
        contentStack.addArrangedSubview(listScroll)
        contentStack.addArrangedSubview(savePanel)
        contentStack.addArrangedSubview(emptyLabel)
        listScroll.isHidden = true
        savePanel.isHidden = true
        emptyLabel.isHidden = true

        chipsScroll.translatesAutoresizingMaskIntoConstraints = false
        listScroll.translatesAutoresizingMaskIntoConstraints = false
        savePanel.translatesAutoresizingMaskIntoConstraints = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contentStack)
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: view.topAnchor, constant: 6),
            contentStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 4),
            contentStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -4),
            contentStack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -6),
            chipsScroll.heightAnchor.constraint(equalToConstant: 48),
            savePanel.heightAnchor.constraint(equalToConstant: 118),
        ])
    }

    private func buildSavePanel() {
        let panelStack = UIStackView()
        panelStack.axis = .vertical
        panelStack.alignment = .fill
        panelStack.spacing = 6
        panelStack.isLayoutMarginsRelativeArrangement = true
        panelStack.layoutMargins = UIEdgeInsets(top: 2, left: 8, bottom: 2, right: 8)

        hintLabel.text = "Save a new snippet without leaving this app."
        hintLabel.numberOfLines = 2
        hintLabel.font = .systemFont(ofSize: 11)
        hintLabel.textColor = .secondaryLabel

        let clipboardButton = UIButton(type: .system)
        var clipboardConfig = UIButton.Configuration.gray()
        clipboardConfig.title = "Save from Clipboard"
        clipboardConfig.image = UIImage(systemName: "doc.on.clipboard")
        clipboardConfig.imagePadding = 8
        clipboardConfig.cornerStyle = .medium
        clipboardConfig.baseForegroundColor = .label
        clipboardConfig.titleAlignment = .leading
        clipboardButton.configuration = clipboardConfig
        clipboardButton.addAction(UIAction { [weak self] _ in
            self?.saveFromClipboard()
        }, for: .touchUpInside)

        let typedButton = UIButton(type: .system)
        var typedConfig = UIButton.Configuration.gray()
        typedConfig.title = "Save Typed Text"
        typedConfig.image = UIImage(systemName: "character.cursor.ibeam")
        typedConfig.imagePadding = 8
        typedConfig.cornerStyle = .medium
        typedConfig.baseForegroundColor = .label
        typedConfig.titleAlignment = .leading
        typedButton.configuration = typedConfig
        typedButton.addAction(UIAction { [weak self] _ in
            self?.saveTypedText()
        }, for: .touchUpInside)

        panelStack.addArrangedSubview(hintLabel)
        panelStack.addArrangedSubview(clipboardButton)
        panelStack.addArrangedSubview(typedButton)

        savePanel.addSubview(panelStack)
        panelStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            panelStack.topAnchor.constraint(equalTo: savePanel.topAnchor),
            panelStack.bottomAnchor.constraint(equalTo: savePanel.bottomAnchor),
            panelStack.leadingAnchor.constraint(equalTo: savePanel.leadingAnchor),
            panelStack.trailingAnchor.constraint(equalTo: savePanel.trailingAnchor),
        ])
    }

    private func makeSpacer() -> UIView {
        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return spacer
    }

    // MARK: - Data

    private func reloadSnippets() {
        let defaults = UserDefaults(suiteName: Shared.suiteName) ?? .standard
        if let data = defaults.data(forKey: Shared.snippetsKey),
           let list = try? JSONDecoder().decode([KeyboardSnippet].self, from: data) {
            snippets = list
        } else {
            snippets = []
        }
        if let data = defaults.data(forKey: Shared.inboxKey),
           let list = try? JSONDecoder().decode([InboxItem].self, from: data) {
            inbox = list
        } else {
            inbox = []
        }
        rebuildAll()
    }

    private func rebuildAll() {
        rebuildChips()
        rebuildList()
        updateEmptyState()
    }

    /// Published snippets + items saved in the keyboard (deduped by content).
    private var displaySnippets: [KeyboardSnippet] {
        let publishedContents = Set(snippets.map { $0.content })
        let extras = inbox
            .filter { !publishedContents.contains($0.content) }
            .map { item in
                let trimmed = item.content.trimmingCharacters(in: .whitespacesAndNewlines)
                return KeyboardSnippet(id: item.id,
                                       title: String(trimmed.prefix(28)),
                                       content: item.content,
                                       colorHex: nil,
                                       isPinned: false,
                                       copyCount: 0)
            }
        return snippets + extras
    }

    private var sortedSnippets: [KeyboardSnippet] {
        displaySnippets.sorted { lhs, rhs in
            if lhs.isPinned != rhs.isPinned { return lhs.isPinned }
            if lhs.copyCount != rhs.copyCount { return lhs.copyCount > rhs.copyCount }
            return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
        }
    }

    private func rebuildChips() {
        chipsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for snippet in sortedSnippets.prefix(20) {
            chipsStack.addArrangedSubview(makeChip(snippet))
        }
    }

    private func rebuildList() {
        listStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for snippet in sortedSnippets {
            listStack.addArrangedSubview(makeRow(snippet))
        }
    }

    // MARK: - Rows

    private func makeChip(_ snippet: KeyboardSnippet) -> UIButton {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.gray()
        config.title = String(snippet.title.prefix(28))
        config.titleLineBreakMode = .byTruncatingTail
        config.baseForegroundColor = .label
        config.cornerStyle = .capsule
        config.buttonSize = .mini
        config.contentInsets = NSDirectionalEdgeInsets(top: 7, leading: 12, bottom: 7, trailing: 12)
        if let color = color(fromHex: snippet.colorHex) {
            config.image = dotImage(color)
            config.imagePadding = 6
        } else if snippet.isPinned {
            config.image = UIImage(systemName: "pin.fill")
            config.imagePadding = 6
        }
        button.configuration = config
        button.addAction(UIAction { [weak self] _ in
            self?.insert(snippet)
        }, for: .touchUpInside)
        return button
    }

    private func makeRow(_ snippet: KeyboardSnippet) -> UIButton {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.plain()
        config.title = snippet.title
        config.titleLineBreakMode = .byTruncatingTail
        config.subtitle = snippet.content
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespaces)
            .prefix(80)
            .description
        config.subtitleLineBreakMode = .byTruncatingTail
        config.titleAlignment = .leading
        config.image = UIImage(systemName: snippet.isPinned ? "pin.fill" : "doc.on.doc")
        config.imagePadding = 10
        config.cornerStyle = .large
        config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        button.configuration = config
        button.addAction(UIAction { [weak self] _ in
            self?.insert(snippet)
        }, for: .touchUpInside)
        return button
    }

    // MARK: - Actions

    private func insert(_ snippet: KeyboardSnippet) {
        textDocumentProxy.insertText(snippet.content)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func toggleMode() {
        showsList.toggle()
        modeButton.setImage(UIImage(systemName: showsList ? "slider.horizontal.3" : "list.bullet"),
                            for: .normal)
        updateEmptyState()
        updateHeight()
    }

    private func toggleSavePanel() {
        showsSavePanel.toggle()
        plusButton.setImage(UIImage(systemName: showsSavePanel ? "xmark" : "plus"), for: .normal)
        if showsSavePanel {
            hintLabel.text = "Save a new snippet without leaving this app."
        }
        updateEmptyState()
        updateHeight()
    }

    private func saveFromClipboard() {
        guard hasFullAccess else {
            showHint("To read the clipboard, enable Allow Full Access: Settings → General → Keyboard → Keyboards → QuickClip → turn on Allow Full Access.")
            return
        }
        if let text = UIPasteboard.general.string,
           !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            saveToInbox(text)
        } else {
            showHint("The clipboard is empty.")
        }
    }

    private func saveTypedText() {
        let proxy = textDocumentProxy
        let content = (proxy.documentContextBeforeInput ?? "")
            + (proxy.selectedText ?? "")
            + (proxy.documentContextAfterInput ?? "")
        if content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            showHint("Nothing to save — the text field is empty.")
        } else {
            saveToInbox(content)
        }
    }

    /// Appends the text to the shared inbox; the app imports it on next launch.
    private func saveToInbox(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let allContents = Set(displaySnippets.map { $0.content })
        if allContents.contains(trimmed) {
            flashSaved("Already saved ✓")
            return
        }
        let defaults = UserDefaults(suiteName: Shared.suiteName) ?? .standard
        var items: [InboxItem] = inbox
        items.append(InboxItem(id: UUID(), content: String(trimmed.prefix(5000))))
        if let encoded = try? JSONEncoder().encode(items) {
            defaults.set(encoded, forKey: Shared.inboxKey)
        }
        reloadSnippets()
        flashSaved("Saved ✓")
    }

    // MARK: - Feedback

    private func showHint(_ text: String) {
        hintLabel.text = text
        if !showsSavePanel { toggleSavePanel() }
    }

    private func flashSaved(_ text: String) {
        flashWork?.cancel()
        titleLabel.text = text
        titleLabel.textColor = .systemGreen
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.titleLabel.text = "QuickClip"
            self.titleLabel.textColor = .secondaryLabel
        }
        flashWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4, execute: work)
    }

    // MARK: - Layout helpers

    private func updateEmptyState() {
        let empty = displaySnippets.isEmpty
        emptyLabel.text = "No snippets yet.\nTap ＋ to save one right here, or open QuickClip."
        emptyLabel.isHidden = !empty || showsSavePanel
        chipsScroll.isHidden = empty || showsList || showsSavePanel
        listScroll.isHidden = empty || !showsList || showsSavePanel
        savePanel.isHidden = !showsSavePanel
        modeButton.isEnabled = !empty
    }

    private func updateHeight() {
        let target: CGFloat
        if showsSavePanel {
            target = 230
        } else if showsList {
            target = 320
        } else {
            target = 200
        }
        if let constraint = heightConstraint {
            constraint.constant = target
        } else {
            let constraint = view.heightAnchor.constraint(equalToConstant: target)
            constraint.priority = UILayoutPriority(999)
            constraint.isActive = true
            heightConstraint = constraint
        }
    }

    // MARK: - Colors

    private func color(fromHex hex: String?) -> UIColor? {
        guard let hex = hex else { return nil }
        let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "# "))
        guard cleaned.count == 6, let value = UInt64(cleaned, radix: 16) else { return nil }
        return UIColor(red: CGFloat((value >> 16) & 0xFF) / 255.0,
                       green: CGFloat((value >> 8) & 0xFF) / 255.0,
                       blue: CGFloat(value & 0xFF) / 255.0,
                       alpha: 1.0)
    }

    private func dotImage(_ color: UIColor) -> UIImage {
        let size = CGSize(width: 9, height: 9)
        return UIGraphicsImageRenderer(size: size).image { _ in
            color.setFill()
            UIBezierPath(ovalIn: CGRect(origin: .zero, size: size)).fill()
        }
    }
}
