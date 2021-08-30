
import Foundation
import iOSSignIn
import UIKit
import iOSFacebook
import iOSDropbox
import iOSGoogle
import iOSApple

// For Google Sign In issues, see https://stackoverflow.com/questions/65469685/using-google-sign-in-for-ios-with-swift-package-manager
/* See also these references for using Google Sign In in extensions in iOS:
https://stackoverflow.com/questions/36103665/how-can-i-sign-in-with-the-google-signin-sdk-in-a-sharing-extension
https://stackoverflow.com/questions/27082068/google-plus-sign-in-for-xcode-share-extension
https://stackoverflow.com/questions/39139160/retrieve-google-user-from-ios-extension/39295203#39295203
*/

extension Services {
    struct SignInSetup {
        let signIns: [(GenericSignIn, SignInDescription)]
    }
    
    // Gets (GenericSignIn, SignInDescription) pairs for each sign in type.
    // Also sets up text that is used in an email when inviting others to an album.
    func getSignIns(configPlist: ConfigPlist) -> SignInSetup {
        var signIns = [(GenericSignIn, SignInDescription)]()

        // The `SignInDescription`'s get sorted by `signInName` before being presented in the sign-in UI, so the order they are added to `result` here doesn't really matter.
        
        if let dropboxAppKey = configPlist.getValue(for: .DropboxAppKey) {
            let dropboxSignIn = DropboxSyncServerSignIn(appKey: dropboxAppKey)
            let dropboxSignInButton = dropboxSignIn.signInButton(configuration: nil)
            
            if let dropboxSignInButton = dropboxSignInButton {
                dropboxSignInButton.frame.size = CGSize(width: 150, height: 50)
            
                let dropboxDescription =
                    SignInDescription(
                        signInName: dropboxSignIn.signInName,
                        userType: dropboxSignIn.userType,
                        button: dropboxSignInButton)
                signIns += [(dropboxSignIn, dropboxDescription)]
            }
        }

        // Not yet allowing Facebook signin for the sharing extension: https://github.com/facebook/facebook-ios-sdk/issues/1607
        //if !Bundle.isAppExtension {
            let facebookSignIn = FacebookSyncServerSignIn()
            let facebookSignInButton = facebookSignIn.signInButton(configuration: nil)
            
            if let facebookButton = facebookSignInButton {
                let facebookDescription =
                    SignInDescription(
                        signInName:facebookSignIn.signInName,
                        userType: facebookSignIn.userType,
                        button: facebookButton)
                signIns += [(facebookSignIn, facebookDescription)]
            }
        //}
        
        if let googleClientId = configPlist.getValue(for: .GoogleClientId),
            let googleServerClientId = configPlist.getValue(for: .GoogleServerClientId) {
            let googleSignIn = GoogleSyncServerSignIn(serverClientId: googleServerClientId, appClientId: googleClientId, signInDelegate: self)

            if let googleSignInButton = googleSignIn.signInButton(configuration: nil) {
                let googleSignInDescription =
                    SignInDescription(
                        signInName:googleSignIn.signInName,
                        userType: googleSignIn.userType,
                        button: googleSignInButton)
                signIns += [(googleSignIn, googleSignInDescription)]
            }
        }
        
        let appleSignIn = AppleSignIn()
        if let appleSignInButton = appleSignIn.signInButton(configuration: nil) {
            let appleSignInDescription =
                SignInDescription(
                    signInName:appleSignIn.signInName,
                    userType: appleSignIn.userType,
                    button: appleSignInButton)
            signIns += [(appleSignIn, appleSignInDescription)]
        }
        
        return SignInSetup(signIns: signIns)
    }
    
    // Based on `currentSignIns`
    func emailPhraseForSharing(allowSocialAcceptance: Bool) -> String {
        var currentSignIns = self.currentSignIns
        if !allowSocialAcceptance {
            currentSignIns = currentSignIns.filter {$0.cloudStorageType != nil}
        }
        
        var sharingTypes = currentSignIns.map { $0.signInName }
        sharingTypes.sort()
        
        var sharingEmailTypes = ""
        
        for (index, sharingType) in sharingTypes.enumerated() {
            switch index {
            case 0:
                sharingEmailTypes = "\(sharingType)"
                
            case sharingTypes.count - 1:
                sharingEmailTypes += " or \(sharingType)"
                
            default:
                sharingEmailTypes += ", \(sharingType)"
            }
        }
        
        return sharingEmailTypes
    }
}

extension Services: GoogleSignInDelegate {
    func getCurrentViewController() -> UIViewController? {
        return delegate?.getCurrentViewController()
    }
}
