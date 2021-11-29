import AppKit
import StoreKit
import UserNotifications
import Core

@NSApplicationMain final class App: NSApplication, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    required init?(coder: NSCoder) { nil }
    override init() {
        super.init()
        delegate = self
    }
    
    func applicationWillFinishLaunching(_: Notification) {
//        mainMenu = Menu()
        
        cloud
            .ready
            .notify(queue: .main) { [weak self] in
                self?.launch()
            }
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
    
    private func launch() {
        Task {
            do {
                let current = try await cloud.current
                await MainActor
                    .run {
                        Window(bookmark: current.bookmark, url: current.url).makeKeyAndOrderFront(nil)
                    }
            } catch {
                await MainActor
                    .run {
                        showLaunch()
                    }
            }
        }
    }
}
