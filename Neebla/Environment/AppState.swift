//
//  AppState.swift
//  Neebla
//
//  Created by Christopher G Prince on 3/15/21.
//

import Foundation
import iOSBasics

// Foreground/background state of the app or the sharing extension.

class AppState {
    static let session = AppState()
    
    // Unless we have a specific indication that the app is in the foreground, assume it is in the background. Trying to deal with background problems. https://github.com/SyncServerII/Neebla/issues/7
    private(set) var current: SyncServer.AppState = .background
    
    static let update = NSNotification.Name("AppState")
    private static let fieldName = "Update"
    private var extensionActive: AnyObject?
    private var extensionResignActive: AnyObject?

    private init() {
        if Bundle.isAppExtension {
            // [1] Don't get this one (or NSNotification.Name.NSExtensionHostWillEnterForeground) the first time the sharing extension's host comes into the foreground, but do the second time.
            extensionActive = NotificationCenter.default.addObserver(forName: NSNotification.Name.NSExtensionHostDidBecomeActive, object: nil, queue: nil, using: { [weak self] _ in
                self?.postUpdate(.foreground)
            })
            
            // If this code is getting executed for a sharing extension, it's getting launched into the foreground. i.e., sharing extensions don't get launched in the background. This is a bit of a hack to accomodate [1] above.
            self.postUpdate(.foreground)
            
            // I am getting this one.
            extensionResignActive = NotificationCenter.default.addObserver(forName: NSNotification.Name.NSExtensionHostWillResignActive, object: nil, queue: nil, using: { [weak self] _ in
                self?.postUpdate(.background)
            })
        }
    }
    
    func postUpdate(_ state: SyncServer.AppState) {
        current = state
        NotificationCenter.default.post(name: Self.update, object: nil, userInfo: [
            Self.fieldName : state,
        ])
    }
    
    static func getUpdate(from notification: Notification) -> SyncServer.AppState? {
        return notification.userInfo?[fieldName] as? SyncServer.AppState
    }
}
