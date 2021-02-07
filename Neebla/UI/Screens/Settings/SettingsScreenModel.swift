
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
        case emailDeveloper
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
    @Published var userName: String?
    
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
    
    func updateUserName(userName: String?) {
        guard let userName = userName else {
            return
        }

        Services.session.serverInterface.signIns.updateUser(userName: userName) { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                logger.error("\(error)")
                self.userAlertModel.userAlert = .titleAndMessage(title: "Alert!", message: "Could not update user name. Please try again.")
                return
            }
            
            do {
                try SettingsModel.update(userName: userName, db: Services.session.db)
                self.initialUserName = userName
                self.userName = userName
            } catch let error {
                logger.error("\(error)")
            }
        }
    }
}
