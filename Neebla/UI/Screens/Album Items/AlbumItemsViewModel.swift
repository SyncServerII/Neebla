
import Foundation
import SQLite
import Combine
import iOSShared
import iOSBasics

extension AlertMessage {
    func showMessage(for errorEvent: ErrorEvent?) {
        switch errorEvent {
        case .error(let error):
            if let error = error {
                alertMessage = "Error: \(error)"
            }
            else {
                alertMessage = "Error!"
            }
            
        case .showAlert(title: let title, message: let message):
            alertMessage = "\(title): \(message)"

        case .none:
            // This isn't an error
            break
        }
    }
}

class AlbumItemsViewModel: ObservableObject, AlertMessage {
    @Published var loading: Bool = false {
        didSet {
            if oldValue == false && loading == true {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.sync()
                }
            }
        }
    }
    
    @Published var objects = [ServerObjectModel]()
    let sharingGroupUUID: UUID

    @Published var presentAlert = false

    var alertMessage: String! {
        didSet {
            presentAlert = alertMessage != nil
        }
    }
    
    @Published var addNewItem = false
    private var syncSubscription:AnyCancellable!
    private var errorSubscription:AnyCancellable!

    init(album sharingGroupUUID: UUID) {
        self.sharingGroupUUID = sharingGroupUUID
        
        syncSubscription = Services.session.serverInterface.$sync.sink { [weak self] syncResult in
            guard let self = self else { return }
            
            self.loading = false
            self.getItemsForAlbum(album: sharingGroupUUID)
        }
        
        errorSubscription = Services.session.serverInterface.$error.sink { [weak self] errorEvent in
            guard let self = self else { return }
            self.showMessage(for: errorEvent)
        }
        
        getItemsForAlbum(album: sharingGroupUUID)
    }
    
    private func getItemsForAlbum(album sharingGroupUUID: UUID) {
        if let objects = try? ServerObjectModel.fetch(db: Services.session.db, where: ServerObjectModel.sharingGroupUUIDField.description == sharingGroupUUID) {
            self.objects = objects
        }
        else {
            self.objects = []
        }
    }
    
    func sync() {
        do {
            try Services.session.syncServer.sync(sharingGroupUUID: sharingGroupUUID)
        } catch let error {
            logger.error("\(error)")
            loading = false
            alertMessage = "Failed to sync."
        }
    }
    
    func startNewAddItem() {
        addNewItem = true
    }
}
