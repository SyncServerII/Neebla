//
//  AppState.swift
//  Neebla
//
//  Created by Christopher G Prince on 3/15/21.
//

import Foundation

enum AppState {
    case foreground
    case background
    
    static let update = NSNotification.Name("AppState")
    private static let fieldName = "Update"
    
    static func postUpdate(_ appState: AppState) {
        NotificationCenter.default.post(name: Self.update, object: nil, userInfo: [
            fieldName : appState,
        ])
    }
    
    static func getUpdate(from notification: Notification) -> AppState? {
        return notification.userInfo?[fieldName] as? AppState
    }
}
