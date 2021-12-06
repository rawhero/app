import AppKit
import Combine
import UserNotifications
import Core

final class Export: NSPanel {
    private var monitor: Any?
    private var subs = Set<AnyCancellable>()
    private let items: [Item]
    
    override var canBecomeKey: Bool {
        true
    }
    
    init(items: [Core.Picture], thumbnails: Camera) {
        self.items = items
            .map {
                Item(picture: $0, thumbnails: thumbnails)
            }
        
        super.init(contentRect: .init(origin: .zero, size: .init(width: 480, height: 500)),
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
        title.stringValue = "Export"
        title.font = .preferredFont(forTextStyle: .title3)
        title.textColor = .secondaryLabelColor
        blur.addSubview(title)
        
        let export = Action(title: "Export", color: .systemBlue)
        blur.addSubview(export)
        export
            .click
            .sink { [weak self] in
                self?.save()
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
        
        let top = Separator(mode: .horizontal)
        blur.addSubview(top)
        
        let bottom = Separator(mode: .horizontal)
        blur.addSubview(bottom)
        
        let flip = Flip()
        flip.translatesAutoresizingMaskIntoConstraints = false
        
        let scroll = NSScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.documentView = flip
        scroll.hasVerticalScroller = true
        scroll.verticalScroller!.controlSize = .mini
        scroll.drawsBackground = false
        scroll.automaticallyAdjustsContentInsets = false
        blur.addSubview(scroll)
        
        let stack = NSStackView(views: self.items)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.orientation = .vertical
        stack.spacing = 10
        flip.addSubview(stack)
        
        blur.topAnchor.constraint(equalTo: contentView!.topAnchor).isActive = true
        blur.bottomAnchor.constraint(equalTo: contentView!.bottomAnchor).isActive = true
        blur.leftAnchor.constraint(equalTo: contentView!.leftAnchor).isActive = true
        blur.rightAnchor.constraint(equalTo: contentView!.rightAnchor).isActive = true
        
        title.topAnchor.constraint(equalTo: blur.topAnchor, constant: 20).isActive = true
        title.centerXAnchor.constraint(equalTo: blur.centerXAnchor).isActive = true
        
        export.centerXAnchor.constraint(equalTo: blur.centerXAnchor).isActive = true
        export.bottomAnchor.constraint(equalTo: cancel.topAnchor).isActive = true
        
        cancel.centerXAnchor.constraint(equalTo: blur.centerXAnchor).isActive = true
        cancel.bottomAnchor.constraint(equalTo: blur.bottomAnchor, constant: -35).isActive = true
        
        top.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 10).isActive = true
        top.leftAnchor.constraint(equalTo: blur.leftAnchor).isActive = true
        top.rightAnchor.constraint(equalTo: blur.rightAnchor).isActive = true
        
        bottom.bottomAnchor.constraint(equalTo: export.topAnchor, constant: -15).isActive = true
        bottom.leftAnchor.constraint(equalTo: blur.leftAnchor).isActive = true
        bottom.rightAnchor.constraint(equalTo: blur.rightAnchor).isActive = true
        
        scroll.topAnchor.constraint(equalTo: top.bottomAnchor).isActive = true
        scroll.leftAnchor.constraint(equalTo: blur.leftAnchor).isActive = true
        scroll.rightAnchor.constraint(equalTo: blur.rightAnchor).isActive = true
        scroll.bottomAnchor.constraint(equalTo: bottom.topAnchor).isActive = true
        
        flip.topAnchor.constraint(equalTo: scroll.topAnchor).isActive = true
        flip.leftAnchor.constraint(equalTo: scroll.leftAnchor).isActive = true
        flip.rightAnchor.constraint(equalTo: scroll.rightAnchor).isActive = true
        flip.bottomAnchor.constraint(equalTo: stack.bottomAnchor, constant: 10).isActive = true
        
        stack.topAnchor.constraint(equalTo: flip.topAnchor, constant: 10).isActive = true
        stack.leftAnchor.constraint(equalTo: flip.leftAnchor).isActive = true
        stack.rightAnchor.constraint(equalTo: flip.rightAnchor).isActive = true
        
        monitor = NSEvent
            .addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]) { [weak self] event in
                if self?.isVisible == true && event.window != self && !(event.window is NSOpenPanel) {
                    self?.close()
                }
                return event
            }
    }
    
    override func keyDown(with: NSEvent) {
        switch with.keyCode {
        case 36:
            save()
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
    
    private func save() {
        makeFirstResponder(contentView)
        
        let browse = NSOpenPanel()
        browse.canChooseFiles = false
        browse.canChooseDirectories = true
        browse.title = "Destination folder"
        browse.prompt = "Save"
        
        guard
            browse.runModal() == .OK,
            let url = browse.url
        else { return }

        var urls = [URL]()
        
        items
            .filter {
                $0.result != nil
            }
            .forEach {
                let temporal = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
                try? $0.result?.write(to: temporal, options: .atomic)
                let name = $0.url.lastPathComponent.components(separatedBy: ".").dropLast().joined(separator: ".")
                var path = url.appendingPathComponent(name + ".jpeg")
                
                if FileManager.default.fileExists(atPath: path.path) {
                    path = url.appendingPathComponent(name + " " + Date().formatted(date: .numeric, time: .standard) + ".jpeg")
                }
                
                if let result = try? FileManager.default.replaceItemAt(path, withItemAt: temporal) {
                    urls.append(result)
                }
                
                try? FileManager.default.removeItem(at: temporal)
            }
        
        NSWorkspace.shared.activateFileViewerSelecting(urls)
        close()
    }
}
