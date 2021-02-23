//
//  AlbumsViewModel+Index.swift
//  Neebla
//
//  Created by Christopher G Prince on 2/21/21.
//

import Foundation
import iOSShared

extension AlbumsViewModel {
    func sync(userTriggered: Bool = false) {
        if userTriggered && !Services.session.userIsSignedIn {
            showAlert(AlertyHelper.alert(title: "Alert!", message: "Please sign in to sync!"))
            isShowingRefresh = false
            return
        }
        
        guard Services.session.userIsSignedIn else {
            logger.warning("sync: Not doing. User is not signed in.")
            return
        }
        
        do {
            try Services.session.syncServer.sync()
        } catch let error {
            isShowingRefresh = false
            logger.error("\(error)")
            
            if let networkError = error as? Errors, networkError.networkIsNotReachable {
                if userTriggered {
                    showAlert(AlertyHelper.alert(title: "Alert!", message: "No network connection."))
                }
                return
            }
            
            showAlert(AlertyHelper.error(message: "Failed to sync."))
        }
    }
}
