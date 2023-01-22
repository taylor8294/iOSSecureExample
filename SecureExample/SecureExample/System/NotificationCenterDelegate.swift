import SwiftUI

class NotificationCenterDelegate: NSObject, ObservableObject {
    var notification: UNNotificationResponse?
    override init() {
       super.init()
       UNUserNotificationCenter.current().delegate = self
    }
}

extension NotificationCenterDelegate: UNUserNotificationCenterDelegate  {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.badge, .banner, .list, .sound])
    }
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        notification = response
        completionHandler()
    }
    func userNotificationCenter(_ center: UNUserNotificationCenter, openSettingsFor notification: UNNotification?) {
        // Handle opening of settings view
    }
}
