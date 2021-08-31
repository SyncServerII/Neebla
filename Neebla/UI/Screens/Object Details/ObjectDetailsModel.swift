
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
    var mediaItemAttributesFileModel: ServerFileModel?
    
    init(object: ServerObjectModel) {
        try? object.debugOutput()

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
        
        mediaItemAttributesFileModel = try? ServerFileModel.getFileFor(fileLabel: FileLabels.mediaItemAttributes, withFileGroupUUID: object.fileGroupUUID)
        badgeSelected = mediaItemAttributesFileModel?.badge ?? .none

        // Create a new media attribute items file on demand. https://github.com/SyncServerII/Neebla/issues/16
        if mediaItemAttributesFileModel == nil {
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
                    mediaItemAttributesFileModel = fileModel
                }
                // Else: We have it. Don't create it.
            } catch let error {
                logger.error("\(error)")
                modelInitialized = false
                return
            }
        }
        
        modelInitialized = success
        
        if success && object.new {
            do {
                // This is a bit tricky. The object is new, but if the user can't view the related files we probably shouldn't mark it as not new.
                if try object.allFilesDownloaded() {
                    try markAsNotNew(object: object)
                }
                // Else: Some files remain to be downloaded. I'm just going to take the simple route for now let the user try viewing the item again to reset the `new` flag.
            } catch let error {
                logger.error("\(error)")
                success = false
            }
        }
    }
    
    // Assumes that `object.new` is true
    private func markAsNotNew(object: ServerObjectModel) throws {
        guard let mediaItemAttributesFileModel = mediaItemAttributesFileModel else {
            return
        }
        
        object.new = false
        try object.update(setters: ServerObjectModel.newField.description <- false)
        object.postNewUpdateNotification()
        
        guard let userId = Services.session.userId else {
            return
        }
        
        let encoder = JSONEncoder()
        let keyValue = KeyValue.notNew(userId: "\(userId)", used: true)
        let data = try encoder.encode(keyValue)

        // No one else needs to be informed about this user having seen a media item.
        let file = FileUpload.informNoOne(fileLabel: FileLabels.mediaItemAttributes, dataSource: .data(data), uuid: mediaItemAttributesFileModel.fileUUID)
        
        let upload = ObjectUpload(objectType: object.objectType, fileGroupUUID: mediaItemAttributesFileModel.fileGroupUUID, sharingGroupUUID: object.sharingGroupUUID, uploads: [file])
        try Services.session.syncServer.queue(upload: upload)        
    }
    
    func selectBadge(newBadgeSelection: MediaItemBadge) throws {
        guard badgeSelected != newBadgeSelection,
            let mediaItemAttributesFileModel = mediaItemAttributesFileModel else {
            return
        }

        badgeSelected = newBadgeSelection
        
        try mediaItemAttributesFileModel.update(setters: ServerFileModel.badgeField.description <- badgeSelected)
        mediaItemAttributesFileModel.badge = badgeSelected
        mediaItemAttributesFileModel.postBadgeUpdateNotification()
        
        guard let userId = Services.session.userId else {
            return
        }
        
        let encoder = JSONEncoder()
        let keyValue = KeyValue.badge(userId: "\(userId)", code: badgeSelected.rawValue)
        let data = try encoder.encode(keyValue)

        // I was using `forOthers` because the UI allows others to see self's badges. See https://github.com/SyncServerII/Neebla/issues/19. However, testers didn't like this! So, using `informNoOne` now.
        let file = FileUpload.informNoOne(fileLabel: FileLabels.mediaItemAttributes, dataSource: .data(data), uuid: mediaItemAttributesFileModel.fileUUID)
        
        let upload = ObjectUpload(objectType: object.objectType, fileGroupUUID: mediaItemAttributesFileModel.fileGroupUUID, sharingGroupUUID: object.sharingGroupUUID, uploads: [file])
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
