//
//  PushNotifications.swift
//  Neebla
//
//  Created by Christopher G Prince on 1/15/21.
//

import Foundation
import UserNotifications
import PersistentValue
import iOSShared
import UIKit

class PushNotifications {
    // Just being cautious-- putting this in the keychain.
    private static let deviceToken = try! PersistentValue<Data>(name: "PushNotifications.deviceToken", storage: .keyChain)
    
    private static let askedUserAboutNotifications = try! PersistentValue<Bool>(name: "PushNotifications.askedUserAboutNotifications", storage: .userDefaults)

    private static let notificationsAuthorized = try! PersistentValue<Bool>(name: "PushNotifications.notificationsAuthorized", storage: .userDefaults)

    static let session = PushNotifications()
    
    // Some code adapted from: https://stackoverflow.com/questions/37956482/registering-for-push-notifications-in-xcode-8-swift-3-0
    private func register() {
        let center = UNUserNotificationCenter.current()
        // The first time this gets called, it will ask the user for authorization. Subsequent times, no user prompt occurs; it just return the prior result.
        center.requestAuthorization(options:[.badge, .alert, .sound]) { (granted, error) in
            logger.info("requestAuthorization: granted: \(granted)")
            Self.notificationsAuthorized.value = granted

            guard error == nil else {
                logger.error("requestAuthorization: \(error!)")
                return
            }

            if granted {
                DispatchQueue.main.async {
                    // At least as of 1/16/21, with Xcode 12.3, this still fails on the simulator. See https://stackoverflow.com/questions/1080556
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
            else {
                logger.info("User didn't grant Push Notifications")
            }
        }
    }
    
    func checkForNotificationAuthorization(userAlertModel:UserAlertModel) {
        if let asked = Self.askedUserAboutNotifications.value, asked {
            if let authorized = Self.notificationsAuthorized.value {
                if authorized {
                    register()
                }
            }
            else {
                register()
            }
        }
        else {
            Self.askedUserAboutNotifications.value = true
            
            let title = "Would you like notifications about new media and discussion comments?"
            let message = "Then, answer \"Allow\" on the next prompt!"
            
            let okAction:() -> () = { [weak self] in
                self?.register()
            }
            
            let cancelAction = {
                // TODO: Eventually, we may want to have a Settings UI feature that reverses this-- otherwise, allowing notifications in the Apple Settings app will have no effect. OR-- is it possible to get an NSNotification about this user change?
                Self.notificationsAuthorized.value = false
            }
            
            userAlertModel.userAlert = .customDetailedAction(title: title, message: message, actionButtonTitle: "OK", action: okAction, cancelTitle: "Cancel", cancelAction: cancelAction)
        }
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {

        let deviceTokenString = deviceToken.reduce("", {$0 + String(format: "%02X", $1)})
        logger.info("Device token: \(deviceTokenString)")

        if Self.deviceToken.value == deviceToken {
            logger.info("Device token unchanged.")
            return
        }
        
        Services.session.serverInterface.syncServer.registerPushNotificationToken(deviceTokenString) { error in
            if let error = error {
                logger.error("registerPushNotificationToken: \(error)")
                return
            }
            
            logger.info("Device token changed: Updating in persistent store.")
            Self.deviceToken.value = deviceToken
        }
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        logger.error("didFailToRegisterForRemoteNotificationsWithError: \(error)")
    }
}
