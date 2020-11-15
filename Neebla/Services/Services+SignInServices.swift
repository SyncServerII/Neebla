//
//  Services+.swift
//  iOSIntegration
//
//  Created by Christopher G Prince on 9/28/20.
//

import Foundation
import iOSFacebook
import iOSDropbox
import UIKit
import iOSSignIn
import iOSBasics

extension Services {
    func setupSignInServices(configPlist: Dictionary<String, Any>, signIns: SignIns, bundleIdentifier: String, helper: SharingInvitationHelper) {
    
        var signInDescriptions = [SignInDescription]()

        if let dropboxAppKey = configPlist["DropboxAppKey"] as? String {
            let dropboxSignIn = DropboxSyncServerSignIn(appKey: dropboxAppKey)
            let dropboxSignInButton = dropboxSignIn.signInButton(configuration: nil)
            
            if let dropboxSignInButton = dropboxSignInButton {
                dropboxSignInButton.frame.size = CGSize(width: 150, height: 50)
            
                let dropboxDescription =
                    SignInDescription(
                        signInName: dropboxSignIn.signInName,
                        userType: dropboxSignIn.userType,
                        button: dropboxSignInButton)
                signInDescriptions += [dropboxDescription]
                signInsToAdd += [dropboxSignIn]
            }
        }

        let facebookSignIn = FacebookSyncServerSignIn()
        let facebookSignInButton = facebookSignIn.signInButton(configuration: nil)
        
        if let facebookButton = facebookSignInButton {
            let facebookDescription =
                SignInDescription(
                    signInName:facebookSignIn.signInName,
                    userType: facebookSignIn.userType,
                    button: facebookButton)
            signInDescriptions += [facebookDescription]
            signInsToAdd += [facebookSignIn]
        }
        
        configuration = UIConfiguration(
            signIntoExisting: "Sign into Existing\nNeebla Account",
            signingIntoExisting: "Signing into Existing\nNeebla Account",
            signedIntoExisting: "Signed into Existing\nNeebla Account",
                        
            createNewAccount: "Create New\nNeebla Account",
            creatingNewAccount: "Creating New\nNeebla Account",
            createdNewAccount: "Created New\nNeebla Account",
            
            createAccountAndAcceptInvitation: "Accept Invitation and Create New Neebla Account",
            creatingAccountAndAcceptingInvitation: "Creating New\nNeebla Account",
            createdAccountAndAcceptedInvitation: "Created New\nNeebla Account",
            
            helpTextWhenCreatingNewAccount: "Creating a new account will give you an account in Neebla. Your cloud storage account (e.g., Dropbox) will be used to save the files you create. When you sign into Neebla later, you should use these same cloud storage account credentials.",
            
            helpTextWhenAcceptingInvitation: "Accepting the invitation will give you an account in Neebla. If you accept using a cloud storage account (e.g., Dropbox), it will be used to save the files you create. If allowed, and you use a social account (e.g., Facebook) to accept the invitation, files you create will be saved in your inviting users cloud storage. When you sign into Neebla later, you should use these same account credentials.")

        signInServices = SignInServices(descriptions: signInDescriptions, configuration: configuration, appBundleIdentifier: bundleIdentifier, signIns: signIns, sharingInvitationHelper: helper)
    }
}
