
import Foundation
import SwiftUI
import iOSShared
import Combine
import SQLite

class AlbumListModalModel: ObservableObject, ModelAlertDisplaying {
    var errorSubscription: AnyCancellable!
    @Published var userAlertModel: UserAlertModel
    
    @Published var albums:[AlbumModel] = []
    
    init(userAlertModel: UserAlertModel) {
        self.userAlertModel = userAlertModel
        setupHandleErrors()
        fetchAlbums()
    }
    
    func fetchAlbums() {
       let albums:[AlbumModel]
        
        do {
            albums = try AlbumModel.fetch(db: Services.session.db, where: AlbumModel.deletedField.description == false)
        } catch let error {
            logger.error("\(error)")
            userAlertModel.userAlert = .full(title: "Alert!", message: "Failed to fetch albums.")
            return
        }
        
        self.albums = albums
    }
    
    func removeUserFromAlbum(album: AlbumModel) {
        Services.session.syncServer.removeFromSharingGroup(sharingGroupUUID: album.sharingGroupUUID) { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                logger.error("\(error)")
                self.userAlertModel.userAlert = .full(title: "Alert!", message: "Failed to remove user from album.")
                return
            }
            
            self.fetchAlbums()
        }
    }
}
