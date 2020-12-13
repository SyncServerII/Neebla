//
//  ViewModel.swift
//  iOSIntegration
//
//  Created by Christopher G Prince on 9/24/20.
//

import Foundation
import iOSSignIn
import iOSBasics
import iOSShared
import ServerShared

class SignInViewModel: ObservableObject {
    @Published var userSignedIn: Bool = false
    
    var signIn:GenericSignIn? {
        return Services.session.signInServices.manager.currentSignIn
    }
        
    init() {
        #warning("Perhaps a little weak. Maybe a SignInManagerDelegate call for a silent sign in would be better?")
        if Services.session.signInServices.manager.currentSignIn != nil {
            userSignedIn = true
        }
        
        Services.session.signInServices.manager.delegate = self
    }
}

extension SignInViewModel: SignInManagerDelegate {
    func sharingInvitationForSignedInUser(_ manager: SignInManager, invitation: Invitation) {
        guard let invitationCodeUUID = UUID(uuidString: invitation.code) else {
            DispatchQueue.main.async {
                Services.session.serverInterface.error = .showAlert(title: "Alert!", message: "Bad invitation code")
            }
            return
        }
        Services.session.redeemForCurrentUser(invitationCode: invitationCodeUUID)
    }
    
    func signInCompleted(_ manager: SignInManager, signIn: GenericSignIn, mode: AccountMode, autoSignIn: Bool) {
        userSignedIn = true
    }
    
    func userIsSignedOut(_ manager: SignInManager, signIn: GenericSignIn) {
        DispatchQueue.main.async {
            self.userSignedIn = false
        }
    }
}
