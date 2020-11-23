//
//  AppDelegate.swift
//  Neebla
//
//  Created by Christopher G Prince on 11/10/20.
//

import UIKit
import iOSShared

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        Services.setup()
        Services.session.appLaunch(options: launchOptions)
        
        do {
            try LocalServices.setup()
        }
        catch let error {
            logger.error("LocalServices: \(error)")
            return false
        }
        
        return Services.setupState.isComplete
    }
    
    // While some of the AppDelegate methods don't seem to work when using SwiftUI and the SceneDelegate (e.g., see https://github.com/dropbox/SwiftyDropbox/issues/259), this method *does* work.
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        Services.session.serverInterface.syncServer.application(application, handleEventsForBackgroundURLSession: identifier, completionHandler: completionHandler)
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
}

