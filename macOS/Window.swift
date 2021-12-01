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
        minSize = .init(width: 300, height: 400)
        toolbar = .init()
        animationBehavior = .documentWindow
        isReleasedWhenClosed = false
        center()
//        setFrameAutosaveName("Window")
        titlebarAppearsTransparent = true
        delegate = self
        
        let pictures = PassthroughSubject<Set<Core.Picture>, Never>()
        let sorted = PassthroughSubject<[Core.Picture], Never>()
        let clear = PassthroughSubject<Void, Never>()
        let sort = CurrentValueSubject<Sort, Never>(.name)
        let selected = CurrentValueSubject<[Core.Picture], Never>([])
        
        let content = NSVisualEffectView()
        content.state = .active
        content.material = .menu
        contentView = content
        
        let separator = Separator(mode: .horizontal)
        content.addSubview(separator)
        
        let middle = NSVisualEffectView()
        middle.translatesAutoresizingMaskIntoConstraints = false
        middle.state = .active
        middle.material = .sheet
        content.addSubview(middle)
        
        let list = List(pictures: sorted, selected: selected, clear: clear)
        middle.addSubview(list)
        
        separator.topAnchor.constraint(equalTo: content.safeAreaLayoutGuide.topAnchor).isActive = true
        separator.leftAnchor.constraint(equalTo: content.leftAnchor).isActive = true
        separator.rightAnchor.constraint(equalTo: content.rightAnchor).isActive = true
        
        middle.topAnchor.constraint(equalTo: separator.bottomAnchor).isActive = true
        middle.bottomAnchor.constraint(equalTo: content.safeAreaLayoutGuide.bottomAnchor).isActive = true
        middle.leftAnchor.constraint(equalTo: content.leftAnchor).isActive = true
        middle.rightAnchor.constraint(equalTo: content.rightAnchor).isActive = true
        
        let count = CurrentValueSubject<Int, Never>(0)
        
        let top = NSTitlebarAccessoryViewController()
        top.view = Bar(url: url, count: count, sort: sort)
        top.layoutAttribute = .top
        addTitlebarAccessoryViewController(top)
        
        let bottom = NSTitlebarAccessoryViewController()
        bottom.view = Subbar(selected: selected, clear: clear)
        bottom.layoutAttribute = .bottom
        bottom.view.frame.size.height = 50
        addTitlebarAccessoryViewController(bottom)
        
        list.topAnchor.constraint(equalTo: middle.topAnchor).isActive = true
        list.bottomAnchor.constraint(equalTo: middle.bottomAnchor).isActive = true
        list.leftAnchor.constraint(equalTo: middle.leftAnchor).isActive = true
        list.rightAnchor.constraint(equalTo: middle.rightAnchor).isActive = true
        
        pictures
            .combineLatest(sort)
            .map { pictures, sort in
                switch sort {
                case .name:
                    return pictures
                        .sorted { a, b in
                            a.id.absoluteString.localizedCaseInsensitiveCompare(b.id.absoluteString) == .orderedAscending
                        }
                case .resolution:
                    return pictures
                        .sorted { a, b in
                            a.size > b.size
                        }
                case .size:
                    return pictures
                        .sorted { a, b in
                            a.bytes > b.bytes
                        }
                }
            }
            .subscribe(sorted)
            .store(in: &subs)
        
        clear
            .sink {
                selected.value = []
            }
            .store(in: &subs)
        
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
