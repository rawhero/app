import AppKit
import Combine

extension Window.Detail {
    final class Cell: CollectionCell<Window.Info> {
        private weak var image: CollectionImage!
        private var sub: AnyCancellable?
        
        override var item: CollectionItem<Window.Info>? {
            didSet {
                guard
                    item != oldValue,
                    let item = item
                else { return }
                
                if item.rect != oldValue?.rect {
                    frame = item.rect
                    image.frame.size = item.rect.size
                }
                
                if item.info != oldValue?.info {
                    sub?.cancel()
                    image.contents = NSImage(systemSymbolName: "photo.circle.fill", accessibilityDescription: nil)?
                        .withSymbolConfiguration(.init(pointSize: 15, weight: .light)
                                                    .applying(.init(hierarchicalColor: .quaternaryLabelColor)))
                    image.contentsGravity = .center
                    sub = item
                        .info
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
        }
        
        required init?(coder: NSCoder) { nil }
        override init(layer: Any) { super.init(layer: layer) }
        required init() {
            let image = CollectionImage()
            self.image = image
            
            super.init()
            addSublayer(image)
        }
    }
}
