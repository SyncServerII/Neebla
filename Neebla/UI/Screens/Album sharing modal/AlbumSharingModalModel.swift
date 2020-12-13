
import Foundation
import SwiftUI
import Combine
import SQLite
import iOSShared

class AlbumSharingModalModel: ObservableObject, ModelAlertDisplaying {
    var errorSubscription: AnyCancellable!
    @Published var userAlertModel: UserAlertModel
    let album:AlbumModel
    let helpDocs = ("SharingInvitationHelp", "html")
    @Published var helpString: String?
    
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

    init(album:AlbumModel, userAlertModel: UserAlertModel) {
        self.userAlertModel = userAlertModel
        self.album = album
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
}
