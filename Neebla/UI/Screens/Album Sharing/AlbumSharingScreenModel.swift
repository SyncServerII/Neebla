
import Foundation
import SwiftUI
import iOSShared
import Combine

class AlbumSharingScreenModel: ObservableObject, ModelAlertDisplaying {
    var errorSubscription: AnyCancellable!
    @ObservedObject var userAlertModel:UserAlertModel

    @Published var sharingCode: String? {
        didSet {
            if let sharingCode = sharingCode {
                let trimmed = sharingCode.trimmingCharacters(in: .whitespaces)
                if trimmed.count > 0 {
                    enableAcceptSharingInvitation = true
                    return
                }
            }
            
            enableAcceptSharingInvitation = false
        }
    }
    
    @Published var enableAcceptSharingInvitation: Bool = false
    
    init(userAlertModel:UserAlertModel) {
        self.userAlertModel = userAlertModel
        setupHandleErrors()
    }
    
    func acceptSharingInvitation() {
        guard let sharingCode = sharingCode,
            let sharingCodeUUID = UUID(uuidString: sharingCode) else {
            userAlertModel.userAlert = .error(message: "Bad sharing code.")
            return
        }
        
        Services.session.syncServer.redeemSharingInvitation(sharingInvitationUUID: sharingCodeUUID) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success:
                // The index was automatically synced. Don't need to do it again.
                self.userAlertModel.userAlert = .full(title: "Success!", message: "You have a new sharing album!")
                self.sharingCode = nil
                
            case .failure(let error):
                logger.error("\(error)")
                self.userAlertModel.userAlert = .error(message: "Failure redeeming sharing code.")
            }
        }
    }
}
