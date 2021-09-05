//
//  ShowAlert.swift
//  Neebla
//
//  Created by Christopher G Prince on 2/14/21.
//

import Foundation
import SwiftUI
import iOSShared

// Global to make it easier to use-- it'll be used alot.

func showAlert(_ alert: SwiftUI.Alert, checkForForeground: Bool = true) {
    // 4/16/21; Without this, I get "no network" alerts when the user first signs in for the first time. I think this is because I'm queuing alerts to show to the user.
    if checkForForeground {
        guard AppState.session.current == .foreground else {
            return
        }
    }
    
    Services.session.userEvents.alerty.send(AlertyContents(alert))
}
