
import SQLite
import Foundation
import ServerShared
import iOSShared
import iOSBasics
import ChangeResolvers

class AlbumModel: DatabaseModel, ObservableObject, Equatable, Hashable, Identifiable {
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
    
    // The last time a general sync was done (not album specific).
    // See also https://github.com/SyncServerII/Neebla/issues/15#issuecomment-852567995
    static let lastSyncDateField = Field("lastSyncDate", \M.lastSyncDate)
    var lastSyncDate: Date?
    
    // Fires when the needsDownload of a AlbumModel changes. The `userInfo` of the notification received contains one key/value pair:
    //      sharingGroupUUIDField.fieldName : sharing group UUID
    // Use the method `getAlbumModel` below to obtain the updated AlbumModel given this notification.
    static let needsDownloadUpdate = NSNotification.Name("AlbumModel.needsDownload.update")
    
    // The most recent date of any item in the `contentsSummary` for the sharing group (across both created and update dates). This is updated from a sync *with* a sharing group given.
    static let mostRecentDateField = Field("mostRecentDate", \M.mostRecentDate)
    var mostRecentDate: Date?
    
    init(db: Connection,
        id: Int64! = nil,
        sharingGroupUUID: UUID,
        albumName: String?,
        permission: Permission,
        deleted: Bool = false,
        needsDownload: Bool = false,
        mostRecentDate: Date? = nil,
        lastSyncDate: Date? = nil) throws {

        self.db = db
        self.id = id
        self.sharingGroupUUID = sharingGroupUUID
        self.albumName = albumName
        self.permission = permission
        self.deleted = deleted
        self.needsDownload = needsDownload
        self.mostRecentDate = mostRecentDate
        self.lastSyncDate = lastSyncDate
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
            lhs.mostRecentDate == rhs.mostRecentDate &&
            lhs.lastSyncDate == rhs.lastSyncDate
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
            
            // MIGRATION, 6/1/21
            // t.column(lastSyncDateField.description)
        }
    }
    
    static func migration_2021_6_1(db: Connection) throws {
        try addColumn(db: db, column: lastSyncDateField.description)
        
        // Opt existing users into this-- so all of a sudden lots of albums don't indicate they need download just because they have a nil `lastSyncDate`.
        try DownloadIndicator.updateAlbumLastSyncDates(db: db)
    }
    
    static func allMigrations(db: Connection) throws {
        try migration_2021_6_1(db: db)
    }
    
    static func rowToModel(db: Connection, row: Row) throws -> AlbumModel {
        return try AlbumModel(db: db,
            id: row[Self.idField.description],
            sharingGroupUUID: row[Self.sharingGroupUUIDField.description],
            albumName: row[Self.albumNameField.description],
            permission: row[Self.permissionField.description],
            deleted: row[Self.deletedField.description],
            needsDownload: row[Self.needsDownloadField.description],
            mostRecentDate: row[Self.mostRecentDateField.description],
            lastSyncDate: row[Self.lastSyncDateField.description]
        )
    }
    
    func insert() throws {
        try doInsertRow(db: db, values:
            Self.sharingGroupUUIDField.description <- sharingGroupUUID,
            Self.albumNameField.description <- albumName,
            Self.permissionField.description <- permission,
            Self.deletedField.description <- deleted,
            Self.needsDownloadField.description <- needsDownload,
            Self.mostRecentDateField.description <- mostRecentDate,
            Self.lastSyncDateField.description <- lastSyncDate
        )
    }
}

extension AlbumModel {
    // This reflects the `lastSyncDate` field which is for a generic sync-- i.e., with no sharing group given.
    var lastSyncDateHasExpired: Bool {
        guard let lastSyncDate = lastSyncDate else {
            // No `lastSyncDate`-- this must be a new album.
            return true
        }

        let calendar = Calendar.current
        guard let expiryDate = calendar.date(byAdding: .day, value: ServerConstants.numberOfDaysUntilInformAllButSelfExpiry, to: lastSyncDate) else {
            logger.error("Could not add dates!")
            return false
        }
        
        if Date() >= expiryDate {
            return true
        }
        
        return false
    }

    struct SharingGroupUpdate: OptionSet {
        let rawValue: Int

        static let updateDownloadIndicator = SharingGroupUpdate(rawValue: 1 << 0)
        static let updateMostRecentDate = SharingGroupUpdate(rawValue: 1 << 1)
    }
    
    static func upsertSharingGroup(db: Connection, sharingGroup: iOSBasics.SharingGroup, updateOptions: SharingGroupUpdate) throws {
        let model:AlbumModel
        
        if let albumModel = try AlbumModel.fetchSingleRow(db: db, where: AlbumModel.sharingGroupUUIDField.description == sharingGroup.sharingGroupUUID) {
            model = albumModel
            
            if sharingGroup.sharingGroupName != albumModel.albumName {
                try albumModel.update(setters:
                    AlbumModel.albumNameField.description <- sharingGroup.sharingGroupName)
            }
                        
            // Albums can be deleted or undeleted. Undeletion occurs when a user is removed from an album, then re-added. Making sure to consider both cases.
            if sharingGroup.deleted != albumModel.deleted {
                try albumModel.update(setters:
                    AlbumModel.deletedField.description <- sharingGroup.deleted)
                    
                if sharingGroup.deleted {
                    // Album is newly deleted. We didn't have it recorded as deleted previously.
                    try albumModel.update(setters:
                        AlbumModel.needsDownloadField.description <- false)
                    try albumDeletionCleanup(db: db, sharingGroupUUID: sharingGroup.sharingGroupUUID)
                    albumModel.postNeedsDownloadUpdateNotification()
                }
            }
        }
        else {
            model = try AlbumModel(db: db, sharingGroupUUID: sharingGroup.sharingGroupUUID, albumName: sharingGroup.sharingGroupName, permission: sharingGroup.permission, deleted: sharingGroup.deleted)
            try model.insert()
        }
        
        if updateOptions.contains(.updateDownloadIndicator) {
            try DownloadIndicator.seeIfNeedsDownload(albumModel: model, sharingGroup: sharingGroup)
        }
        
        if updateOptions.contains(.updateMostRecentDate) {
            try DownloadIndicator.updateAlbumMostRecentDate(album: model, sharingGroup: sharingGroup)
        }
    }
    
    static func upsertSharingGroups(db: Connection, sharingGroups: [iOSBasics.SharingGroup], updateOptions: SharingGroupUpdate) throws {
        for sharingGroup in sharingGroups {
            try upsertSharingGroup(db: db, sharingGroup: sharingGroup, updateOptions: updateOptions)
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
            
            // Need to also inform the SyncServer interface-- this is in case the album is ever re-added by user. Possibly this can be done automatically by `iOSBasics`. I.e., when a sharing group is marked as deleted this could possibly be done too. However, the timing is a little tricky. I don't want these to get re-downloaded by accident. Or to have a bunch of errors occur if download attempts are made, since the user isn't in the album any more.
            let files = fileModels.map { NotDownloadedFile(uuid: $0.fileUUID) }
            let object = NotDownloadedObject(sharingGroupUUID: sharingGroupUUID, fileGroupUUID: objectModel.fileGroupUUID, downloads: files)
            try Services.session.syncServer.markAsNotDownloaded(object: object)
        }
    }
    
    // Doesn't send if app is in the background. Make sure receiving uses of this only drive the UI, or can be reconsituted when the app comes back into the foreground.
    func postNeedsDownloadUpdateNotification() {
        guard AppState.session.current == .foreground else {
            return
        }
        
        NotificationCenter.default.post(name: Self.needsDownloadUpdate, object: nil, userInfo: [
            AlbumModel.sharingGroupUUIDField.fieldName : sharingGroupUUID,
        ])
    }
    
    // Use this when receiving a `needsDownloadUpdate` notification.
    static func getSharingGroupUUID(db: Connection, from notification: Notification) throws -> UUID {
        guard let sharingGroupUUID = notification.userInfo?[sharingGroupUUIDField.fieldName] as? UUID else {
            throw AlbumModelError.noSharingGroupUUID
        }
        
        return sharingGroupUUID
    }
    
    // Don't use this for general filtering. Intended only for an exact match.
    static func usesKeyword(_ keyword: String, sharingGroupUUID: UUID, db: Connection) throws -> Bool {
        // Get all ServerObjectModels for album.
        let objectModels = try ServerObjectModel.fetch(db: db, where: ServerObjectModel.sharingGroupUUIDField.description == sharingGroupUUID)
        
        for objectModel in objectModels {
            let keywords = MediaItemAttributes.getKeywords(fromCSV: objectModel.keywords)
            if let contains = keywords?.contains(keyword), contains {
                return true
            }
        }
        
        return false
    }
}
