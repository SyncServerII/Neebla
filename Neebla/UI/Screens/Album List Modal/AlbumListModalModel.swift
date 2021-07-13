
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
            // No need to do a `AlbumModel.upsertSharingGroups` -- this was already done before we get the `sync` event.
            self.fetchAlbums()
        }
    }
    
    func fetchAlbums() {
       let albums:[AlbumModel]
        
        do {
            albums = try AlbumsViewModel.getSortedCurrentAlbums()
        } catch let error {
            logger.error("\(error)")
            showAlert(AlertyHelper.alert(title: "Alert!", message: "Failed to fetch albums."))
            return
        }
        
        self.albums = albums
    }
}
