import AppKit
import Combine

final class Launch: NSWindow {
    private var subs = Set<AnyCancellable>()
    
    init() {
        super.init(contentRect: .init(x: 0,
                                      y: 0,
                                      width: 600,
                                      height: 400),
                   styleMask: [.closable, .titled, .fullSizeContentView],
                   backing: .buffered,
                   defer: false)
        toolbar = .init()
        isReleasedWhenClosed = false
        center()
        titlebarAppearsTransparent = true
        
        let content = NSVisualEffectView()
        content.state = .active
        content.material = .hudWindow
        contentView = content
        
        let button = NSButton(title: "hello", target: nil, action: nil)
//        button.bezelStyle
        content.addSubview(button)
    }
}
