//
//  AppDelegate.swift
//  Neebla
//
//  Created by Christopher G Prince on 11/10/20.
//

import UIKit
import iOSShared
import Firebase

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    
        FirebaseApp.configure()

        // I'm starting to get Crashlytics crash reports. Perhaps because I added this?
        Crashlytics.crashlytics().checkForUnsentReports { _ in
            Crashlytics.crashlytics().sendUnsentReports()
        }

        Services.setup(delegate: self)
        
        guard Services.setupState == .done(appLaunch: false) else {
            logger.critical("Services.setup: Failed")
            return false
        }
        
        Services.session.appLaunch(options: launchOptions)

        guard Services.setupState.isComplete else {
            logger.critical("Services.session.appLaunch: Failed")
            return false
        }
        
        do {
            try LocalServices.setup(db: Services.session.db)
        }
        catch let error {
            logger.critical("LocalServices: \(error)")
            return false
        }
        
        // Necessary with [1] below.
        UNUserNotificationCenter.current().delegate = self
        
        return Services.setupState.isComplete &&
            LocalServices.session?.initialized == true
    }
    
    // Neither of these are called.
    /*
    func applicationDidBecomeActive(_ application: UIApplication) {
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
    }
    */
    
    // While some of the AppDelegate methods don't seem to work when using SwiftUI and the SceneDelegate (e.g., see https://github.com/dropbox/SwiftyDropbox/issues/259), this method *does* work.
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        Services.session.syncServer.application(application, handleEventsForBackgroundURLSession: identifier, completionHandler: completionHandler)
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        PushNotifications.session.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        PushNotifications.session.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }
}

extension AppDelegate: ServicesDelegate {
    /* This is for Google Sign In. I was initially getting the error:2020-12-20 11:36:34.082029-0700 Neebla[23638:595208] Keyboard cannot present view controllers (attempted to present <SFAuthenticationViewController: 0x7fe629879a00>)
        2020-12-20 11:36:34.175586-0700 Neebla[23638:595208] [View] First responder error: non-key window attempting reload - allowing due to manual keyboard (first responder window is <UIRemoteKeyboardWindow: 0x7fe6288c2e00; frame = (0 0; 414 896); opaque = NO; autoresize = W+H; layer = <UIWindowLayer: 0x6000024ad460>>, key window is <UIWindow: 0x7fe628418530; frame = (0 0; 414 896); autoresize = W+H; gestureRecognizers = <NSArray: 0x600002a8e5e0>; layer = <UIWindowLayer: 0x6000024daf80>>)
        https://stackoverflow.com/questions/59570306
        Changed to current from:
            UIApplication.shared.windows.first?.rootViewController
        And that seems to fix it.
    */
    func getCurrentViewController() -> UIViewController? {
        return UIApplication.shared.windows.first?.rootViewController
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    // This method will be called when app receives push notifications in foreground. See [1] above.
    // See also https://stackoverflow.com/questions/14872088/get-push-notification-while-app-in-foreground-ios
    // And https://stackoverflow.com/questions/30852870 (for problem when app is in fg).
    // And https://stackoverflow.com/questions/59674174
    // The solution seems to be: https://developer.apple.com/forums/thread/661953
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .badge, .sound])
    }
}
