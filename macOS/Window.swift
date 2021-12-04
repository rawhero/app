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
        
        let content = NSVisualEffectView()
        content.state = .active
        content.material = .menu
        contentView = content
        
        let separator = Separator(mode: .horizontal)
        content.addSubview(separator)
        
        let top = NSTitlebarAccessoryViewController()
        top.view = Bar(url: url, count: count, sort: sort, zoom: zoom)
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
            .sink {
                content
                    .subviews
                    .filter {
                        $0 != separator
                    }
                    .forEach {
                        $0.removeFromSuperview()
                    }
                
                let view: NSView
                
                switch $0 {
                case .grid:
                    view = Grid(info: info, selected: selected, clear: clear, zoom: zoom)
                case .detail:
                    view = Detail(info: info, selected: selected, zoom: zoom)
                }
                
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
    
//    override func keyDown(with: NSEvent) {
//        print(with.keyCode)
//        switch with.keyCode {
//        case 123:
//            //left
//        case 124:
//            //right
//        case 125:
//            //down
//        case 126:
//            //up
//        default:
//            super.keyDown(with: with)
//        }
//    }
    
    /*
     func control(_ control: NSControl, textView: NSTextView, doCommandBy: Selector) -> Bool {
         switch doCommandBy {
         case #selector(cancelOperation), #selector(complete), #selector(NSSavePanel.cancel):
             autocomplete?.close()
             window?.makeFirstResponder(window?.contentView)
         case #selector(insertNewline):
             autocomplete?.close()
             Task
                 .detached(priority: .utility) { [weak self] in
                     await self?.status.searching(search: control.stringValue)
                 }
             window!.makeFirstResponder(window!.contentView)
         case #selector(moveUp):
             autocomplete?.list.move.send((date: .init(), direction: .up))
         case #selector(moveDown):
             autocomplete?.list.move.send((date: .init(), direction: .down))
         default:
             return false
         }
         return true
     }
     */
    
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
