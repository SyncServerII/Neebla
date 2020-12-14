
import Foundation
import iOSShared

class DeveloperScreenModel: ObservableObject {
    @Published var albums:[AlbumModel] = []
    @Published var objects:[ServerObjectModel] = []
    @Published var files:[ServerFileModel] = []
    @Published var objectDirectoryFiles:[String] = []
    
    func update() {
        let localObjectsDir = Files.getDocumentsDirectory().appendingPathComponent(
            LocalFiles.objectsDir)
            
        do {
            objects = try ServerObjectModel.fetch(db: Services.session.db)
            albums = try AlbumModel.fetch(db: Services.session.db)
            files = try ServerFileModel.fetch(db: Services.session.db)
            logger.debug("localObjectsDir.path: \(localObjectsDir.path)")
            objectDirectoryFiles = try FileManager.default.contentsOfDirectory(atPath: localObjectsDir.path)
        } catch let error {
            logger.error("\(error)")
        }
    }
}
