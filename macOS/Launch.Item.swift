import AppKit
import Core

extension Launch {
    final class Item: Control {
        required init?(coder: NSCoder) { nil }
        init(bookmark: Bookmark) {
            let text = Text(vibrancy: true)
            text.stringValue = bookmark.id.replacingOccurrences(of: "file://", with: "")
            text.textColor = .secondaryLabelColor
            text.font = .preferredFont(forTextStyle: .body)
            text.lineBreakMode = .byTruncatingMiddle
            text.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            
            super.init(layer: true)
            layer!.cornerRadius = 6
            addSubview(text)
            
            widthAnchor.constraint(equalToConstant: 410).isActive = true
            heightAnchor.constraint(equalToConstant: 38).isActive = true
            
            text.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
            text.leftAnchor.constraint(equalTo: leftAnchor, constant: 12).isActive = true
            text.rightAnchor.constraint(lessThanOrEqualTo: rightAnchor, constant: -12).isActive = true
        }
        
        override func updateLayer() {
            super.updateLayer()
            
            switch state {
            case .pressed, .highlighted:
                layer!.backgroundColor = NSColor.labelColor.withAlphaComponent(0.15).cgColor
            default:
                layer!.backgroundColor = NSColor.labelColor.withAlphaComponent(0.05).cgColor
            }
        }
        
        override var allowsVibrancy: Bool {
            true
        }
    }
}
