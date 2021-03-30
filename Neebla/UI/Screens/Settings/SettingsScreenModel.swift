
import Foundation
import CoreGraphics
import SwiftUI
import Combine
import iOSShared
import MessageUI
import SQLite

class SettingsScreenModel:ObservableObject {
    enum ShowSheet: Identifiable {        
        case albumList
        case emailDeveloper(addAttachments: AddEmailAttachments?)
        case aboutApp
        
        var id: Int {
            switch self {
            case .albumList:
                return 0
            case .emailDeveloper:
                return 1
            case .aboutApp:
                return 2
            }
        }
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
    
    @Published var sheet: ShowSheet?
    @Published var sendMailResult: Swift.Result<MFMailComposeResult, Error>? = nil
    @Published private(set) var initialUserName: String?
    @Published var userName: String? {
        didSet {
            guard let _ = SettingsModel.checkForValidUserNameUpdate(oldUserName: initialUserName, newUserName: userName) else {
                userNameChangeIsValid = false
                return
            }
            
            userNameChangeIsValid = true
        }
    }
    
    @Published var userNameChangeIsValid: Bool = false
    
    init() {
        do {
            if let userName = try SettingsModel.userName(db: Services.session.db) {
                initialUserName = userName
                self.userName = userName
            }
        } catch let error {
            logger.error("\(error)")
        }
    }
    
    func updateUserNameOnServer(userName: String?, completion:((_ success:Bool)->())? = nil) {
        guard let userName = userName else {
            completion?(false)
            return
        }

        Services.session.serverInterface.signIns.updateUser(userName: userName) { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                logger.error("\(error)")
                showAlert(AlertyHelper.alert(title: "Alert!", message: "Could not update user name. Please try again."))
                completion?(false)
                return
            }
            
            do {
                try SettingsModel.update(userName: userName, db: Services.session.db)
                self.initialUserName = userName
                self.userName = userName
                // `userName` setter also changes `userNameChangeIsValid`.
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
        do {
            // Logging these as errors to make sure they hit the logs.
            if let pendingUploads = try Services.session.syncServer.debugPendingUploads() {
                logger.error("Pending Uploads: \(String(describing: pendingUploads))")
            }
            else {
                logger.error("No Pending Uploads")
            }
        } catch let error {
            logger.error("\(error)")
        }
        
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
