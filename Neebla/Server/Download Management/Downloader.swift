
import Foundation
import iOSShared
import iOSBasics
import SQLite

// Implements a relatively simple strategy for deciding which files need to be downloaded.

class Downloader {
    private let maxNumberActiveDownloads: UInt = 10
    
    // Size of queue beyond those actively downloading
    let priorityQueueAdditional: UInt = 100

    let priorityQueueLength: UInt

    static let checkDownloadsInterval: TimeInterval = 4
    static let session = Downloader()
    
    // Keep track of the N most recently accessed objects. i.e., objects viewed by the user. When we're ready to trigger downloads, use these. A consequence of this strategy is that if the user doesn't move around in the UI, more downloads may not be triggered because they were not accessed.
    // We make the `priorityQueue` larger than the actual number of objects we allow to download so we can queue up additional objects.
    private let priorityQueue:PriorityQueue<ServerObjectModel>
    
    // To periodically check for downloads.
    private var timer: Timer!
    
    private init() {
        priorityQueueLength = maxNumberActiveDownloads + priorityQueueAdditional
        priorityQueue = try! PriorityQueue<ServerObjectModel>(maxLength: priorityQueueLength)
        timer = Timer.scheduledTimer(withTimeInterval: Self.checkDownloadsInterval, repeats: true) { [weak self] _ in
            self?.checkDownloads()
        }
    }
    
    // The object was accessed-- i.e., presented to the user in the UI. (Not yet determined if any of the files in the object need downloading).
    func objectAccessed(object: ServerObjectModel) {
        do {
            guard let _ = try Services.session.syncServer.objectNeedsDownload(fileGroupUUID: object.fileGroupUUID, includeGone: true) else {
                return
            }
            
            Synchronized.block(self) {
                priorityQueue.add(object: object)
            }
            
            logger.debug("priorityQueue.current.count: \(priorityQueue.current.count)")
        } catch let error {
            logger.error("\(error)")
        }
    }
    
    // Process:
    //  1) Any objects in the queue
    //  2) If yes, how many objects currently downloading?
    //  3) If capacity available, start more.
    private func checkDownloads() {
        do {
            try checkDownloadsHelper()
        }
        catch let error {
            logger.error("checkDownloads: \(error)")
        }
    }
    
    private func checkDownloadsHelper() throws {
        var downloadsToStart = [ServerObjectModel]()

        try Synchronized.block(self) {
            guard priorityQueue.current.count > 0 else {
                return
            }
            
            let numberDownloadsQueued:Int
            
            numberDownloadsQueued = try Services.session.syncServer.numberQueued(.download)
            
            guard numberDownloadsQueued < maxNumberActiveDownloads else {
                logger.info("Not starting more downloads: Currently at max.")
                return
            }
            
            let maxNumberDownloadsToStart = maxNumberActiveDownloads - UInt(numberDownloadsQueued)
            let numberDownloadsToStart = min(maxNumberDownloadsToStart, UInt(priorityQueue.current.count))
            
            downloadsToStart = try priorityQueue.getInitial(numberDownloadsToStart)
        }
        
        guard downloadsToStart.count > 0 else {
            return
        }
        
        for objectModel in downloadsToStart {
            // Use sync server interface, just to make it simpler to get info for download.
            guard let downloadable = try Services.session.syncServer.objectNeedsDownload(fileGroupUUID: objectModel.fileGroupUUID, includeGone: true) else {
                logger.debug("No objectNeedsDownload")
                continue
            }

            let files = downloadable.downloads.map { FileToDownload(uuid: $0.uuid, fileVersion: $0.fileVersion) }
            let downloadObject = ObjectToDownload(fileGroupUUID: downloadable.fileGroupUUID, downloads: files)
            
            try Services.session.syncServer.queue(download: downloadObject)
            logger.info("Started download for object: \(downloadObject.fileGroupUUID)")
            
            // Update the dowloadStatus of these files to `.downloading`
            
            func downloadingFile(fileUUID: UUID) -> Bool {
                return files.filter( {$0.uuid == fileUUID}).count == 1
            }
            
            let fileModelsForObject = try objectModel.fileModels()
            for fileModel in fileModelsForObject {
                if downloadingFile(fileUUID: fileModel.fileUUID) {
                    try fileModel.update(setters: ServerFileModel.downloadStatusField.description <- .downloading)
                    fileModel.postDownloadStatusUpdateNotification()
                }
            }
        }
    }
}
