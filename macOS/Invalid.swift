import AppKit

final class Invalid: NSPanel {
    private var monitor: Any?

    init() {
        super.init(contentRect: .init(origin: .zero, size: .init(width: 300, height: 200)),
                   styleMask: [.borderless],
                   backing: .buffered,
                   defer: true)
        isOpaque = false
        isMovableByWindowBackground = true
        backgroundColor = .clear
        hasShadow = true
        animationBehavior = .alertPanel
        center()
        
        let blur = NSVisualEffectView()
        blur.translatesAutoresizingMaskIntoConstraints = false
        blur.material = .hudWindow
        blur.state = .active
        blur.wantsLayer = true
        blur.layer!.cornerRadius = 20
        contentView!.addSubview(blur)
        
        let error = Text(vibrancy: true)
        error.stringValue = "Unable to open folder."
        error.font = .preferredFont(forTextStyle: .title3)
        error.textColor = .secondaryLabelColor
        blur.addSubview(error)
        
        blur.topAnchor.constraint(equalTo: contentView!.topAnchor).isActive = true
        blur.bottomAnchor.constraint(equalTo: contentView!.bottomAnchor).isActive = true
        blur.leftAnchor.constraint(equalTo: contentView!.leftAnchor).isActive = true
        blur.rightAnchor.constraint(equalTo: contentView!.rightAnchor).isActive = true
        
        error.centerYAnchor.constraint(equalTo: blur.centerYAnchor).isActive = true
        error.centerXAnchor.constraint(equalTo: blur.centerXAnchor).isActive = true
        
        monitor = NSEvent
            .addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]) { [weak self] event in
                if self?.isVisible == true && event.window != self {
                    self?.close()
                }
                return event
            }
    }
    
    override func close() {
        monitor
            .map(NSEvent.removeMonitor)
        monitor = nil
        parent?.removeChildWindow(self)
        super.close()
    }
    
    override func cancelOperation(_: Any?) {
        close()
    }
    
    override var canBecomeKey: Bool {
        true
    }
}
