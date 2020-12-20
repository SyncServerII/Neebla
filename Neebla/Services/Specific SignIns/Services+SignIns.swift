
import Foundation
import iOSSignIn
import UIKit
import iOSFacebook
import iOSDropbox
import iOSGoogle

extension Services {
    // Gets (GenericSignIn, SignInDescription) pairs for each sign in type.
    func getSignIns(configPlist: ConfigPlist) -> [(GenericSignIn, SignInDescription)] {
        var result = [(GenericSignIn, SignInDescription)]()
        
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
                result += [(dropboxSignIn, dropboxDescription)]
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
            result += [(facebookSignIn, facebookDescription)]
        }
        
        if let googleClientId = configPlist.getValue(for: .GoogleClientId),
            let googleServerClientId = configPlist.getValue(for: .GoogleServerClientId) {
            let googleSignIn = GoogleSyncServerSignIn(serverClientId: googleServerClientId, appClientId: googleClientId, signInDelegate: self)
            
            if let googleSignInButton = googleSignIn.signInButton(configuration: nil) {
                let googleSignInDescription =
                    SignInDescription(
                        signInName:googleSignIn.signInName,
                        userType: googleSignIn.userType,
                        button: googleSignInButton)
                result += [(googleSignIn, googleSignInDescription)]
            }
        }

        return result
    }
}

extension Services: GoogleSignInDelegate {
    func getCurrentViewController() -> UIViewController? {
        return delegate?.getCurrentViewController()
    }
}
