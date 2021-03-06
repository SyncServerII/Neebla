//
//  MoveItemsSpecifics.swift
//  Neebla
//
//  Created by Christopher G Prince on 7/11/21.
//

import Foundation
import iOSShared
import SwiftUI
import ServerShared

class MoveItemsSpecifics: AlbumListModalSpecifics {
    let albumListHeader = "Where do you want to move these items?"
    let alertTitle = "Move items?"
    let actionButtonTitle = "Move"
    
    let fileGroupsToMove: [UUID]
    let sourceSharingGroup: UUID
    let usersMakingComments:Set<UserId>
    
    let refreshAlbums:()->()
    
    init(usersMakingComments:Set<UserId>, fileGroupsToMove: [UUID], sourceSharingGroup: UUID, refreshAlbums:@escaping ()->()) {
        self.fileGroupsToMove = fileGroupsToMove
        self.sourceSharingGroup = sourceSharingGroup
        self.refreshAlbums = refreshAlbums
        self.usersMakingComments = usersMakingComments
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
    
    func action(album: AlbumModel, completion: ((_ alert: ActionCompletion)->())?) {
        // Rod and Dany didn't like this idea. Of also having a push notification for the source album. So, at least for now, I'm getting rid of it.
        // let sourcePushNotificationMessage = PushNotificationMessage.forMoving(numberItems: fileGroupsToMove.count, moveDirection: .from)
        
        let destinationPushNotificationMessage = PushNotificationMessage.forMoving(numberItems: fileGroupsToMove.count, moveDirection: .to)
 
        var itemTerm = "item"
        if fileGroupsToMove.count > 1 {
            itemTerm += "s"
        }
        
        Services.session.syncServer.moveFileGroups(fileGroupsToMove, usersThatMustBeInDestination: usersMakingComments, fromSourceSharingGroup: sourceSharingGroup, toDestinationSharingGroup: album.sharingGroupUUID, sourcePushNotificationMessage: nil, destinationPushNotificationMessage: destinationPushNotificationMessage) { result in
        
            switch result {
            case .success:
                do {
                    try ServerObjectModel.updateSharingGroups(ofFileGroups: self.fileGroupsToMove, destinationSharinGroup: album.sharingGroupUUID, db: Services.session.db)
                } catch let error {
                    logger.error("Error during updateSharingGroups: \(error)")
                    completion?(.showAlert(AlertyHelper.alert(title: "Alert!", message: "Failed attempting to update albums after doing the move.")))
                    return
                }
                
                // Hold off on the refresh until the user confirms. It looks like when the move empties the album, and the empty album state shows up, this otherwise removes this alert.
                
                let cancel = SwiftUI.Alert.Button.cancel(Text("OK")) {
                    self.refreshAlbums()
                }

                let alert = SwiftUI.Alert(title: Text("Success!"), message: Text("Look in the other album for your moved \(itemTerm)."), dismissButton: cancel)
                
                completion?(.dismissAndThenShow(alert))
                return
                
            case .currentUploads:
                completion?(.showAlert(AlertyHelper.alert(title: "Alert!", message: "There were uploads in progress-- Please try your move again later.")))
                
            case .currentDeletions:
                completion?(.showAlert(AlertyHelper.alert(title: "Alert!", message: "There were deletions in progress-- Please try your move again later.")))
                
            case .failedWithNotAllOwnersInTarget:
                completion?(.showAlert(AlertyHelper.alert(title: "Alert!", message: "Your move could not be completed because some of the item owners are not in the destination album.")))
            
            case .failedWithUserConstraintNotSatisfied:
                completion?(.showAlert(AlertyHelper.alert(title: "Alert!", message: "Your move could not be completed because some of the item commenters are not in the destination album.")))
                
            case .error(let error):
                logger.error("Album item move: \(String(describing: error))")
                completion?(.showAlert(AlertyHelper.alert(title: "Alert!", message: "There was an unknown error when trying to do your item move.")))
            }
        }
    }
}
