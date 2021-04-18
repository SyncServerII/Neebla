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
    func signInCompleted(_ signIns: SignIns, userInfo: CheckCredsResponse.UserInfo) {
        if checkForDifferentPriorUserWithData(userState: .userSignedIn(userInfo.userId)) {
            return
        }
        
        if let fullUserName = userInfo.fullUserName {
            signInServices.manager.currentSignIn?.updateUserName(fullUserName)
            
            do {
                try SettingsModel.setupUserName(userName: fullUserName)
            } catch let error {
                logger.error("\(error)")
            }
        }
        syncServerUserId = userInfo.userId
    }
    
    func newOwningUserCreated(_ signIns: SignIns) {
        if !checkForDifferentPriorUserWithData(userState: .newUser, additionalMessage: "A new owning user was created") {
            showAlert(AlertyHelper.alert(title: "Success!", message: "Created new owning user! You are now signed in too!"))
        }
    }

    func invitationAccepted(_ signIns: SignIns, redeemResult: RedeemResult) {
        let userState:Services.UserState
        if redeemResult.userCreated {
            userState = .newUser
        }
        else {
            userState = .userSignedIn(redeemResult.userId)
        }

        if !checkForDifferentPriorUserWithData(userState: userState, additionalMessage: "A new sharing user was created") {
            if redeemResult.userCreated {
                showAlert(AlertyHelper.alert(title: "Success!", message: "Accepted invitation, and created new sharing user! You are now signed in too!"))
            }
            else {
                showAlert(AlertyHelper.alert(title: "Success!", message: "Accepted invitation! You are now signed in too!"))
            }
        }
    }
    
    func userIsSignedOut(_ signIns: SignIns) {
        // Not going to set syncServerUserId to nil. I want to keep track of the prior signed user even if they sign out. So, if they sign back in, we can check if their data is present.
    }
    
    func setCredentials(_ signIns: SignIns, credentials: GenericCredentials?) {
    }
}

extension Services {
    enum UserState {
        case newUser
        case userSignedIn(UserId)
    }
    
    @discardableResult
    func checkForDifferentPriorUserWithData(userState: UserState, additionalMessage: String? = nil) -> Bool {
        
        if let priorSignedInUserId = syncServerUserId {
            switch userState {
            case .newUser:
                // Check to see if there is data present.
                break
            case .userSignedIn(let userId):
                if priorSignedInUserId == userId {
                    return false
                }
            }
        }
        
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
            showAlert(AlertyHelper.alert(title: title, message: message))
            logger.error("signUserOut")
            signInServices.manager.currentSignIn?.signUserOut()
            return true
        }
        
        return false
    }
}
