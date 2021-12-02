import AppKit
import Combine

extension Window.Detail {
    final class Cell: NSView {
        private weak var image: CollectionImage!
        private var sub: AnyCancellable?
        
        var info: Window.Info? {
            didSet {
                guard info != oldValue else { return }
                
                if let info = info {
                    empty.isHidden = true
                    sub?.cancel()
                    image.contents = NSImage(systemSymbolName: "photo.circle.fill", accessibilityDescription: nil)?
                        .withSymbolConfiguration(.init(pointSize: 25, weight: .light)
                                                    .applying(.init(hierarchicalColor: .quaternaryLabelColor)))
                    image.contentsGravity = .center
                    sub = info
                        .thumbnail
                        .sink { [weak self] in
                            switch $0 {
                            case let .image(image):
                                self?.image.contents = image
                                self?.image.contentsGravity = .resizeAspect
                            case .error:
                                self?.image.contents = NSImage(systemSymbolName: "exclamationmark.triangle.fill", accessibilityDescription: nil)?
                                    .withSymbolConfiguration(.init(pointSize: 20, weight: .light)
                                                                .applying(.init(hierarchicalColor: .systemPink)))
                            }
                        }
                } else {
                    empty.isHidden = false
                }
            }
        }
        
        override var frame: NSRect {
            didSet {
                image.frame.size = frame.size
            }
        }
        
        private weak var empty: Text!
        
        required init?(coder: NSCoder) { nil }
        required init() {
            let image = CollectionImage()
            self.image = image
            
            let empty = Text(vibrancy: true)
            empty.stringValue = "No photos found"
            empty.textColor = .secondaryLabelColor
            empty.font = .preferredFont(forTextStyle: .body)
            self.empty = empty

            super.init(frame: .zero)
            layer = image
            wantsLayer = true
            
            addSubview(empty)
            
            empty.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
            empty.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        }
    }
}
