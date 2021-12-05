import AppKit
import Combine
import Core

final class Window: NSWindow, NSWindowDelegate {
    private weak var present: NSView?
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
        minSize = .init(width: 400, height: 400)
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
        let info = CurrentValueSubject<[Info], Never>([])
        let count = CurrentValueSubject<Int, Never>(0)
        let thumbnails = Camera(strategy: .thumbnail)
        let hd = Camera(strategy: .hd)
        let zoom = CurrentValueSubject<Zoom, Never>(.grid)
        let animateOut = PassthroughSubject<Void, Never>()
        
        let content = NSVisualEffectView()
        content.state = .active
        content.material = .menu
        contentView = content
        
        let separator = Separator(mode: .horizontal)
        content.addSubview(separator)
        
        let top = NSTitlebarAccessoryViewController()
        top.view = Bar(url: url, count: count, selected: selected, sort: sort, zoom: zoom)
        top.layoutAttribute = .top
        addTitlebarAccessoryViewController(top)
        
        let bottom = NSTitlebarAccessoryViewController()
        bottom.view = Subbar(selected: selected, zoom: zoom, clear: clear)
        bottom.layoutAttribute = .bottom
        bottom.view.frame.size.height = 50
        addTitlebarAccessoryViewController(bottom)
        
        separator.topAnchor.constraint(equalTo: content.safeAreaLayoutGuide.topAnchor).isActive = true
        separator.leftAnchor.constraint(equalTo: content.leftAnchor).isActive = true
        separator.rightAnchor.constraint(equalTo: content.rightAnchor).isActive = true
        
        sorted
            .sink { pictures in
                Task {
                    var items = [Info]()
                    for picture in pictures {
                        await items.append(.init(
                            picture: picture,
                            thumbnail: thumbnails.publisher(for: picture),
                            hd: hd.publisher(for: picture)))
                    }
                    info.send(items)
                }
            }
            .store(in: &subs)
        
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
        
        zoom
            .removeDuplicates()
            .sink { [weak self] new in
                let view: NSView
                
                switch new {
                case .grid:
                    view = Grid(info: info, selected: selected, clear: clear, zoom: zoom, animateOut: animateOut)
                    self?.present?.removeFromSuperview()
                case .detail:
                    view = Detail(info: info, selected: selected, zoom: zoom)
                    
                    if self?.present != nil {
                        view.isHidden = true
                        animateOut.send()
                    }
                }
                
                self?.present = view
                content.addSubview(view)
                
                view.topAnchor.constraint(equalTo: separator.bottomAnchor).isActive = true
                view.bottomAnchor.constraint(equalTo: content.safeAreaLayoutGuide.bottomAnchor).isActive = true
                view.leftAnchor.constraint(equalTo: content.leftAnchor).isActive = true
                view.rightAnchor.constraint(equalTo: content.rightAnchor).isActive = true
            }
            .store(in: &subs)
        
        Task
            .detached(priority: .utility) {
                let photos = FileManager.default.pictures(at: url)
                pictures.send(photos)
                count.send(photos.count)
            }
    }
    
    func animatedOut() {
        present?.isHidden = false
    }
    
    override func keyDown(with: NSEvent) {
        switch present {
        case let detail as Detail:
            switch with.keyCode {
            case 123:
                detail.controller.navigateBack(nil)
            case 124:
                detail.controller.navigateForward(nil)
            default:
                super.keyDown(with: with)
            }
        default:
            super.keyDown(with: with)
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
