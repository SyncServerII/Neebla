
import Foundation
import SQLite

protocol AlertMessage: AnyObject {
    var alertMessage: String! { get set }
}

class AlbumItemsViewModel: ObservableObject, AlertMessage {
    @Published var objects = [ServerObjectModel]()
    let sharingGroupUUID: UUID

    @Published var isShowingRefresh = false
    @Published var presentAlert = false

    var alertMessage: String! {
        didSet {
            presentAlert = alertMessage != nil
        }
    }
    
    @Published var addNewItem = false
    
    init(album sharingGroupUUID: UUID) {
        self.sharingGroupUUID = sharingGroupUUID
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
        Services.session.serverInterface.sync(sharingGroupUUID: sharingGroupUUID) { [weak self] error in
            guard let self = self else { return }
            
            self.isShowingRefresh = false

            guard error == nil else {
                self.alertMessage = "Failed to sync."
                return
            }
            
            self.getItemsForAlbum(album: self.sharingGroupUUID)
        }
    }
    
    func startNewAddItem() {
        addNewItem = true
    }
}
