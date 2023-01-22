//
//  NotificationPermissions.swift
//  SecureExample
//
//  Created by Alex T on 30/12/2022.
//

import Foundation
import UIKit
import UserNotifications

class PushNotifications {
    
    enum Status: Equatable {
        case unknown
        case notRequested
        case granted
        case denied
    }
    
    static private(set) var lastKnownStatus: Status = .unknown
    static private(set) var lastKnownStatusDate: Date = Date.now
    static var isRegisteredForRemoteNotifications : Bool {
        UIApplication.shared.isRegisteredForRemoteNotifications
    }
    static let hasRequestedAuthorizationKey = "PushNotification.hasRequestedAuthorization"
    static var hasRequestedAuthorization : Bool {
        lastKnownStatus == .granted || Foundation.UserDefaults.standard.bool(forKey: self.hasRequestedAuthorizationKey)
    }
    
    static func requestAuthorization(registerIfGranted: Bool = true, completion: ((Status) -> Void)?) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in
            UserDefaults.standard.set(true, forKey: self.hasRequestedAuthorizationKey)
            self.authorizationStatus { status in
                if status == .granted && registerIfGranted {
                    self.registerForRemoteNotifications()
                }
                if let callback = completion {
                    callback(status)
                }
            }
        }
    }
    
    static func requestAuthorization(registerIfGranted: Bool = true, completion: @escaping (Bool) -> Void) {
        requestAuthorization(registerIfGranted: registerIfGranted){ (status: Status) in
            completion(status == .granted)
        }
    }
    
    static func authorizationStatus(completion: ((Status) -> Void)? = nil) {
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            PushNotifications.lastKnownStatus = settings.authorizationStatus.map
            PushNotifications.lastKnownStatusDate = Date.now
            if let callback = completion{
                callback(PushNotifications.lastKnownStatus)
            }
        }
    }
    
    static func registerForRemoteNotifications(force: Bool = true) {
        if force || !isRegisteredForRemoteNotifications {
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
                // Should call didRegisterForRemoteNotificationsWithDeviceToken in AppDelegate
            }
        }
    }
    
    // Should only need to call this in rare circumstances
    static func unregisterForRemoteNotifications(force: Bool = true) {
        if force || isRegisteredForRemoteNotifications {
            DispatchQueue.main.async {
                UIApplication.shared.unregisterForRemoteNotifications()
            }
        }
    }
}

extension UNAuthorizationStatus {
    var map: PushNotifications.Status {
        switch self {
        case .denied: return .denied
        case .authorized: return .granted
        case .notDetermined, .provisional, .ephemeral: return .notRequested
        @unknown default: return .notRequested
        }
    }
}
