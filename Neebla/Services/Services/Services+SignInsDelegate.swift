//
//  Services+SignInsDelegate.swift
//  Neebla
//
//  Created by Christopher G Prince on 12/31/20.
//

import Foundation
import iOSBasics
import ServerShared
import iOSSignIn
import iOSShared

extension Services: iOSBasics.SignInsDelegate {
    func signInCompleted(_ signIns: SignIns, userId: UserId) {
        if let priorSignedInUserId = syncServerUserId {
            // There was a user signed in before. Check if it was the same user as before, and if not if the prior user had data.
            if priorSignedInUserId != userId {
                if priorUserWithData() {
                    return
                }
            }
        }
        // Else: No user signed in before.
            
        syncServerUserId = userId
    }
    
    func newOwningUserCreated(_ signIns: SignIns) {
        if !priorUserWithData(additionalMessage: "A new owning user was created") {
            #warning("Make this *not* an error!!")
            serverInterface.error = .showAlert(title: "Success!", message: "Created new owning user! You are now signed in too!")
        }
    }
    
    func invitationAcceptedAndUserCreated(_ signIns: SignIns) {
        if !priorUserWithData(additionalMessage: "A new sharing user was created") {
            serverInterface.error = .showAlert(title: "Success!", message: "Created new sharing user! You are now signed in too!")
        }
    }
    
    func userIsSignedOut(_ signIns: SignIns) {
    }
    
    func setCredentials(_ signIns: SignIns, credentials: GenericCredentials?) {
    }
}

extension Services {
    // Assumes that the new user is a different user.
    @discardableResult
    func priorUserWithData(additionalMessage: String? = nil) -> Bool {
        // There was a user signed in before. Check if it was the same user as before, and if not if the prior user had data.
        var albums = [AlbumModel]()
        do {
            albums = try AlbumModel.fetch(db: Services.session.db)
        } catch let error {
            logger.error("\(error)")
        }
        
        var title: String
        if let additionalMessage = additionalMessage {
            title = additionalMessage + ", but you "
        }
        else {
            title = "You "
        }
        
        title += " are trying to sign in as a different user than before."
        
        let message = "The Neebla app doesn't allow this (yet)."
        
        if albums.count > 0 {
            logger.error("Different user attempting to sign in and there was data from the prior user.")
            serverInterface.error = .showAlert(title: title, message: message)
            signInServices.manager.currentSignIn?.signUserOut()
            return true
        }
        
        return false
    }
}
