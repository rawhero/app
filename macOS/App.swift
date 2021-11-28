import AppKit
import StoreKit
import UserNotifications
import Core

@NSApplicationMain final class App: NSApplication, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    required init?(coder: NSCoder) { nil }
    override init() {
        super.init()
        cloud.load()
        delegate = self
    }
    
    func applicationWillFinishLaunching(_: Notification) {
//        mainMenu = Menu()
        
        
    }
    
    func applicationDidFinishLaunching(_: Notification) {
//        switch Defaults.action {
//        case .rate:
//            SKStoreReviewController.requestReview()
//        case .froob:
//            (NSApp.anyWindow() ?? Froob())
//                .makeKeyAndOrderFront(nil)
//        case .none:
//            break
//        }

        registerForRemoteNotifications()
//        UNUserNotificationCenter.current().delegate = self
        
//        Task {
//            _ = await UNUserNotificationCenter.request()
//        }
        
        Task
            .detached(priority: .utility) {
                do {
                    let current = try await cloud.current
                    await Window(bookmark: current.bookmark, url: current.url).makeKeyAndOrderFront(nil)
                } catch {
                    await NSApp.showLaunch()
                }
            }
    }
    
    func applicationDidBecomeActive(_: Notification) {
        cloud.pull.send()
    }
    
    func application(_: NSApplication, didReceiveRemoteNotification: [String : Any]) {
        cloud.pull.send()
    }
    
//    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
//        await center.present(notification)
//    }
    
    @objc override func orderFrontStandardAboutPanel(_ sender: Any?) {
//        (anyWindow() ?? About())
//            .makeKeyAndOrderFront(nil)
    }
}
