//
//  MoveItemsSpecifics.swift
//  Neebla
//
//  Created by Christopher G Prince on 7/11/21.
//

import Foundation
import iOSShared

class MoveItemsSpecifics: AlbumListModalSpecifics {
    let albumListHeader = "Where do you want to move these items?"
    let alertTitle = "Move items?"
    let actionButtonTitle = "Move"
    
    let fileGroupsToMove: [UUID]
    let sourceSharingGroup: UUID
    
    let refreshAlbums:()->()
    
    init(fileGroupsToMove: [UUID], sourceSharingGroup: UUID, refreshAlbums:@escaping ()->()) {
        self.fileGroupsToMove = fileGroupsToMove
        self.sourceSharingGroup = sourceSharingGroup
        self.refreshAlbums = refreshAlbums
    }
    
    func alertMessage(albumName: String) -> String {
        "This will move the items you have selected to the album \"\(albumName)\"."
    }
    
    func albumFilter(albums:[AlbumModel]) -> [AlbumModel] {
        albums.filter {
            $0.sharingGroupUUID != sourceSharingGroup &&
            $0.permission == .admin
        }
    }
    
    func action(album: AlbumModel, completion: ((_ dismiss: Bool)->())?) {
        let pushNotificationMessage = PushNotificationMessage.forMovingFromAlbum(numberItems: fileGroupsToMove.count)
 
        var itemTerm = "item"
        if fileGroupsToMove.count > 1 {
            itemTerm += "s"
        }
        
        Services.session.syncServer.moveFileGroups(fileGroupsToMove, fromSourceSharingGroup: sourceSharingGroup, toDestinationSharinGroup: album.sharingGroupUUID, pushNotificationMessage: pushNotificationMessage) { result in
        
            switch result {
            case .success:
                showAlert(AlertyHelper.alert(title: "Success!", message: "Look in the other album for your moved \(itemTerm)."))
                do {
                    try ServerObjectModel.updateSharingGroups(ofFileGroups: self.fileGroupsToMove, destinationSharinGroup: album.sharingGroupUUID, db: Services.session.db)
                } catch let error {
                    logger.error("Error during updateSharingGroups: \(error)")
                    completion?(false)
                    return
                }
                
                self.refreshAlbums()
                completion?(true)
                return
                
            case .currentUploads:
                showAlert(AlertyHelper.alert(title: "Alert!", message: "There were uploads in progress-- Please try your move again later."))
                
            case .currentDeletions:
                showAlert(AlertyHelper.alert(title: "Alert!", message: "There were deletions in progress-- Please try your move again later."))
                
            case .failedWithNotAllOwnersInTarget:
                showAlert(AlertyHelper.alert(title: "Alert!", message: "Your move could not be done because some of the item owners are not in the destination album."))
                
            case .error(let error):
                logger.error("Album item move: \(String(describing: error))")
                showAlert(AlertyHelper.alert(title: "Alert!", message: "There was an unknown error when trying to do your item move."))
            }
            
            completion?(false)
        }
    }
}
