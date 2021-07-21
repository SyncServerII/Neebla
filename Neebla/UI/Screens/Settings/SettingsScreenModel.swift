
import Foundation
import CoreGraphics
import SwiftUI
import Combine
import iOSShared
import MessageUI
import SQLite

class SettingsScreenModel:ObservableObject {
    var deletionSpecifics: AlbumListModalDeletion {
        return AlbumListModalDeletion()
    }
    
    enum ShowSheet: Identifiable {        
        case albumList
        case emailDeveloper(addAttachments: AddEmailAttachments?)
        case aboutApp
        case removeUser
        
        var id: Int {
            switch self {
            case .albumList:
                return 0
            case .emailDeveloper:
                return 1
            case .aboutApp:
                return 2
            case .removeUser:
                return 3
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
        // Logging these as `notice` to make sure they hit the logs for production builds.
        logger.notice("Email attachments:")
        do {
            // Logging these as errors to make sure they hit the logs.
            if let pendingUploads = try Services.session.syncServer.debugPendingUploads() {
                logger.notice("Pending Uploads: \(String(describing: pendingUploads))")
            }
            else {
                logger.notice("No Pending Uploads")
            }
            
            logger.notice("Albums:")
            let albums = try AlbumModel.fetch(db: Services.session.db)
            for album in albums {
                logger.notice("Album: sharingGroupUUID: \(album.sharingGroupUUID); name: \(String(describing: album.albumName)); deleted: \(album.deleted)")
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

class AlbumListModalDeletion: AlbumListModalSpecifics {
    let albumListHeader = "Select album to delete:"
    let alertTitle = "Delete album?"
    let actionButtonTitle = "Remove"
    
    func alertMessage(albumName: String) -> String {
        "This will remove you from the album \"\(albumName)\". And if you are the last one using the album, will entirely remove the album."
    }
    
    func action(album: AlbumModel, completion: ((_ alert: ActionCompletion)->())?) {
        Services.session.syncServer.removeFromSharingGroup(sharingGroupUUID: album.sharingGroupUUID) { error in
        
            if let noNetwork = error as? Errors, noNetwork.networkIsNotReachable {
                completion?(.showAlert(AlertyHelper.alert(title: "Alert!", message: "No network connection.")))
                return
            }
                
            if let error = error {
                logger.error("\(error)")
                completion?(.showAlert(AlertyHelper.alert(title: "Alert!", message: "Failed to remove user from album.")))
                return
            }
            
            // At this point, the sync carried out by `removeFromSharingGroup` may not have completed. Rely on our `sync` listener for that.
            
            completion?(.dismissAndThenShow(AlertyHelper.alert(title: "Success", message: "You have been removed from the album.")))
        }
    }
}
