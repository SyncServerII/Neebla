
import Foundation
import iOSBasics

class CommentUploader {
    // The `fileUUID` references the comment file within the object-- just a convenience. We could get it given the `object` and the file label also.
    static func queueUpload(fileUUID: UUID, comment: Data, object: ServerObjectModel) throws {
        let file = FileUpload(fileLabel: FileLabels.comments, dataSource: .data(comment), uuid: fileUUID)
        let upload = ObjectUpload(objectType: object.objectType, fileGroupUUID: object.fileGroupUUID, sharingGroupUUID: object.sharingGroupUUID, uploads: [file])
        try Services.session.syncServer.queue(upload: upload)
    }
}
