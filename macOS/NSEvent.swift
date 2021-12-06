import AppKit

extension NSEvent {
    var multiple: Bool {
        modifierFlags.contains(.command) || modifierFlags.contains(.shift)
    }
}
