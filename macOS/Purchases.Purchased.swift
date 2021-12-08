import AppKit

extension Purchases {
    final class Purchased: NSView {
        required init?(coder: NSCoder) { nil }
        init() {
            super.init(frame: .zero)
            
            let check = Image(icon: "checkmark.circle.fill")
            check.symbolConfiguration = .init(pointSize: 30, weight: .regular)
                .applying(.init(hierarchicalColor: .controlAccentColor))
            addSubview(check)
            
            let text = Text(vibrancy: true)
            text.attributedStringValue = .make(alignment: .center) {
                $0.append(.make("We received your support", attributes: [
                    .foregroundColor: NSColor.secondaryLabelColor]))
                $0.newLine()
                $0.append(.make("Thank you!", attributes: [
                    .foregroundColor: NSColor.labelColor]))
            }
            text.font = .preferredFont(forTextStyle: .body)
            addSubview(text)
            
            check.topAnchor.constraint(equalTo: topAnchor, constant: 30).isActive = true
            check.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
            
            text.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
            text.topAnchor.constraint(equalTo: check.bottomAnchor, constant: 15).isActive = true
        }
    }
}
