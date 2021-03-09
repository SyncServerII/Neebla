
import SQLite
import Foundation
import ServerShared
import iOSShared
import iOSBasics

class AlbumModel: DatabaseModel, ObservableObject, Equatable, Hashable {
    enum AlbumModelError: Error {
        case noSharingGroupUUID
        case noObject
    }
    
    let db: Connection
    var id: Int64!
    
    static let sharingGroupUUIDField = Field("sharingGroupUUID", \M.sharingGroupUUID)
    @Published var sharingGroupUUID: UUID

    static let untitledAlbumName = "Untitled Album"
    static let albumNameField = Field("albumName", \M.albumName)
    @Published var albumName: String?
    
    static let permissionField = Field("permission", \M.permission)
    var permission: Permission

    // This is for when the album itself is deleted. Not for just when the user is removed from the album.
    static let deletedField = Field("deleted", \M.deleted)
    var deleted: Bool

    // If this is true, indicates some items need downloading for album.
    static let needsDownloadField = Field("needsDownload", \M.needsDownload)
    var needsDownload: Bool
    
    // Fires when the needsDownload of a AlbumModel changes. The `userInfo` of the notification received contains one key/value pair:
    //      sharingGroupUUIDField.fieldName : sharing group UUID
    // Use the method `getAlbumModel` below to obtain the updated AlbumModel given this notification.
    static let needsDownloadUpdate = NSNotification.Name("AlbumModel.needsDownload.update")
    
    // This serves as a kind of serial number for an album. It is the most recent date of any item in the `contentsSummary` for the sharing group.
    static let mostRecentDateField = Field("mostRecentDate", \M.mostRecentDate)
    var mostRecentDate: Date?
    
    init(db: Connection,
        id: Int64! = nil,
        sharingGroupUUID: UUID,
        albumName: String?,
        permission: Permission,
        deleted: Bool = false,
        needsDownload: Bool = false,
        mostRecentDate: Date? = nil) throws {

        self.db = db
        self.id = id
        self.sharingGroupUUID = sharingGroupUUID
        self.albumName = albumName
        self.permission = permission
        self.deleted = deleted
        self.needsDownload = needsDownload
        self.mostRecentDate = mostRecentDate
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: AlbumModel, rhs: AlbumModel) -> Bool {
        return lhs.id == rhs.id &&
            lhs.sharingGroupUUID == rhs.sharingGroupUUID &&
            lhs.albumName == rhs.albumName &&
            lhs.permission == rhs.permission &&
            lhs.deleted == rhs.deleted &&
            lhs.needsDownload == rhs.needsDownload &&
            lhs.mostRecentDate == rhs.mostRecentDate
    }
    
    // MARK: DatabaseModel
    
    static func createTable(db: Connection) throws {
        try startCreateTable(db: db) { t in
            t.column(idField.description, primaryKey: true)
            t.column(sharingGroupUUIDField.description, unique: true)
            t.column(albumNameField.description)
            t.column(permissionField.description)
            t.column(deletedField.description)
            t.column(needsDownloadField.description)
            t.column(mostRecentDateField.description)
        }
    }
    
    static func rowToModel(db: Connection, row: Row) throws -> AlbumModel {
        return try AlbumModel(db: db,
            id: row[Self.idField.description],
            sharingGroupUUID: row[Self.sharingGroupUUIDField.description],
            albumName: row[Self.albumNameField.description],
            permission: row[Self.permissionField.description],
            deleted: row[Self.deletedField.description],
            needsDownload: row[Self.needsDownloadField.description],
            mostRecentDate: row[Self.mostRecentDateField.description]
        )
    }
    
    func insert() throws {
        try doInsertRow(db: db, values:
            Self.sharingGroupUUIDField.description <- sharingGroupUUID,
            Self.albumNameField.description <- albumName,
            Self.permissionField.description <- permission,
            Self.deletedField.description <- deleted,
            Self.needsDownloadField.description <- needsDownload,
            Self.mostRecentDateField.description <- mostRecentDate
        )
    }
}

extension Array where Element == iOSBasics.SharingGroup.FileGroupSummary {
    // Get the most recent date from all `FileGroupSummary`'s.
    func mostRecentDate() -> Date? {
        var current:Date!
        
        for summary in self {
            if let curr = current {
                current = Swift.max(curr, summary.mostRecentDate)
            }
            else {
                current = summary.mostRecentDate
            }
        }
        
        return current
    }
}

extension AlbumModel {
    // If `contentsSummary`'s are present in `sharingGroup`, they will be used to update.
    static func upsertSharingGroup(db: Connection, sharingGroup: iOSBasics.SharingGroup) throws {
        if let albumModel = try AlbumModel.fetchSingleRow(db: db, where: AlbumModel.sharingGroupUUIDField.description == sharingGroup.sharingGroupUUID) {
            if sharingGroup.sharingGroupName != albumModel.albumName {
                try albumModel.update(setters:
                    AlbumModel.albumNameField.description <- sharingGroup.sharingGroupName)
            }

            if sharingGroup.deleted {
                try albumModel.update(setters:
                    AlbumModel.deletedField.description <- sharingGroup.deleted,
                    AlbumModel.needsDownloadField.description <- false)
                try albumDeletionCleanup(db: db, sharingGroupUUID: sharingGroup.sharingGroupUUID)
                albumModel.postNeedsDownloadUpdateNotification()
            }
            else if let contentsSummary = sharingGroup.contentsSummary {
                guard let idDate = contentsSummary.mostRecentDate() else {
                    return
                }
                
                var needsUpdate = false
                
                if let albumModelMostRecentDate = albumModel.mostRecentDate {
                    if idDate > albumModelMostRecentDate {
                        needsUpdate = true
                    }
                }
                else {
                    needsUpdate = true
                }
                
                guard needsUpdate else {
                    return
                }
                
                try albumModel.update(setters:
                    AlbumModel.mostRecentDateField.description <- idDate)
                        
                // For each file group, check if the server has more recent info. If so, we need to set the `needsDownload` flag.
                for fileGroup in contentsSummary {
                    if try fileGroup.serverHasUpdate(db: db) {
                        if !albumModel.needsDownload {
                            try albumModel.update(setters:
                                AlbumModel.needsDownloadField.description <- true)
                            albumModel.postNeedsDownloadUpdateNotification()
                        }
                        break
                    }
                }
            }
        }
        else {
            let model = try AlbumModel(db: db, sharingGroupUUID: sharingGroup.sharingGroupUUID, albumName: sharingGroup.sharingGroupName, permission: sharingGroup.permission, deleted: sharingGroup.deleted)
            try model.insert()
            
            if !sharingGroup.deleted,
                let contentsSummary = sharingGroup.contentsSummary,
                contentsSummary.count > 0 {
                try model.update(setters:
                    AlbumModel.needsDownloadField.description <- true)
                model.postNeedsDownloadUpdateNotification()
            }
        }
    }
    
    // If `contentsSummary` is present in SharingGroup's, they will be updated.
    static func upsertSharingGroups(db: Connection, sharingGroups: [iOSBasics.SharingGroup]) throws {
    
        // First, need to deal with case of albums that we have locally but which are not listed on server. Those have been deleted.
        let localAlbums = try AlbumModel.fetch(db: db)
        
        for localAlbum in localAlbums {
            // Is this local album on the server?
            let onServer = sharingGroups.filter {$0.sharingGroupUUID == localAlbum.sharingGroupUUID}.count == 1
            if !onServer {
                // Not on server: Remove it locally.
                try localAlbum.update(setters: AlbumModel.deletedField.description <- true)
                try albumDeletionCleanup(db: db, sharingGroupUUID: localAlbum.sharingGroupUUID)
            }
        }
        
        // Second, update albums on the basis of the sharing groups.
        for sharingGroup in sharingGroups {
            try upsertSharingGroup(db: db, sharingGroup: sharingGroup)
        }
    }
    
    /* After marking an album as deleted, do related cleanup:
        Remove all ServerObjectModel’s, and all ServerFileModel's.
            Remove all files associated with these.
    */
    static func albumDeletionCleanup(db: Connection, sharingGroupUUID: UUID) throws {
        let objectModelsForAlbum = try ServerObjectModel.fetch(db: db, where: AlbumModel.sharingGroupUUIDField.description == sharingGroupUUID)
        for objectModel in objectModelsForAlbum {
            let fileModels = try ServerFileModel.fetch(db: db, where: ServerFileModel.fileGroupUUIDField.description == objectModel.fileGroupUUID)
            for fileModel in fileModels {
                try fileModel.removeFile()
                try fileModel.delete()
            }
            try objectModel.delete()
        }
    }
    
    func postNeedsDownloadUpdateNotification() {
        NotificationCenter.default.post(name: Self.needsDownloadUpdate, object: nil, userInfo: [
            AlbumModel.sharingGroupUUIDField.fieldName : sharingGroupUUID,
        ])
    }
    
    // Use this when receiving a `needsDownloadUpdate` notification.
    // If the sharingGroupUUID of the received notification doesn't match that given in the expectingSharingGroupUUID, nil is returned.
    static func getAlbumModel(db: Connection, from notification: Notification, expectingSharingGroupUUID: UUID) throws -> AlbumModel? {
        guard let sharingGroupUUID = notification.userInfo?[sharingGroupUUIDField.fieldName] as? UUID else {
            throw AlbumModelError.noSharingGroupUUID
        }
        
        guard expectingSharingGroupUUID == sharingGroupUUID else {
            return nil
        }
        
        guard let albumModel = try AlbumModel.fetchSingleRow(db: db, where: AlbumModel.sharingGroupUUIDField.description == sharingGroupUUID) else {
            throw AlbumModelError.noObject
        }
        
        return albumModel
    }
}
