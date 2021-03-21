//
//  AppState.swift
//  Neebla
//
//  Created by Christopher G Prince on 3/15/21.
//

import Foundation
import iOSBasics

// Foreground/background state of the app

class AppState {
    static let session = AppState()
    
    // Unless we have a specific indication that the app is in the foreground, assume it is in the background. Trying to deal with background problems https://github.com/SyncServerII/Neebla/issues/7
    private(set) var current: SyncServer.AppState = .background
    
    static let update = NSNotification.Name("AppState")
    private static let fieldName = "Update"
    
    private init() {
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
