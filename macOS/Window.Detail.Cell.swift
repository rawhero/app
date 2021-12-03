import AppKit
import Combine

extension Window.Detail {
    final class Cell: NSView {
        private weak var image: CollectionImage!
        private var sub: AnyCancellable?
        
        var info: Window.Info? {
            didSet {
                guard let info = info else { return }
                sub = info
                    .hd
                    .sink { [weak self] in
                        switch $0 {
                        case let .image(image):
                            let transition = CATransition()
                            transition.timingFunction = .init(name: .easeInEaseOut)
                            transition.type = .fade
                            transition.duration = 0.5
                            self?.image.add(transition, forKey: "transition")
                            self?.image.contents = image
                            self?.image.contentsGravity = .resizeAspect
                        case .error:
                            self?.image.contents = NSImage(
                                systemSymbolName: "exclamationmark.triangle.fill",
                                accessibilityDescription: nil)?
                                .withSymbolConfiguration(.init(pointSize: 20, weight: .light)
                                                            .applying(.init(hierarchicalColor: .systemPink)))
                        }
                    }
            }
        }
        
        override var frame: NSRect {
            didSet {
                image.frame.size = frame.size
            }
        }
        
        required init?(coder: NSCoder) { nil }
        required init() {
            let image = CollectionImage()
            image.contents = NSImage(systemSymbolName: "photo.circle.fill", accessibilityDescription: nil)?
                .withSymbolConfiguration(.init(pointSize: 25, weight: .light)
                                            .applying(.init(hierarchicalColor: .quaternaryLabelColor)))
            image.contentsGravity = .center
            
            self.image = image
            
            super.init(frame: .zero)
            layer = Layer()
            wantsLayer = true
            layer!.backgroundColor = NSColor.controlBackgroundColor.cgColor
            layer!.addSublayer(image)
        }
    }
}
