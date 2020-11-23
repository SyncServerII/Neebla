
import Foundation
import SwiftUI
import SQLite
import iOSShared

class URLIconModel: ObservableObject {
    let maxLengthTitle = 10
    @Published var description: String?
    let object: ServerObjectModel
    
    init(object: ServerObjectModel) {
        self.object = object
    }
    
    private func getFilesFor(fileGroupUUID: UUID) throws -> [ServerFileModel] {
        return try ServerFileModel.fetch(db: Services.session.db, where: ServerFileModel.fileGroupUUIDField.description == fileGroupUUID)
    }
    
    func getDescriptionText() {
        DispatchQueue.global().async {
            let description = self.getDescriptionTextHelper()
            DispatchQueue.main.async {
                self.description = description
            }
        }
    }
    
    func getDescriptionTextHelper() -> String? {
        guard let fileModels = try? getFilesFor(fileGroupUUID: object.fileGroupUUID) else {
            logger.error("Could not get file models!")
            return nil
        }
        
        let filter = fileModels.filter {
            $0.fileLabel == URLObjectType.urlDeclaration.fileLabel
        }
        
        guard filter.count == 1 else {
            logger.error("Not exactly one url file!")
            return nil
        }
        
        guard let urlFile = filter[0].url else {
            logger.error("No url with url file!")
            return nil
        }
        
        guard let contents = URLFile.parse(localURLFile: urlFile) else {
            logger.error("Could not get url file contents!")
            return nil
        }
        
        if let prefix = contents.title?.prefix(maxLengthTitle) {
            return String(prefix)
        }
        else {
            return nil
        }
    }
}
