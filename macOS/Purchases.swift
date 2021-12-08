import AppKit
import Combine
import Core

final class Purchases: NSWindow {
    private var subs = Set<AnyCancellable>()
    
    init() {
        super.init(contentRect: .init(x: 0, y: 0, width: 520, height: 780),
                   styleMask: [.closable, .titled, .fullSizeContentView], backing: .buffered, defer: true)
        animationBehavior = .alertPanel
        toolbar = .init()
        isReleasedWhenClosed = false
        titlebarAppearsTransparent = true
        center()
        
        let content = NSVisualEffectView()
        content.state = .active
        content.material = .menu
        contentView = content
        
        let image = Image(named: "Support")
        image.imageScaling = .scaleNone
        content.addSubview(image)
        
        let title = Text(vibrancy: true)
        title.stringValue = "Support"
        title.font = NSFont.systemFont(ofSize: NSFont.preferredFont(forTextStyle: .title1).pointSize, weight: .regular)
        title.textColor = .labelColor
        content.addSubview(title)
        
        var inner: NSView?
        
        store
            .status
            .sink { status in
                inner?.removeFromSuperview()

                if Defaults.isPremium {
                    inner = Purchased()
                } else {
                    switch status {
                    case .loading:
                        inner = NSView()
                        
                        let image = Image(icon: "hourglass")
                        image.symbolConfiguration = .init(textStyle: .largeTitle)
                            .applying(.init(hierarchicalColor: .systemCyan))
                        inner!.addSubview(image)
                        
                        image.centerXAnchor.constraint(equalTo: inner!.centerXAnchor).isActive = true
                        image.centerYAnchor.constraint(equalTo: inner!.centerYAnchor).isActive = true
                        
                    case let .error(error):
                        inner = NSView()
                        
                        let text = Text(vibrancy: true)
                        text.font = .preferredFont(forTextStyle: .title3)
                        text.alignment = .center
                        text.textColor = .secondaryLabelColor
                        text.stringValue = error
                        text.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
                        inner!.addSubview(text)
                        
                        text.centerXAnchor.constraint(equalTo: inner!.centerXAnchor).isActive = true
                        text.centerYAnchor.constraint(equalTo: inner!.centerYAnchor).isActive = true
                        text.widthAnchor.constraint(equalToConstant: 300).isActive = true
                        
                    case let .products(products):
                        inner = Item(product: products.first!)
                    }
                }
                
                inner!.translatesAutoresizingMaskIntoConstraints = false
                content.addSubview(inner!)
                inner!.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 10).isActive = true
                inner!.leftAnchor.constraint(equalTo: content.leftAnchor).isActive = true
                inner!.rightAnchor.constraint(equalTo: content.rightAnchor).isActive = true
                inner!.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -30).isActive = true
            }
            .store(in: &subs)
        
        image.topAnchor.constraint(equalTo: content.topAnchor, constant: 100).isActive = true
        image.centerXAnchor.constraint(equalTo: content.centerXAnchor).isActive = true
        
        title.topAnchor.constraint(equalTo: image.bottomAnchor, constant: 80).isActive = true
        title.centerXAnchor.constraint(equalTo: content.centerXAnchor, constant: -22).isActive = true
        
        Task {
            await store.load()
        }
    }
}
