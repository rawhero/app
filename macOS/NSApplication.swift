import AppKit

extension NSApplication {
    @objc func showLaunch() {
        (NSApp.anyWindow() ?? Launch())
            .makeKeyAndOrderFront(nil)
    }
    
    @objc func showPreferencesWindow(_ sender: Any?) {
//        (anyWindow() ?? Preferences())
//            .makeKeyAndOrderFront(nil)
    }
    
    func anyWindow<T>() -> T? {
        windows
            .compactMap {
                $0 as? T
            }
            .first
    }
}
