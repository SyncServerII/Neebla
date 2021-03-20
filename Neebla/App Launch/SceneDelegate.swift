//
//  SceneDelegate.swift
//  Neebla
//
//  Created by Christopher G Prince on 11/10/20.
//

import UIKit
import SwiftUI
import iOSShared

// Adapted from https://stackoverflow.com/questions/57441654/swiftui-repaint-view-components-on-device-rotation
class AppEnv: ObservableObject {
    @Published var isLandScape: Bool = false
}

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    var appEnv = AppEnv()

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).

        // Create the SwiftUI view that provides the window contents.
        let contentView = MainView()

        // Use a UIHostingController as window root view controller.
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = UIHostingController(rootView: contentView.environmentObject(appEnv))
            self.window = window
            window.makeKeyAndVisible()
        }
        
        // Because on an app launch when tapping on a sharing invitation, I don't get the `openURLContexts` method called. See also https://stackoverflow.com/questions/58973143
        let urlinfo = connectionOptions.urlContexts
        if let url = urlinfo.first?.url {
            _ = Services.session.application(UIApplication.shared, open: url)
        }
    }

    // See https://github.com/dropbox/SwiftyDropbox/issues/259
    // Also relevant: I first tried to use the SwiftUI life cycle management-- without a SceneDelegate, but I wasn't able to get an equivalent method to this called. Even using https://stackoverflow.com/questions/62538110
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        if let url = URLContexts.first?.url {
            _ = Services.session.application(UIApplication.shared, open: url)
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
        logger.debug("sceneDidBecomeActive")
        AppState.session.postUpdate(.foreground)
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
        logger.debug("sceneWillResignActive")
        debugBackground()
        AppState.session.postUpdate(.background)
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }

    func windowScene(_ windowScene: UIWindowScene, didUpdate previousCoordinateSpace: UICoordinateSpace, interfaceOrientation previousInterfaceOrientation: UIInterfaceOrientation, traitCollection previousTraitCollection: UITraitCollection) {
        appEnv.isLandScape = windowScene.interfaceOrientation.isLandscape
    }
}

extension SceneDelegate {
    func debugBackground() {
        logger.debug("openFilePaths: \(openFilePaths())")
    }
    
    // From https://developer.apple.com/forums/thread/655225
    func openFilePaths() -> [String] {
        let result = (0..<getdtablesize()).map { fd -> (String?) in
            var flags: CInt = 0
            guard fcntl(fd, F_GETFL, &flags) >= 0 else {
                return nil
            }
            // Return "?" for file descriptors not associated with a path, for
            // example, a socket.
            var path = [CChar](repeating: 0, count: Int(MAXPATHLEN))
            guard fcntl(fd, F_GETPATH, &path) >= 0 else {
                return "?"
            }
            
            // https://stackoverflow.com/questions/11737819
            var flockValue:flock = flock()
            if fcntl(fd, F_GETLK, &flockValue) >= 0 &&
                flockValue.l_type == F_WRLCK {
                return String(cString: path) + "; flock.l_type: F_WRLCK (exclusive or write lock)"
            }

            return String(cString: path)
        }
        
        return result.compactMap {$0}
    }
}
