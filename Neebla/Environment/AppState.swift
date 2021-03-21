//
//  AppState.swift
//  Neebla
//
//  Created by Christopher G Prince on 3/15/21.
//

import Foundation

// Foreground/background state of the app

class AppState {
    enum State {
        case foreground
        case background
    }
    
    static let session = AppState()
    
    // Unless we have a specific indication that the app is in the foreground, assume it is in the background. Trying to deal with background problems https://github.com/SyncServerII/Neebla/issues/7
    private(set) var current: State = .background
    
    static let update = NSNotification.Name("AppState")
    private static let fieldName = "Update"
    
    private init() {
    }
    
    func postUpdate(_ state: State) {
        current = state
        NotificationCenter.default.post(name: Self.update, object: nil, userInfo: [
            Self.fieldName : state,
        ])
    }
    
    static func getUpdate(from notification: Notification) -> State? {
        return notification.userInfo?[fieldName] as? State
    }
}
