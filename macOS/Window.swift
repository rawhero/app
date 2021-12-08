import AppKit
import Combine
import UserNotifications
import Core

final class Window: NSWindow, NSWindowDelegate {
    let url: URL
    let bookmark: Bookmark
    private weak var present: NSView?
    private var subs = Set<AnyCancellable>()
    
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
        setFrameAutosaveName("Window")
        titlebarAppearsTransparent = true
        delegate = self
        
        let pictures = CurrentValueSubject<Set<Core.Picture>, Never>([])
        let sorted = PassthroughSubject<[Core.Picture], Never>()
        let sort = CurrentValueSubject<Sort, Never>(.name)
        let selected = CurrentValueSubject<[Core.Picture], Never>([])
        let info = CurrentValueSubject<[Info], Never>([])
        let thumbnails = Camera(strategy: .thumbnail)
        let hd = Camera(strategy: .hd)
        let zoom = CurrentValueSubject<Zoom, Never>(.grid)
        let animateOut = PassthroughSubject<Void, Never>()
        let move = PassthroughSubject<(date: Date, direction: Direction, multiple: Bool), Never>()
        let trash = PassthroughSubject<[Core.Picture], Never>()
        let share = PassthroughSubject<[Core.Picture], Never>()
        let reload = PassthroughSubject<Void, Never>()
        
        let content = NSVisualEffectView()
        content.state = .active
        content.material = .menu
        contentView = content
        
        let separator = Separator(mode: .horizontal)
        content.addSubview(separator)
        
        let top = NSTitlebarAccessoryViewController()
        top.view = Bar(
            url: url,
            info: info,
            selected: selected,
            sort: sort,
            zoom: zoom,
            trash: trash,
            share: share,
            reload: reload)
        top.layoutAttribute = .top
        addTitlebarAccessoryViewController(top)
        
        let bottom = NSTitlebarAccessoryViewController()
        bottom.view = Subbar(selected: selected, zoom: zoom)
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
            .removeDuplicates()
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
        
        zoom
            .removeDuplicates()
            .combineLatest(info
                            .map { $0.isEmpty }
                            .removeDuplicates())
            .sink { [weak self] new, empty in
                let view: NSView
                
                if empty {
                    view = Empty()
                    self?.present?.removeFromSuperview()
                } else {
                    switch new {
                    case .grid:
                        view = Grid(
                            info: info,
                            selected: selected,
                            zoom: zoom,
                            animateOut: animateOut,
                            move: move,
                            trash: trash,
                            share: share)
                        self?.present?.removeFromSuperview()
                    case .detail:
                        view = Detail(
                            info: info,
                            selected: selected,
                            zoom: zoom,
                            trash: trash,
                            share: share)
                        
                        if self?.present != nil {
                            self?.present = view
                            view.isHidden = true
                            animateOut.send()
                        }
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
        
        trash
            .sink { items in
                let alert = NSAlert()
                alert.alertStyle = .warning
                alert.icon = .init(systemSymbolName: "trash", accessibilityDescription: nil)
                alert.messageText = items.count == 1 ? "Delete photo?" : "Delete photos?"
                alert.informativeText = items.count == 1 ? "Photo will be send to Trash" : "Photos will be send to Trash"
                
                let delete = alert.addButton(withTitle: "Delete")
                let cancel = alert.addButton(withTitle: "Cancel")
                delete.keyEquivalent = "\r"
                cancel.keyEquivalent = "\u{1b}"
                if alert.runModal().rawValue == delete.tag {
                    
                    if let current = selected.value.first,
                       zoom.value == .detail,
                       info.value.count > 1,
                       let index = info
                        .value
                        .firstIndex(where: {
                            $0.picture.id == current.id
                        }) {
                        
                        selected.send([info.value[index + (index < info.value.count - 1 ? 1 : -1)].picture])
                        
                    } else {
                        selected.send([])
                    }
                    
                    pictures.value = pictures
                        .value
                        .filter {
                            !items.contains($0)
                        }
                    
                    items
                        .forEach {
                            try? FileManager.default.trashItem(at: $0.id, resultingItemURL: nil)
                        }
                    
                    Task {
                        await UNUserNotificationCenter.send(message: items.count == 1 ? "Delete photo!" : "Deleted photos!")
                    }
                }
            }
            .store(in: &subs)
        
        share
            .sink { [weak self] in
                let export = Export(items: $0, thumbnails: thumbnails)
                self?.addChildWindow(export, ordered: .above)
                export.makeKey()
            }
            .store(in: &subs)
        
        reload
            .sink {
                selected.send([])
                pictures.send(FileManager.default.pictures(at: url))
                
                Task {
                    await UNUserNotificationCenter.send(message: "Refreshed folder!")
                }
            }
            .store(in: &subs)
        
        Task
            .detached(priority: .utility) {
                pictures.send(FileManager.default.pictures(at: url))
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
        case let grid as Grid:
            switch with.keyCode {
            case 123:
                grid.move.send((date: .now, direction: .left, multiple: with.multiple))
            case 124:
                grid.move.send((date: .now, direction: .right, multiple: with.multiple))
            case 125:
                grid.move.send((date: .now, direction: .down, multiple: with.multiple))
            case 126:
                grid.move.send((date: .now, direction: .up, multiple: with.multiple))
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
