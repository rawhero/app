import AppKit
import Core

extension Launch {
    final class Item: Control {
        required init?(coder: NSCoder) { nil }
        init(bookmark: Bookmark) {
            let text = Text(vibrancy: true)
            text.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            text.maximumNumberOfLines = 2
            
            let components = bookmark
                .id
                .replacingOccurrences(of: "file://", with: "")
                .components(separatedBy: "/")
                .dropLast()
            
            if !components.isEmpty {
                text.attributedStringValue = .make(lineBreak: .byTruncatingMiddle) { string in
                    string.append(.make(components.last!, attributes: [
                        .font: NSFont.systemFont(ofSize: NSFont.preferredFont(forTextStyle: .title3).pointSize, weight: .regular),
                        .foregroundColor: NSColor.labelColor]))
                    
                    let remain = components
                        .dropLast()
                        .joined(separator: "/")
                    
                    if !remain.isEmpty {
                        string.newLine()
                        string.append(.make(remain + "/", attributes: [
                            .font: NSFont.preferredFont(forTextStyle: .callout),
                            .foregroundColor: NSColor.tertiaryLabelColor]))
                    }
                }
            }
            
            super.init(layer: true)
            layer!.cornerRadius = 6
            addSubview(text)
            
            widthAnchor.constraint(equalToConstant: 410).isActive = true
            heightAnchor.constraint(equalToConstant: 56).isActive = true
            
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
