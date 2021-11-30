import AppKit
import Combine

extension Window {
    final class Cell: CollectionCell<Info> {
        static let height = CGFloat(108)
        static let spacing = CGFloat(4)
        static let margin2 = margin + margin
        static let height_spacing = height + spacing
        static let height_margin = height - margin2
        private static let margin = CGFloat(4)
        private static let margin_2 = margin / 2
        private weak var image: CollectionImage!
        private weak var margin: Shape!
        private var sub: AnyCancellable?
        
        override var item: CollectionItem<Info>? {
            didSet {
                guard
                    item != oldValue,
                    let item = item
                else { return }
                
                if item.rect != oldValue?.rect {
                    frame = item.rect
                    image.frame.size = .init(width: item.rect.width - Self.margin2, height: item.rect.height - Self.margin2)
                    
                    margin.path = {
                        $0.move(to: .init(x: Self.margin_2, y: Self.margin_2))
                        $0.addLine(to: .init(x: item.rect.size.width - Self.margin_2, y: Self.margin_2))
                        $0.addLine(to: .init(x: item.rect.size.width - Self.margin_2, y: item.rect.size.height - Self.margin_2))
                        $0.addLine(to: .init(x: Self.margin_2, y: item.rect.size.height - Self.margin_2))
                        $0.closeSubpath()
                        return $0
                    } (CGMutablePath())
                }
                
                if item.info != oldValue?.info {
                    sub?.cancel()
                    image.contents = NSImage(systemSymbolName: "photo.circle.fill", accessibilityDescription: nil)?
                        .withSymbolConfiguration(.init(pointSize: 25, weight: .light)
                                                    .applying(.init(hierarchicalColor: .tertiaryLabelColor)))
                    image.contentsGravity = .center
                    sub = item
                        .info
                        .publisher
                        .sink { [weak self] in
                            switch $0 {
                            case let .image(image):
                                self?.image.contents = image
                                self?.image.contentsGravity = .resizeAspect
                            case .error:
                                self?.image.contents = NSImage(systemSymbolName: "exclamationmark.triangle.fill", accessibilityDescription: nil)?
                                    .withSymbolConfiguration(.init(pointSize: 15, weight: .light)
                                                                .applying(.init(hierarchicalColor: .systemPink)))
                                self?.image.contentsGravity = .bottomRight
                            }
                        }
                }
            }
        }
        
        required init?(coder: NSCoder) { nil }
        override init(layer: Any) { super.init(layer: layer) }
        required init() {
            let image = CollectionImage()
            image.frame = .init(
                x: Self.margin,
                y: Self.margin,
                width: 0,
                height: 0)
            
            self.image = image
            
            let margin = Shape()
            margin.fillColor = .clear
            margin.lineWidth = Self.margin_2
            self.margin = margin
            
            super.init()
            addSublayer(margin)
            addSublayer(image)
        }
        
        override func update() {
            switch state {
            case .highlighted, .pressed:
                margin.strokeColor = NSColor.tertiaryLabelColor.cgColor
            default:
                margin.strokeColor = .clear
            }
        }
    }
}
