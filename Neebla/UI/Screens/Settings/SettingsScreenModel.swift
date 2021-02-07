
import Foundation
import CoreGraphics
import SwiftUI
import Combine
import iOSShared
import MessageUI
import SQLite

class SettingsScreenModel:ObservableObject, ModelAlertDisplaying {    
    enum ShowSheet {
        case albumList
        case emailDeveloper(addAttachments: AddEmailAttachments?)
    }
    
    var versionAndBuild:String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
            let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            return version + "/" + build
        }
        else {
            return "(Unavailable)"
        }
    }
    
    var userEventSubscription: AnyCancellable!

    @Published var userAlertModel: UserAlertModel
    @Published var showSheet: Bool = false
    @Published var sheet: ShowSheet?
    @Published var sendMailResult: Swift.Result<MFMailComposeResult, Error>? = nil
    @Published var initialUserName: String?
    @Published var userName: String? {
        didSet {
            guard let _ = SettingsModel.validUserNameUpdate(oldUserName: initialUserName, newUserName: userName) else {
                userNameChangeIsValid = false
                return
            }
            
            userNameChangeIsValid = true
        }
    }
    @Published var userNameChangeIsValid: Bool = false
    
    init(userAlertModel: UserAlertModel) {
        self.userAlertModel = userAlertModel
        setupHandleUserEvents()
        
        do {
            if let userName = try SettingsModel.userName(db: Services.session.db) {
                initialUserName = userName
                self.userName = initialUserName
            }
            else if let userName = Services.session.signInServices.manager.currentSignIn?.credentials?.username {
                updateUserName(userName: userName)
            }
        } catch let error {
            logger.error("\(error)")
        }
    }
    
    func updateUserName(userName: String?, completion:((_ success:Bool)->())? = nil) {
        guard let userName = userName else {
            completion?(false)
            return
        }

        Services.session.serverInterface.signIns.updateUser(userName: userName) { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                logger.error("\(error)")
                self.userAlertModel.userAlert = .titleAndMessage(title: "Alert!", message: "Could not update user name. Please try again.")
                completion?(false)
                return
            }
            
            do {
                try SettingsModel.update(userName: userName, db: Services.session.db)
                self.initialUserName = userName
                self.userName = userName
                // Don't have to directly update `userNameChangeIsValid`-- these two above changes will do that.
                completion?(true)
            } catch let error {
                logger.error("\(error)")
                completion?(false)
            }
        }
    }
}

extension SettingsScreenModel: AddEmailAttachments {
    func addAttachments(vc: MFMailComposeViewController) {
        let archivedFileURLs = sharedLogging.archivedFileURLs
        guard archivedFileURLs.count > 0 else {
            return
        }
        
        for logFileURL in archivedFileURLs {
            guard let logFileData = try? Data(contentsOf: logFileURL, options: NSData.ReadingOptions()) else {
                continue
            }
            
            let fileName = logFileURL.lastPathComponent
            vc.addAttachmentData(logFileData, mimeType: "text/plain", fileName: fileName)
        }
    }
}
