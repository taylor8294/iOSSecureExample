//
//  LocalNotification.swift
//  SecureExample
//
//  Created by Alex T on 30/12/2022.
//

import SwiftUI

class LocalNotification: ObservableObject {
    init() {
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { (allowed, error) in
            //This callback does not trigger on main loop be careful
            if allowed {
                NSLog("Allowed")
            } else {
                NSLog("Error")
            }
        }
    }
    
    func setLocalNotification(title: String, subtitle: String, body: String, when: Double) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.subtitle = subtitle
        content.body = body
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: when, repeats: false)
        let request = UNNotificationRequest.init(identifier: "localNotificatoin", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        
    }
}
