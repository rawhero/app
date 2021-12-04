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
                            self?.image.contents = image
                        case .error:
                            self?.image.contentsGravity = .center
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
            image.contentsGravity = .resizeAspect
            self.image = image
            
            super.init(frame: .zero)
            layer = Layer()
            wantsLayer = true
            layer!.backgroundColor = NSColor.controlBackgroundColor.cgColor
            layer!.addSublayer(image)
        }
    }
}
