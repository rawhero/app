import AppKit
import Combine

extension Window {
    final class Cell: CollectionCell<Info> {
        static let height = CGFloat(40)
        private weak var image: CollectionImage!
        private var sub: AnyCancellable?
        
        override var item: CollectionItem<Info>? {
            didSet {
                guard
                    item != oldValue,
                    let item = item
                else { return }
                
                if item.rect != oldValue?.rect {
                    frame = item.rect
                }
                
                if item.info != oldValue?.info {
                    sub?.cancel()
                    image.contents = nil
                    
                    sub = item
                        .info
                        .publisher
                        .sink { [weak self] in
                            self?.image.contents = $0
                        }
//                    print(self.superlayer.voew)
                    
//                    icon.contents = NSImage(systemSymbolName: "network", accessibilityDescription: nil)?
//                        .withSymbolConfiguration(.init(pointSize: 32, weight: .ultraLight)
//                                                    .applying(.init(hierarchicalColor: .tertiaryLabelColor)))
//
//                    Task
//                        .detached { [weak self] in
//                            await self?.update(icon: item.info.icon)
//                        }
                }
            }
        }
        
        required init?(coder: NSCoder) { nil }
        override init(layer: Any) { super.init(layer: layer) }
        required init() {
            super.init()
            let image = CollectionImage()
            image.frame = .init(
                x: 1,
                y: 1,
                width: 38,
                height: 38)
            addSublayer(image)
            self.image = image
        }
        
        override func update() {
            switch state {
            case .highlighted, .pressed:
                backgroundColor = NSColor.labelColor.withAlphaComponent(0.05).cgColor
            default:
                backgroundColor = .clear
            }
        }
        
//        private func update(icon: String?) async {
//            guard
//                let icon = icon,
//                let publisher = await favicon.publisher(for: icon)
//            else { return }
//            sub = publisher
//                .sink { [weak self] in
//                    self?.icon.contents = $0
//                }
//        }
    }
}
