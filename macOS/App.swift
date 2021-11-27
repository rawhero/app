import AppKit
import StoreKit
import UserNotifications

@NSApplicationMain final class App: NSApplication, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    required init?(coder: NSCoder) { nil }
    override init() {
        super.init()
        delegate = self
    }
    
    func applicationWillFinishLaunching(_: Notification) {
//        mainMenu = Menu()
        
        Launch().makeKeyAndOrderFront(nil)
    }
    
    func applicationDidFinishLaunching(_: Notification) {
//        Task {
//            switch Defaults.action {
//            case .rate:
//                SKStoreReviewController.requestReview()
//            case .none:
//                break
//            }
//        }
//
//        registerForRemoteNotifications()
//        UNUserNotificationCenter.current().delegate = self
    }
    
//    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
//        await center.present(notification)
//    }
    
    @objc override func orderFrontStandardAboutPanel(_ sender: Any?) {
//        (anyWindow() ?? About())
//            .makeKeyAndOrderFront(nil)
    }
}
