import AppKit

extension NSApplication {
    @objc func launch() {
        let browse = NSOpenPanel()
        browse.canChooseFiles = false
        browse.canChooseDirectories = true
        browse.prompt = "Open folder"
        browse.title = "Select a folder containing photos"
        
        guard
            browse.runModal() == .OK,
            let url = browse.url
        else { return }
        
        guard
            let opened = window(id: url.absoluteString)
        else {
            Task {
                guard
                    let open = try? await cloud.bookmark(url: url)
                else {
                    Invalid().makeKeyAndOrderFront(nil)
                    return
                }
                
                Window(bookmark: open.bookmark, url: open.url).makeKeyAndOrderFront(nil)
            }
            return
        }
        opened.makeKeyAndOrderFront(nil)
        opened.center()
    }
    
    @objc func showLaunch() {
        (NSApp.anyWindow() ?? Launch())
            .makeKeyAndOrderFront(nil)
    }
    
    @objc func showPurchases(_ sender: Any?) {
//        (anyWindow() ?? Preferences())
//            .makeKeyAndOrderFront(nil)
    }
    
    func window(id: String) -> Window? {
        windows
            .compactMap {
                $0 as? Window
            }
            .first {
                $0.bookmark.id == id
            }
    }
    
    func anyWindow<T>() -> T? {
        windows
            .compactMap {
                $0 as? T
            }
            .first
    }
}
