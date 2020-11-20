
import Foundation
import iOSShared
import iOSBasics

/* Implements a strategy for deciding which files need to be downloaded.
    a) Don't download more than a fixed number of files at one time.
*/

class Downloader {
    static let session = Downloader()
    
    private init() {}
    
    // Something very simple to begin with. Just look for files that need downloading and start the downloads.
    func start(sharingGroupUUID: UUID) {
        DispatchQueue.main.async { [weak self] in
            self?._start(sharingGroupUUID: sharingGroupUUID)
        }
    }
    
    private func _start(sharingGroupUUID: UUID) {
        let downloads:[DownloadObject]
                
        do {
            downloads = try Services.session.syncServer.objectsNeedingDownload(sharingGroupUUID: sharingGroupUUID)
        } catch let error {
            logger.error("Downloader: \(error)")
            return
        }
        
        for object in downloads {            
            let files = object.downloads.map { FileToDownload(uuid: $0.uuid, fileVersion: $0.fileVersion) }
            let downloadObject = ObjectToDownload(fileGroupUUID: object.fileGroupUUID, downloads: files)

            do {
                try Services.session.syncServer.queue(download: downloadObject)
            } catch let error {
                logger.error("Downloader: \(error)")
                return
            }
        }
    }
}
