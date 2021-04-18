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
import Combine

class SignInViewModel: ObservableObject {
    @Published var userSignedIn: Bool = false
    
    // Only ever transitions from true to false and do this exactly once.
    @Published var landingViewDisplayed: Bool = true
    let initialDelayMS = 1500
    
    var signIn:GenericSignIn? {
        return Services.session.signInServices.manager.currentSignIn
    }
    
    var signInSubscription: AnyCancellable!
    
    init() {
        signInSubscription = Services.session.signInServices.manager.$userIsSignedIn.sink { [weak self] signedIn in
        
            DispatchQueue.main.async {
                self?.userSignedIn = signedIn ?? false
            }
            
            do {
                // Allowing nil user name because user creds may supply a nil user name.
                try SettingsModel.setupUserName(userName: Services.session.username, allowNilUserName: true)
            } catch let error {
                logger.error("\(error)")
            }
        }
        
        Services.session.signInServices.manager.delegate = self
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(initialDelayMS)) {
            self.landingViewDisplayed = false
        }
    }
}

extension SignInViewModel: SignInManagerDelegate {
    func sharingInvitationForSignedInUser(_ manager: SignInManager, invitation: Invitation) {
        guard let invitationCodeUUID = UUID(uuidString: invitation.code) else {
            DispatchQueue.main.async {
                // Called while app is transitioning from background to foreground, so don't check if app is in foreground.
                showAlert(AlertyHelper.alert(title: "Alert!", message: "Bad invitation code"), checkForForeground: false)
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
