
import Foundation
import SQLite
import UIKit

class GenericImageModel {
    let fileLabel: String
    
    init(fileLabel: String) {
        self.fileLabel = fileLabel
    }
    
    // Completion handler called async on the main thread.
    func loadImage(fileGroupUUID: UUID, completion:@escaping (UIImage?)->()) {
        guard let fileModels = try? ServerFileModel.getFilesFor(fileGroupUUID: fileGroupUUID, withFileLabel: fileLabel) else {
            return
        }
        
        guard fileModels.count == 1 else {
            completion(nil)
            return
        }
        
        let imageFileModel = fileModels[0]
        
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
