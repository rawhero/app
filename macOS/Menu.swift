import AppKit
import StoreKit
import Core

final class Menu: NSMenu, NSMenuDelegate {
    required init(coder: NSCoder) { super.init(coder: coder) }
    init() {
        super.init(title: "")
        items = [app, file, edit, view, window, help]
    }
    
    func menuNeedsUpdate(_ menu: NSMenu) {
        switch menu.title {
        case "File":
            menu.items = fileItems
        case "Window":
            menu.items = windowItems
        default:
            break
        }
    }
    
    private var app: NSMenuItem {
        .parent("Raw", [
            .child("About", #selector(NSApplication.orderFrontStandardAboutPanel(_:))),
            .separator(),
            .child("In-App Purchases", #selector(NSApp.showPurchases)),
            .separator(),
            .child("Hide", #selector(NSApplication.hide), "h"),
            .child("Hide Others", #selector(NSApplication.hideOtherApplications), "h") {
                $0.keyEquivalentModifierMask = [.option, .command]
            },
            .child("Show all", #selector(NSApplication.unhideAllApplications)),
            .separator(),
            .child("Quit", #selector(NSApplication.terminate), "q")])
    }
    
    private var file: NSMenuItem {
        .parent("File", fileItems) {
            $0.submenu!.autoenablesItems = false
            $0.submenu!.delegate = self
        }
    }
    
    private var fileItems: [NSMenuItem] {
        [
            .child("Open Folder", #selector(NSApp.launch), "n"),
            .separator(),
            .child("Open...", #selector(NSApp.showLaunch), "N"),
            .separator(),
            .child("Delete selected", #selector(Window.deleteSelected), .init(Unicode.Scalar(NSBackspaceCharacter)!)) {
                $0.keyEquivalentModifierMask = []
                $0.isEnabled = (NSApp.keyWindow as? Window)?.selected.value.isEmpty == false
            }]
    }
    
    private var edit: NSMenuItem {
        .parent("Edit", [
            .child("Undo", Selector(("undo:")), "z"),
            .child("Redo", Selector(("redo:")), "Z"),
            .separator(),
            .child("Cut", #selector(NSText.cut), "x"),
            .child("Copy", #selector(NSText.copy(_:)), "c"),
            .child("Paste", #selector(NSText.paste), "v"),
            .child("Delete", #selector(NSText.delete)),
            .child("Select All", #selector(NSText.selectAll), "a")])
    }
    
    private var view: NSMenuItem {
        .parent("View", [
            .child("Full Screen", #selector(Window.toggleFullScreen), "f") {
                $0.keyEquivalentModifierMask = [.function]
            }])
    }
    
    private var window: NSMenuItem {
        .parent("Window", windowItems) {
            $0.submenu!.delegate = self
        }
    }
    
    private var windowItems: [NSMenuItem] {
        var items: [NSMenuItem] = [
            .child("Minimize", #selector(NSWindow.miniaturize), "m"),
            .child("Zoom", #selector(NSWindow.zoom)),
            .separator(),
            .child("Close", #selector(NSWindow.close), "w"),
            .separator(),
            .child("Bring All to Front", #selector(NSApplication.arrangeInFront)),
            .separator()]

        items += NSApp
            .windows
            .compactMap { item in
                
                var title = ""
                var add: NSWindow? = item
                
                switch item {
                case let window as Window:
                    title = "Raw: " + window.url.lastPathComponent
                case is Purchases:
                    title = "In-App Purchases"
                case is About:
                    title = "About"
                case is Info.Policy:
                    title = "Privacy policy"
                default:
                    add = nil
                }
                
                return add
                    .map {
                        .child(title, #selector($0.makeKeyAndOrderFront)) {
                            $0.target = item
                            $0.state = NSApp.mainWindow == item ? .on : .off
                        }
                    }
            }
        
        return items
    }
    
    private var help: NSMenuItem {
        .parent("Help", [
            .child("Privacy policy", #selector(triggerPolicy)) {
                $0.target = self
            },
            .separator(),
            .child("Rate on the App Store", #selector(triggerRate)) {
                $0.target = self
            },
            .child("Visit website", #selector(triggerWebsite)) {
                $0.target = self
            }])
    }
    
    @objc private func triggerRate() {
        SKStoreReviewController.requestReview()
        Defaults.hasRated = true
    }
    
    @objc private func triggerWebsite() {
        NSWorkspace.shared.open(URL(string: "https://rawhero.github.io/about")!)
    }
    
    @objc private func triggerPolicy() {
        (NSApp.anyWindow() ?? Info.Policy())
            .makeKeyAndOrderFront(nil)
    }
}
