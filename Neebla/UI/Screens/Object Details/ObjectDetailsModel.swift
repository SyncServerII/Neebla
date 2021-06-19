
import Foundation
import iOSShared
import SQLite
import Combine
import SwiftUI
import ChangeResolvers
import iOSBasics

class ObjectDetailsModel: ObservableObject {
    let object: ServerObjectModel
    private(set) var objectTypeDisplayName:String?
    var mediaTitle: String?
    @Published var modelInitialized: Bool
    @Published var badgeSelected: MediaItemBadge = .none
    var badgeModel: ServerFileModel?
    
    init(object: ServerObjectModel) {
#if DEBUG
        try? object.debugOutput()
#endif
        self.object = object
        
        var success = true
        
        if let displayName = AnyTypeManager.session.displayName(forObjectType: object.objectType) {
            objectTypeDisplayName = displayName
        }
        else {
            logger.error("Could not get display name for objectType: \(object.objectType)")
            success = false
        }
        
        do {
            mediaTitle = try Comments.displayableMediaTitle(for: object)
        } catch let error {
            logger.error("\(error)")
            success = false
        }
        
        /* Workaround for early version of app, when the title was stored in the app meta data for images.
         */
        if mediaTitle == nil {
            do {
                mediaTitle = try OldAppImage.getTitle(object: object)
            } catch let error {
                logger.error("OldAppImage.getTitle: \(error)")
            }
        }
        
        badgeModel = try? ServerFileModel.getFileFor(fileLabel: FileLabels.mediaItemAttributes, withFileGroupUUID: object.fileGroupUUID)
        badgeSelected = badgeModel?.badge ?? .none

        // Create a new media attribute items file on demand. https://github.com/SyncServerII/Neebla/issues/16
        if badgeModel == nil {
            // Do our best to make sure that this means we actually don't yet have a media item attributes file.
            do {
                guard let fileGroupAttr = try Services.session.syncServer.fileGroupAttributes(forFileGroupUUID: object.fileGroupUUID) else {
                    logger.error("ObjectDetailsModel: Don't have file group!!")
                    modelInitialized = false
                    return
                }
                
                guard let objectType = ObjectType(rawValue: object.objectType) else {
                    logger.error("ObjectDetailsModel: Could not convert objectType")
                    modelInitialized = false
                    return
                }

                let filter = fileGroupAttr.files.filter {$0.fileLabel == FileLabels.mediaItemAttributes}
                if filter.count == 0 {
                    let fileUUID = UUID()
                    let fileModel = try MediaItemAttributes.queueUpload(fileUUID: fileUUID, fileGroupUUID: object.fileGroupUUID, sharingGroupUUID: object.sharingGroupUUID, objectType: objectType)
                    badgeModel = fileModel
                }
                // Else: We have it. Don't create it.
            } catch let error {
                logger.error("\(error)")
                modelInitialized = false
                return
            }
        }
        
        modelInitialized = success
    }
    
    func selectBadge(newBadgeSelection: MediaItemBadge) throws {
        guard badgeSelected != newBadgeSelection,
            let badgeModel = badgeModel else {
            return
        }

        badgeSelected = newBadgeSelection
        
        try badgeModel.update(setters: ServerFileModel.badgeField.description <- badgeSelected)
        badgeModel.badge = badgeSelected
        badgeModel.postBadgeUpdateNotification()
        
        guard let userId = Services.session.userId else {
            return
        }
        
        let encoder = JSONEncoder()
        let keyValue = KeyValue.badge(userId: "\(userId)", code: badgeSelected.rawValue)
        let data = try encoder.encode(keyValue)

        // This at least currently is not `FileUpload.forOthers` because the UI currently doesn't allow others to see self's badges. See https://github.com/SyncServerII/Neebla/issues/19
        let file = FileUpload.informNoOne(fileLabel: FileLabels.mediaItemAttributes, dataSource: .data(data), uuid: badgeModel.fileUUID)
        
        let upload = ObjectUpload(objectType: object.objectType, fileGroupUUID: badgeModel.fileGroupUUID, sharingGroupUUID: object.sharingGroupUUID, uploads: [file])
        try Services.session.syncServer.queue(upload: upload)        
    }
    
    private func deleteObject() -> Bool {
        do {
            let pushNotificationText = try PushNotificationMessage.forDeletion(of: object)

            // Do the SyncServer call first; it's the most likely to fail of these two.
            try Services.session.syncServer.queue(objectDeletion: object.fileGroupUUID, pushNotificationMessage: pushNotificationText)
            // The actual local deletion of files occurs after the deletion request is completed on the server, and the next index update occurs.
            try object.update(setters: ServerObjectModel.deletedField.description <- true)
        } catch let error {
            logger.error("\(error)")
            return false
        }
        
        return true
    }
    
    func promptForDeletion(dismiss: @escaping ()->()) {
        guard modelInitialized else {
            logger.error("promptForDeletion: Model not initialized")
            return
        }
        
        let displayName = objectTypeDisplayName ?? "item"
        
        let alert = AlertyHelper.customAction(
            title: "Delete?",
            message: "Really delete this \(displayName)?",
            actionButtonTitle: "Delete",
            action: {
                if self.deleteObject() {
                    dismiss()
                }
            },
            cancelTitle: "Cancel")
        showAlert(alert)
    }
}
