import AppKit
import Combine

extension Window {
    final class Empty: NSView {
        private var subs = Set<AnyCancellable>()
        
        required init?(coder: NSCoder) { nil }
        init(info: CurrentValueSubject<[Info], Never>) {
            let text = Text(vibrancy: true)
            text.stringValue = "Loading..."
            text.textColor = .secondaryLabelColor
            text.font = .preferredFont(forTextStyle: .body)

            super.init(frame: .zero)
            translatesAutoresizingMaskIntoConstraints = false
            addSubview(text)
            text.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
            text.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
            
            info
                .dropFirst(2)
                .filter {
                    $0.isEmpty
                }
                .sink { _ in
                    text.stringValue = "No photos found"
                }
                .store(in: &subs)
        }
    }
}
