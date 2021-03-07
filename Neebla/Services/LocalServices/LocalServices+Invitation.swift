//
//  LocalServices+Invitation.swift
//  iOSIntegration
//
//  Created by Christopher G Prince on 10/1/20.
//

import Foundation
import ServerShared
import iOSShared

extension Services {
    // Call this if the user pastes an invitation code into the UI and needs to redeem it.
    func copyPaste(invitationCodeUUID: UUID) {
        syncServer.getSharingInvitationInfo(sharingInvitationUUID: invitationCodeUUID) { [weak self] result in
            guard let self = self else { return }
            
            var message: String?
            
            switch result {
            case .success(let info):
                switch info {
                case .invitation(let invitation):
                    if let userIsSignedIn = self.signInServices.manager.userIsSignedIn, userIsSignedIn {
                        self.redeemForCurrentUser(invitationCode: invitationCodeUUID)
                        return
                    }
                    
                    // User not signed in.
                    do {
                        try self.signInServices.copyPaste(invitation: invitation)
                        return
                    } catch let error {
                        message = "\(error)"
                    }
                case .noInvitationFound:
                    message = "No invitation was found on server. Did it expire?"
                }
                
            case .failure(let error):
                if let networkError = error as? Errors, networkError.networkIsNotReachable {
                    showAlert(AlertyHelper.alert(title: "Alert!", message: "No network connection."))
                }
                else {
                    message = "\(error)"
                }
            }
            
            if let message = message {
                DispatchQueue.main.async {
                    showAlert(AlertyHelper.alert(title: "Alert!", message: message))
                }
            }
        }
    }
    
    func redeemForCurrentUser(invitationCode: UUID) {
        syncServer.redeemSharingInvitation(sharingInvitationUUID: invitationCode) { result in
            switch result {
            case .success:
                DispatchQueue.main.async {
                    showAlert(AlertyHelper.alert(title: "Success!", message: "You now have access to another album!"))
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    if let noNetwork = error as? Errors, noNetwork.networkIsNotReachable {
                        showAlert(AlertyHelper.alert(title: "Alert!", message: "No network connection."))
                        return
                    }

                    showAlert(AlertyHelper.alert(title: "Alert!", message: "Failed redeeming sharing invitation. Has it expired? Have you redeemded it already?"))
                    logger.error("\(error)")
                }
            }
        }
    }
}
