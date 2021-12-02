import AppKit
import Combine

extension Window.Detail {
    final class Cell: NSView {
        private weak var image: CollectionImage!
        private var sub: AnyCancellable?
        
        var info: Window.Info? {
            didSet {
                guard
                    info != oldValue,
                    let info = info
                else { return }
                
                sub?.cancel()
                image.contents = NSImage(systemSymbolName: "photo.circle.fill", accessibilityDescription: nil)?
                    .withSymbolConfiguration(.init(pointSize: 15, weight: .light)
                                                .applying(.init(hierarchicalColor: .quaternaryLabelColor)))
                image.contentsGravity = .center
                sub = info
                    .thumbnail
                    .sink { [weak self] in
                        switch $0 {
                        case let .image(image):
                            self?.image.contents = image
                            self?.image.contentsGravity = .resizeAspectFill
                        case .error:
                            self?.image.contents = NSImage(systemSymbolName: "exclamationmark.triangle.fill", accessibilityDescription: nil)?
                                .withSymbolConfiguration(.init(pointSize: 12, weight: .light)
                                                            .applying(.init(hierarchicalColor: .systemPink)))
                        }
                    }
            }
        }
        
        required init?(coder: NSCoder) { nil }
        required init() {
            let image = CollectionImage()
            self.image = image
            
            super.init(frame: .zero)
            layer = image
            wantsLayer = true
        }
    }
}
