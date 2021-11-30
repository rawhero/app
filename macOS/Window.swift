import AppKit
import Combine
import Core

final class Window: NSWindow, NSWindowDelegate {
    private var subs = Set<AnyCancellable>()
    private let url: URL
    private let bookmark: Bookmark
    
    init(bookmark: Bookmark, url: URL) {
        self.bookmark = bookmark
        self.url = url
        
        super.init(contentRect: .init(x: 0,
                                      y: 0,
                                      width: 800,
                                      height: 600),
                   styleMask: [.closable, .miniaturizable, .resizable, .titled, .fullSizeContentView],
                   backing: .buffered,
                   defer: false)
        minSize = .init(width: 600, height: 400)
        toolbar = .init()
        animationBehavior = .documentWindow
        isReleasedWhenClosed = false
        center()
//        setFrameAutosaveName("Window")
        titlebarAppearsTransparent = true
        delegate = self
        
        let pictures = PassthroughSubject<Set<Core.Picture>, Never>()
        
        let content = NSVisualEffectView()
        content.state = .active
        content.material = .menu
        contentView = content
        
        let separatorTop = Separator(mode: .horizontal)
        content.addSubview(separatorTop)
        
        let separatorBottom = Separator(mode: .horizontal)
        content.addSubview(separatorBottom)
        
        let middle = NSVisualEffectView()
        middle.translatesAutoresizingMaskIntoConstraints = false
        middle.state = .active
        middle.material = .sheet
        content.addSubview(middle)
        
        let list = List(pictures: pictures)
        middle.addSubview(list)
        
        separatorTop.topAnchor.constraint(equalTo: content.safeAreaLayoutGuide.topAnchor).isActive = true
        separatorTop.leftAnchor.constraint(equalTo: content.leftAnchor, constant: 1).isActive = true
        separatorTop.rightAnchor.constraint(equalTo: content.rightAnchor, constant: -1).isActive = true
        
        separatorBottom.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -100).isActive = true
        separatorBottom.leftAnchor.constraint(equalTo: content.leftAnchor, constant: 1).isActive = true
        separatorBottom.rightAnchor.constraint(equalTo: content.rightAnchor, constant: -1).isActive = true
        
        middle.topAnchor.constraint(equalTo: separatorTop.bottomAnchor).isActive = true
        middle.bottomAnchor.constraint(equalTo: separatorBottom.topAnchor).isActive = true
        middle.leftAnchor.constraint(equalTo: content.leftAnchor, constant: 1).isActive = true
        middle.rightAnchor.constraint(equalTo: content.rightAnchor, constant: -1).isActive = true
        
        let count = CurrentValueSubject<Int, Never>(0)
        let top = NSTitlebarAccessoryViewController()
        top.view = Bar(url: url, count: count)
        top.layoutAttribute = .top
        addTitlebarAccessoryViewController(top)
        
        list.topAnchor.constraint(equalTo: middle.topAnchor).isActive = true
        list.bottomAnchor.constraint(equalTo: middle.bottomAnchor).isActive = true
        list.leftAnchor.constraint(equalTo: middle.leftAnchor).isActive = true
        list.rightAnchor.constraint(equalTo: middle.rightAnchor).isActive = true
        
        Task
            .detached(priority: .utility) {
                let photos = FileManager.default.pictures(at: url)
                pictures.send(photos)
                count.send(photos.count)
            }
    }
    
    override func close() {
        Task {
            await cloud.close(bookmark: bookmark, url: url)
        }
        
        if NSApp
            .windows
            .filter({
                $0 is Window
            })
            .filter ({
                $0 != self
            })
            .isEmpty {
            NSApp.showLaunch()
        }
        
        super.close()
    }
    
    func windowDidEnterFullScreen(_: Notification) {
        titlebarAccessoryViewControllers
            .compactMap {
                $0.view as? NSVisualEffectView
            }
            .forEach {
                $0.material = .sheet
            }
    }

    func windowDidExitFullScreen(_: Notification) {
        titlebarAccessoryViewControllers
            .compactMap {
                $0.view as? NSVisualEffectView
            }
            .forEach {
                $0.material = .menu
            }
    }
}
