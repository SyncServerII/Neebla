
import Foundation
import SwiftUI
import iOSShared
import Combine
import SQLite

class AlbumListModalModel: ObservableObject {
    var syncSubscription: AnyCancellable!
    @Published var albums:[AlbumModel] = []
    
    init() {
        fetchAlbums()
        
        syncSubscription = Services.session.serverInterface.sync.sink { _ in
            // Propagate any sharing group changes to our AlbumModel.
            do {
                let sharingGroups = try Services.session.syncServer.sharingGroups()
                try AlbumModel.upsertSharingGroups(db: Services.session.db, sharingGroups: sharingGroups)
            } catch let error {
                logger.error("\(error)")
            }
            
            self.fetchAlbums()
        }
    }
    
    func fetchAlbums() {
       let albums:[AlbumModel]
        
        do {
            albums = try AlbumModel.fetch(db: Services.session.db, where: AlbumModel.deletedField.description == false)
        } catch let error {
            logger.error("\(error)")
            showAlert(AlertyHelper.alert(title: "Alert!", message: "Failed to fetch albums."))
            return
        }
        
        self.albums = albums
    }
    
    func removeUserFromAlbum(album: AlbumModel) {
        Services.session.syncServer.removeFromSharingGroup(sharingGroupUUID: album.sharingGroupUUID) { error in
        
            if let noNetwork = error as? Errors, noNetwork.networkIsNotReachable {
                showAlert(AlertyHelper.alert(title: "Alert!", message: "No network connection."))
                return
            }
                
            if let error = error {
                logger.error("\(error)")
                showAlert(AlertyHelper.alert(title: "Alert!", message: "Failed to remove user from album."))
                return
            }
            
            // At this point, the sync carried out by `removeFromSharingGroup` may not have completed. Rely on our `sync` listener for that.
        }
    }
}
