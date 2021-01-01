
import Foundation
import SwiftUI
import iOSShared
import Combine

class AlbumSharingScreenModel: ObservableObject, ModelAlertDisplaying {
    var userEventSubscription: AnyCancellable!
    @ObservedObject var userAlertModel:UserAlertModel

    @Published var sharingCode: String? {
        didSet {
            if let trimmedSharingCode = getTrimmedSharingCode() {
                if trimmedSharingCode.count > 0 {
                    enableAcceptSharingInvitation = true
                    return
                }
            }
            
            enableAcceptSharingInvitation = false
        }
    }
    
    private func getTrimmedSharingCode() -> String? {
        if let sharingCode = sharingCode {
            return sharingCode.trimmingCharacters(in: .whitespaces)
        }
        return nil
    }
    
    @Published var enableAcceptSharingInvitation: Bool = false
    
    init(userAlertModel:UserAlertModel) {
        self.userAlertModel = userAlertModel
        setupHandleUserEvents()
    }
    
    func acceptSharingInvitation() {
        guard let trimmedSharingCode = getTrimmedSharingCode(),
            let sharingCodeUUID = UUID(uuidString: trimmedSharingCode) else {
            userAlertModel.userAlert = .error(message: "Bad sharing code.")
            return
        }
        
        Services.session.syncServer.redeemSharingInvitation(sharingInvitationUUID: sharingCodeUUID) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success:
                // The index was automatically synced. Don't need to do it again.
                self.userAlertModel.userAlert = .titleAndMessage(title: "Success!", message: "You have a new sharing album!")
                self.sharingCode = nil
                
            case .failure(let error):
                logger.error("\(error)")
                self.userAlertModel.userAlert = .error(message: "Failure redeeming sharing code.")
            }
        }
    }
}
