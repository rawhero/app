import AppKit

extension Window {
    final class Empty: NSView {
        required init?(coder: NSCoder) { nil }
        required init() {
            let text = Text(vibrancy: true)
            text.stringValue = "No photos found"
            text.textColor = .secondaryLabelColor
            text.font = .preferredFont(forTextStyle: .body)

            super.init(frame: .zero)
            translatesAutoresizingMaskIntoConstraints = false
            addSubview(text)
            text.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
            text.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        }
    }
}
