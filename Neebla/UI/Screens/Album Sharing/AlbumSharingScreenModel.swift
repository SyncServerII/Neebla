
import Foundation
import SwiftUI
import iOSShared
import Combine

class AlbumSharingScreenModel: ObservableObject {
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
    
    func acceptSharingInvitation() {
        guard let trimmedSharingCode = getTrimmedSharingCode(),
            let sharingCodeUUID = UUID(uuidString: trimmedSharingCode) else {
            showAlert(AlertyHelper.error(message: "Bad sharing code."))
            return
        }
        
        Services.session.syncServer.redeemSharingInvitation(sharingInvitationUUID: sharingCodeUUID) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success:
                // The index was automatically synced. Don't need to do it again.
                showAlert(AlertyHelper.alert(title: "Success!", message: "You have a new sharing album!"))
                self.sharingCode = nil
                
            case .failure(let error):
                logger.error("\(error)")
                showAlert(AlertyHelper.error(message: "Failure redeeming sharing code."))
            }
        }
    }
}
