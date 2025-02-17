//
//  ChitChatAppApp.swift
//  ChitChatApp
//
//  Created by Berkay Emre Aslan on 11.10.2024.
//


import SwiftUI
import Firebase


class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        setUpPushNotifications(for: application)
        return true
    }
    
    private func setUpPushNotifications(for application: UIApplication) {
        let notificationCenter = UNUserNotificationCenter.current()
        Messaging.messaging().delegate = self
        notificationCenter.delegate = self
        let options: UNAuthorizationOptions = [.alert, .badge, .sound]
        
        notificationCenter.requestAuthorization(options: options) { granted, error in
            
            if let error = error {
                print("APNs Failed to request Authorization: \(error.localizedDescription)")
                return
            }
            
            if granted {
                print("APNs Authorization granted")
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                }
            } else {
                print("APNs Authorization was denied")
            }
        }
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate, MessagingDelegate {
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("APNs device token is: \(fcmToken)")

    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
        print("APNs successfully registered for push notifications: \(deviceToken)")
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        return [.badge, .banner, .sound]
    }
}

@main
struct ChitChatAppApp: App {
  // register app delegate for Firebase setup
  @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

  var body: some Scene {
    WindowGroup {
        RootScreen()
    }
  }
}
