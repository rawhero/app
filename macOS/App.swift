import AppKit
import StoreKit
import UserNotifications
import Combine
import Core

@NSApplicationMain final class App: NSApplication, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    private var subs = Set<AnyCancellable>()
    
    required init?(coder: NSCoder) { nil }
    override init() {
        super.init()
        cloud.load()
        delegate = self
    }
    
    func applicationWillFinishLaunching(_: Notification) {
//        mainMenu = Menu()
        
        cloud
            .dropFirst()
            .first()
            .sink { [weak self] _ in
                self?.launch()
            }
            .store(in: &subs)
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
