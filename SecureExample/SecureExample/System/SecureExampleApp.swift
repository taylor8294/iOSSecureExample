//
//  SecureExampleApp.swift
//  SecureExample
//
//  Created by Alex T on 29/12/2022.
//

import SwiftUI

@main
struct SecureExampleApp: App {
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    @StateObject var notificationCenterDelegate = NotificationCenterDelegate()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
