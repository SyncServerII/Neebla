
import Foundation
import SQLite
import UIKit

class GenericImageIconModel {
    let fileLabel: String
    
    init(fileLabel: String) {
        self.fileLabel = fileLabel
    }

    private func getFilesFor(fileGroupUUID: UUID) throws -> [ServerFileModel] {
        return try ServerFileModel.fetch(db: Services.session.db, where: ServerFileModel.fileGroupUUIDField.description == fileGroupUUID)
    }
    
    // Completion handler called async on the main thread.
    func loadImage(fileGroupUUID: UUID, completion:@escaping (UIImage?)->()) {
        guard let fileModels = try? getFilesFor(fileGroupUUID: fileGroupUUID) else {
            return
        }
        
        let filter = fileModels.filter { $0.fileLabel == fileLabel}
        guard filter.count == 1 else {
            completion(nil)
            return
        }
        
        let imageFileModel = filter[0]
        
        guard let imageURL = imageFileModel.url else {
            completion(nil)
            return
        }
        
        // This first line is a bit of a hack. Unless I have it, at least on the simulator, it take a long time to transition to the "Album Contents" screen. Perhaps when I'm not trying to load the entire image but a scaled, smaller image, this will be faster?
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
            DispatchQueue.global(qos: .background).async {
                if let imageData = try? Data(contentsOf: imageURL),
                    let image = UIImage(data: imageData) {
                    DispatchQueue.main.async {
                        completion(image)
                    }
                }
            }
        }
    }
}
