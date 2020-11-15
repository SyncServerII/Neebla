//
//  Services+Invitation.swift
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
        serverInterface.syncServer.getSharingInvitationInfo(sharingInvitationUUID: invitationCodeUUID) { [weak self] result in
            guard let self = self else { return }
            
            var message: String?
            
            switch result {
            case .success(let info):
                switch info {
                case .invitation(let invitation):
                    if self.signInServices.manager.userIsSignedIn {
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
                message = "\(error)"
            }
            
            if let message = message {
                DispatchQueue.main.async {
                    Alert.show(withTitle: "Alert!", message: message)
                }
            }
        }
    }
    
    func redeemForCurrentUser(invitationCode: UUID) {
        serverInterface.syncServer.redeemSharingInvitation(sharingInvitationUUID: invitationCode) { result in
            switch result {
            case .success:
                DispatchQueue.main.async {
                    Alert.show(withTitle: "Success!", message: "You are now in another sharing group!")
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    Alert.show(withTitle: "Alert!", message: "\(error)")
                }
            }
        }
    }
}
