import AppKit
import Combine

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
                guard let self = self else { return }
                let browse = NSOpenPanel()
                browse.canChooseFiles = false
                browse.canChooseDirectories = true
                browse.prompt = "Open folder"
                browse.beginSheetModal(for: self) { [weak self] in
                    guard
                        $0 == .OK,
                        let url = browse.url
                    else { return }
                    self?.open(url: url)
                }
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
        content.addSubview(scroll)
        
        let stack = NSStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.orientation = .vertical
        flip.addSubview(stack)
        
        open.centerXAnchor.constraint(equalTo: content.centerXAnchor).isActive = true
        open.topAnchor.constraint(equalTo: content.safeAreaLayoutGuide.topAnchor, constant: 10).isActive = true
        
        title.leftAnchor.constraint(equalTo: content.leftAnchor, constant: 30).isActive = true
        title.bottomAnchor.constraint(equalTo: separator.topAnchor, constant: -10).isActive = true
        
        separator.centerYAnchor.constraint(equalTo: content.centerYAnchor).isActive = true
        separator.leftAnchor.constraint(equalTo: content.leftAnchor, constant: 1).isActive = true
        separator.rightAnchor.constraint(equalTo: content.rightAnchor, constant: -1).isActive = true
        
        scroll.topAnchor.constraint(equalTo: separator.bottomAnchor).isActive = true
        scroll.leftAnchor.constraint(equalTo: content.leftAnchor).isActive = true
        scroll.rightAnchor.constraint(equalTo: content.rightAnchor, constant: -1).isActive = true
        scroll.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -1).isActive = true
        
        flip.topAnchor.constraint(equalTo: scroll.topAnchor).isActive = true
        flip.leftAnchor.constraint(equalTo: scroll.leftAnchor).isActive = true
        flip.rightAnchor.constraint(equalTo: scroll.rightAnchor).isActive = true
        flip.bottomAnchor.constraint(equalTo: stack.bottomAnchor, constant: 30).isActive = true
        
        stack.topAnchor.constraint(equalTo: flip.topAnchor, constant: 20).isActive = true
        stack.leftAnchor.constraint(equalTo: flip.leftAnchor, constant: 30).isActive = true
        stack.rightAnchor.constraint(equalTo: flip.rightAnchor, constant: -30).isActive = true
        
        cloud
            .map(\.bookmarks)
            .removeDuplicates()
            .sink {
                stack
                    .setViews(
                        $0
                            .map {
                                let text = Text(vibrancy: true)
                                text.stringValue = $0.id
                                return text
                            }, in: .top)
            }
            .store(in: &subs)
    }
    
    private func open(url: URL) {
        Task {
            guard
                let open = try? await cloud.bookmark(url: url)
            else {
                Invalid().makeKeyAndOrderFront(nil)
                return
            }
            
            close()
            
            Window(bookmark: open.bookmark, url: open.url).makeKeyAndOrderFront(nil)
        }
    }
}
