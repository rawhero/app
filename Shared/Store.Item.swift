import Foundation
import UserNotifications
import Core

extension Store {
    enum Item: String, CaseIterable {
        case
        support = "rawhero.support"
        
        func purchased(active: Bool) async {
            if active {
                Defaults.isPremium = true
                await UNUserNotificationCenter.send(message: "Support purchase successful!")
            } else {
                Defaults.isPremium = false
            }
        }
    }
}
