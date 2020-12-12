
import Foundation
import iOSShared

class DeveloperScreenModel: ObservableObject {
    @Published var objects:[ServerObjectModel] = []
    @Published var objectDirectoryFiles:[String] = []
    
    func update() {
        let localObjectsDir = Files.getDocumentsDirectory().appendingPathComponent(
            LocalFiles.objectsDir)
            
        do {
            objects = try ServerObjectModel.fetch(db: Services.session.db)
            logger.debug("localObjectsDir.path: \(localObjectsDir.path)")
            objectDirectoryFiles = try FileManager.default.contentsOfDirectory(atPath: localObjectsDir.path)
        } catch let error {
            logger.error("\(error)")
        }
    }
}
