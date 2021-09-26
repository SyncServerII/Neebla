
import Foundation
import UIKit
import iOSSignIn
import iOSBasics
import iOSShared

extension Services {
    func setupSignInServices(configPlist: ConfigPlist, signIns: SignIns, bundleIdentifier: String, defaultCloudFolderName: String, helper: SharingInvitationHelper) {
    
        var signInDescriptions = [SignInDescription]()

        let signInSetup = getSignIns(configPlist: configPlist, defaultCloudFolderName: defaultCloudFolderName)
        
        for signIn in signInSetup.signIns {
            signInDescriptions += [signIn.1]
            currentSignIns += [signIn.0]
        }
        
        var height: CGFloat = UIConfiguration.defaultHeight
        let width: CGFloat = UIConfiguration.defaultWidth
        if UIDevice.isPad {
            // Make the sign in view a bit larger on iPad
            height *= 1.5
        }
        
        configuration = UIConfiguration(
            signIntoExisting: "Sign into Existing\nNeebla Account",
            signingIntoExisting: "Signing into Existing\nNeebla Account",
            signedIntoExisting: "Signed into Existing\nNeebla Account",
                        
            createNewAccount: "Create New\nNeebla Account",
            creatingNewAccount: "Creating New\nNeebla Account",
            createdNewAccount: "Created New\nNeebla Account",
            
            acceptInvitation: "Accept Invitation",
            acceptingInvitation: "Accepting Invitation",
            acceptedInvitation: "Accepted Invitation",
            
            helpTextWhenCreatingNewAccount: "Creating a new account will give you an account in Neebla. Your cloud storage account (e.g., Dropbox) will be used to save the files you create. When you sign into Neebla later, you should use these same cloud storage account credentials.",
            
            helpTextWhenAcceptingInvitation: "Accepting the invitation will give you an account in Neebla if you don't have one already. If you accept using a cloud storage account (e.g., Dropbox), it will be used to save the files you create. If allowed, and you use a social account (e.g., Facebook) to accept the invitation, files you create will be saved in your inviting users cloud storage. When you sign into Neebla later, you should use these same account credentials.",
            width: width,
            height: height)

        signInServices = SignInServices(descriptions: signInDescriptions, configuration: configuration, appBundleIdentifier: bundleIdentifier, signIns: signIns, sharingInvitationHelper: helper)
    }
}
