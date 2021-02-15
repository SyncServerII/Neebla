
import Foundation
import SwiftUI
import Combine
import SQLite
import iOSShared
import ServerShared

class AlbumSharingModalModel: ObservableObject {
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
    
    static let expiryDurationSingleDayInterval:TimeInterval = 60*60*24
    static let defaultExpiryDurationDays:Int = 3
    static let minExpiryDurationDays:Int = 1
    static let maxExpiryDurationDays:Int = 7
    
    @Published var expiryDurationDaysRaw:Float = 1 /* defaultExpiryDurationDays */ {
        didSet {
            expiryDurationDays = Int(expiryDurationDaysRaw)
        }
    }
    
    @Published var expiryDurationDays:Int = 1 {
        didSet {
            logger.debug("Time interval: \(getExpiryInterval())")
        }
    }
    
    private func getExpiryInterval() -> TimeInterval {
        return Double(expiryDurationDays) * Self.expiryDurationSingleDayInterval
    }
    
    let displayablePermissionText: [String]

    init(album:AlbumModel, completion:@escaping (_ parameters: AlbumSharingParameters)->()) {
        self.album = album
        displayablePermissionText = Permission.allCases.map {$0.displayableText}
        
        expiryDurationDaysRaw = Float(Self.defaultExpiryDurationDays)
        expiryDurationDays = Int(Self.defaultExpiryDurationDays)
        
        if let writeIndex = displayablePermissionText.firstIndex(of: Permission.write.displayableText) {
            permissionSelection = writeIndex
        }
        
        self.completion = completion
        
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
        
        guard expiryDurationDays >= 1 else {
            logger.error("Expiry duration wasn't at least one day.")
            return
        }
        
        let expiry: TimeInterval = getExpiryInterval()

        Services.session.syncServer.createSharingInvitation(withPermission: permission, sharingGroupUUID: album.sharingGroupUUID, numberAcceptors: UInt(numberOfPeopleToInvite), allowSocialAcceptance: allowSocialAcceptance, expiryDuration: expiry) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let invitationCode):
                logger.debug("invitationCode: \(invitationCode)")
                let parameters = AlbumSharingParameters(invitationCode: invitationCode, sharingGroupName: self.album.albumName, allowSocialAcceptance: self.allowSocialAcceptance, permission: permission)
                self.completion(parameters)
                
            case .failure(let error):
                logger.error("\(error)")
                showAlert(AlertyHelper.alert(title: "Alert!", message: "Failed to create sharing invitation!"))
            }
        }
    }
}
