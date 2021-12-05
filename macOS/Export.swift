import AppKit
import Combine
import UserNotifications
import Core

final class Export: NSPanel {
    private var monitor: Any?
    private var subs = Set<AnyCancellable>()
    
    override var canBecomeKey: Bool {
        true
    }
    
    init(items: [Core.Picture]) {
        super.init(contentRect: .init(origin: .zero, size: .init(width: 400, height: 500)),
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
        blur.material = .menu
        blur.state = .active
        blur.wantsLayer = true
        blur.layer!.cornerRadius = 20
        contentView!.addSubview(blur)
        
        let title = Text(vibrancy: true)
        title.stringValue = "Edit"
        title.font = .preferredFont(forTextStyle: .title3)
        title.textColor = .tertiaryLabelColor
        blur.addSubview(title)
        
        let save = Action(title: "Save", color: .systemBlue)
        blur.addSubview(save)
        save
            .click
            .sink { [weak self] in
//                self?.save()
            }
            .store(in: &subs)
        
        let cancel = Plain(title: "Cancel")
        cancel
            .click
            .sink { [weak self] in
                self?.close()
            }
            .store(in: &subs)
        blur.addSubview(cancel)
        
        blur.topAnchor.constraint(equalTo: contentView!.topAnchor).isActive = true
        blur.bottomAnchor.constraint(equalTo: contentView!.bottomAnchor).isActive = true
        blur.leftAnchor.constraint(equalTo: contentView!.leftAnchor).isActive = true
        blur.rightAnchor.constraint(equalTo: contentView!.rightAnchor).isActive = true
        
        title.centerYAnchor.constraint(equalTo: blur.topAnchor, constant: 26).isActive = true
        title.leftAnchor.constraint(equalTo: blur.leftAnchor, constant: 20).isActive = true
        
        save.rightAnchor.constraint(equalTo: blur.rightAnchor, constant: -13).isActive = true
        save.centerYAnchor.constraint(equalTo: blur.topAnchor, constant: 26).isActive = true
        
        cancel.rightAnchor.constraint(equalTo: save.leftAnchor, constant: -10).isActive = true
        cancel.centerYAnchor.constraint(equalTo: blur.topAnchor, constant: 26).isActive = true
        
        monitor = NSEvent
            .addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]) { [weak self] event in
                if self?.isVisible == true && event.window != self {
                    self?.close()
                }
                return event
            }
    }
    
    override func keyDown(with: NSEvent) {
        switch with.keyCode {
        case 36:
            break
//            save()
        default:
            super.keyDown(with: with)
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
    
    override func mouseDown(with: NSEvent) {
        super.mouseDown(with: with)
        if with.clickCount == 1 {
            makeFirstResponder(nil)
        }
    }
}
