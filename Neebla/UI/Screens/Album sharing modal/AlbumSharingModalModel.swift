
import Foundation
import SwiftUI
import Combine
import SQLite
import iOSShared
import ServerShared

class AlbumSharingModalModel: ObservableObject, ModelAlertDisplaying {
    var errorSubscription: AnyCancellable!
    @Published var userAlertModel: UserAlertModel
    let album:AlbumModel
    let helpDocs = ("SharingInvitationHelp", "html")
    @Published var helpString: String?
    let completion: (_ parameters: AlbumSharingParameters)->()
    
    // Actually only UInt values allowed.
    @Published var numberOfPeopleToInviteRaw:Float = 1 {
        didSet {
            numberOfPeopleToInvite = Int(numberOfPeopleToInviteRaw)
        }
    }
    
    @Published var numberOfPeopleToInvite:Int = 1

    @Published var allowSocialAcceptance:Bool = false
    @Published var permissionSelection:Int = 0 {
        didSet {
            logger.debug("permissionSelection: \(permissionSelection)")
        }
    }
    
    let displayablePermissionText: [String]

    init(album:AlbumModel, userAlertModel: UserAlertModel, completion:@escaping (_ parameters: AlbumSharingParameters)->()) {
        self.userAlertModel = userAlertModel
        self.album = album
        displayablePermissionText = Permission.allCases.map {$0.displayableText}
        
        if let writeIndex = displayablePermissionText.firstIndex(of: Permission.write.displayableText) {
            permissionSelection = writeIndex
        }
        
        self.completion = completion

        setupHandleErrors()
        
        guard let helpFileURL = Bundle.main.url(forResource: helpDocs.0, withExtension: helpDocs.1) else {
            logger.error("Could not load help file from bundle: \(helpDocs)")
            return
        }
        
        guard let helpData = try? Data(contentsOf: helpFileURL) else {
            logger.error("Could not load data from help file")
            return
        }
        
        helpString = String(data: helpData, encoding: .utf8)
        logger.debug("help string: \(String(describing: helpString))")
    }
    
    func createInvitation() {
        guard permissionSelection < displayablePermissionText.count,
            permissionSelection >= 0,
            let permission = Permission.from(displayablePermissionText[permissionSelection]) else {
            logger.error("Could not get permission!!")
            return
        }

        Services.session.syncServer.createSharingInvitation(withPermission: permission, sharingGroupUUID: album.sharingGroupUUID, numberAcceptors: UInt(numberOfPeopleToInvite), allowSocialAcceptance: allowSocialAcceptance) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let invitationCode):
                logger.debug("invitationCode: \(invitationCode)")
                let parameters = AlbumSharingParameters(invitationCode: invitationCode, sharingGroupName: self.album.albumName, allowSocialAcceptance: self.allowSocialAcceptance, permission: permission)
                self.completion(parameters)
                
            case .failure(let error):
                logger.error("\(error)")
                self.userAlertModel.userAlert = .titleAndMessage(title: "Alert!", message: "Failed to create sharing invitation!")
            }
        }
    }
}
