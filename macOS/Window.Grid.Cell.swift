import AppKit
import Combine

extension Window.Grid {
    final class Cell: CollectionCell<Window.Info> {
        static let width = CGFloat(120)
        static let spacing = CGFloat(4)
        static let width_spacing = width + spacing
        private(set) weak var image: CollectionImage!
        private(set) weak var margin: Shape!
        private(set) weak var gradient: Gradient!
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
                    gradient.frame.size = item.rect.size
                    
                    margin.path = {
                        $0.move(to: .zero)
                        $0.addLine(to: .init(x: item.rect.size.width, y: 0))
                        $0.addLine(to: .init(x: item.rect.size.width, y: item.rect.size.height))
                        $0.addLine(to: .init(x: 0, y: item.rect.size.height))
                        $0.closeSubpath()
                        return $0
                    } (CGMutablePath())
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
                                self?.image.contentsGravity = .resizeAspect
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
            
            let gradient = Gradient()
            gradient.startPoint = .init(x: 0.5, y: 0)
            gradient.endPoint = .init(x: 0.5, y: 1)
            gradient.locations = [0, 1]
            gradient.colors = [NSColor.controlAccentColor.cgColor, NSColor.labelColor.cgColor]
            self.gradient = gradient
            
            let margin = Shape()
            margin.fillColor = .clear
            margin.lineWidth = 3
            self.margin = margin
            
            super.init()
            backgroundColor = NSColor.labelColor.withAlphaComponent(0.05).cgColor
            addSublayer(image)
            addSublayer(gradient)
            addSublayer(margin)
        }
        
        override func update() {
            switch state {
            case .highlighted, .pressed:
                margin.strokeColor = NSColor.controlAccentColor.cgColor
                gradient.opacity = 0.25
            default:
                margin.strokeColor = .clear
                gradient.opacity = 0
            }
        }
    }
}
