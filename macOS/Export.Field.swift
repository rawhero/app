import AppKit

extension Export {
    final class Field: NSTextField {
        required init?(coder: NSCoder) { nil }
        init() {
            super.init(frame: .zero)
            bezelStyle = .roundedBezel
            translatesAutoresizingMaskIntoConstraints = false
            font = .monospacedSystemFont(ofSize: NSFont.preferredFont(forTextStyle: .body).pointSize, weight: .regular)
            controlSize = .large
            lineBreakMode = .byTruncatingTail
            textColor = .labelColor
            isAutomaticTextCompletionEnabled = false
            refusesFirstResponder = true
            alignment = .right
            
            widthAnchor.constraint(equalToConstant: 105).isActive = true
        }
        
        deinit {
            NSApp
                .windows
                .forEach {
                    $0.undoManager?.removeAllActions()
                }
        }
        
        override func cancelOperation(_: Any?) {
            window?.makeFirstResponder(nil)
        }
    }
}
