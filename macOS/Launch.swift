import AppKit
import Combine
import Core

final class Launch: NSWindow {
    private var subs = Set<AnyCancellable>()
    
    init() {
        super.init(contentRect: .init(x: 0,
                                      y: 0,
                                      width: 440,
                                      height: 320),
                   styleMask: [.closable, .titled, .fullSizeContentView],
                   backing: .buffered,
                   defer: false)
        toolbar = .init()
        isReleasedWhenClosed = false
        center()
        titlebarAppearsTransparent = true
        animationBehavior = .alertPanel
        
        let content = NSVisualEffectView()
        content.state = .active
        content.material = .hudWindow
        contentView = content
        
        let open = Action(title: "Open folder", color: .controlAccentColor)
        content.addSubview(open)
        open
            .click
            .sink { [weak self] in
                self?.close()
                NSApp.launch()
            }
            .store(in: &subs)
        
        let title = Text(vibrancy: true)
        title.stringValue = "Recent locations"
        title.font = .systemFont(ofSize: NSFont.preferredFont(forTextStyle: .title3).pointSize, weight: .regular)
        title.textColor = .tertiaryLabelColor
        content.addSubview(title)
        
        let separator = Separator(mode: .horizontal)
        content.addSubview(separator)
        
        let flip = Flip()
        flip.translatesAutoresizingMaskIntoConstraints = false
        
        let scroll = NSScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.documentView = flip
        scroll.hasVerticalScroller = true
        scroll.verticalScroller!.controlSize = .mini
        scroll.drawsBackground = false
        scroll.automaticallyAdjustsContentInsets = false
        scroll.scrollerInsets.top = 10
        scroll.scrollerInsets.bottom = 10
        content.addSubview(scroll)
        
        let stack = NSStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.orientation = .vertical
        flip.addSubview(stack)
        
        open.rightAnchor.constraint(equalTo: content.rightAnchor, constant: -12).isActive = true
        open.centerYAnchor.constraint(equalTo: content.topAnchor, constant: 26).isActive = true
        
        title.leftAnchor.constraint(equalTo: content.leftAnchor, constant: 14).isActive = true
        title.topAnchor.constraint(equalTo: content.safeAreaLayoutGuide.topAnchor, constant: 5).isActive = true
        
        separator.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 15).isActive = true
        separator.leftAnchor.constraint(equalTo: content.leftAnchor, constant: 1).isActive = true
        separator.rightAnchor.constraint(equalTo: content.rightAnchor, constant: -1).isActive = true
        
        scroll.topAnchor.constraint(equalTo: separator.bottomAnchor).isActive = true
        scroll.leftAnchor.constraint(equalTo: content.leftAnchor).isActive = true
        scroll.rightAnchor.constraint(equalTo: content.rightAnchor, constant: -1).isActive = true
        scroll.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -1).isActive = true
        
        flip.topAnchor.constraint(equalTo: scroll.topAnchor).isActive = true
        flip.leftAnchor.constraint(equalTo: scroll.leftAnchor).isActive = true
        flip.rightAnchor.constraint(equalTo: scroll.rightAnchor).isActive = true
        flip.bottomAnchor.constraint(equalTo: stack.bottomAnchor, constant: 16).isActive = true
        
        stack.topAnchor.constraint(equalTo: flip.topAnchor, constant: 10).isActive = true
        stack.leftAnchor.constraint(equalTo: flip.leftAnchor, constant: 10).isActive = true
        stack.rightAnchor.constraint(equalTo: flip.rightAnchor, constant: -10).isActive = true
        
        cloud
            .map(\.bookmarks)
            .removeDuplicates()
            .sink { [weak self] in
                guard let self = self else { return }
                stack.setViews( $0.map { self.item(bookmark: $0) }, in: .top)
            }
            .store(in: &subs)
    }
    
    private func item(bookmark: Bookmark) -> Item {
        let item = Item(bookmark: bookmark)
        item
            .click
            .sink { [weak self] in
                self?.open(bookmark: bookmark)
            }
            .store(in: &subs)
        return item
    }
    
    private func open(bookmark: Bookmark) {
        Task {
            guard let opened = NSApp.window(id: bookmark.id)
            else {
                guard
                    let url = try? await cloud.open(bookmark: bookmark)
                else {
                    Invalid().makeKeyAndOrderFront(nil)
                    return
                }
                
                close()
                
                Window(bookmark: bookmark, url: url).makeKeyAndOrderFront(nil)
                
                return
            }
            
            opened.makeKeyAndOrderFront(nil)
            opened.center()
        }
    }
}
