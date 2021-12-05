import AppKit
import Combine
import Core

extension Export {
    final class Item: NSView {
        required init?(coder: NSCoder) { nil }
        init(picture: Core.Picture) {
            super.init(frame: .zero)
            translatesAutoresizingMaskIntoConstraints = false
            layer = Layer()
            wantsLayer = true
            layer!.backgroundColor = NSColor.labelColor.withAlphaComponent(0.05).cgColor
            
            widthAnchor.constraint(equalToConstant: 380).isActive = true
            heightAnchor.constraint(equalToConstant: 100).isActive = true
        }
    }
}
