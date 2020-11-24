
import Foundation
import SwiftUI
import SQLite
import iOSShared

class URLModel: ObservableObject {
    let fileLabel = URLObjectType.urlDeclaration.fileLabel
    let maxLengthTitle = 10
    @Published var description: String?
    @Published var contents: URLFile.URLFileContents?
    let object: ServerObjectModel
    
    init(urlObject: ServerObjectModel) {
        self.object = urlObject
    }
    
    private func getFilesFor(fileGroupUUID: UUID) throws -> [ServerFileModel] {
        return try ServerFileModel.fetch(db: Services.session.db, where: ServerFileModel.fileGroupUUIDField.description == fileGroupUUID)
    }
    
    func getContents() {
        DispatchQueue.global().async {
            let contents = self.getContentsHelper()
            DispatchQueue.main.async {
                self.contents = contents
            }
        }
    }
    
    func getDescriptionText() {
        DispatchQueue.global().async {
            let contents = self.getContentsHelper()

            DispatchQueue.main.async {
                if let prefix = contents?.title?.prefix(self.maxLengthTitle) {
                    self.description = String(prefix)
                }
                else {
                    self.description = nil
                }
            }
        }
    }
    
    private func getContentsHelper() -> URLFile.URLFileContents? {
        guard let fileModels = try? getFilesFor(fileGroupUUID: object.fileGroupUUID) else {
            logger.error("Could not get file models!")
            return nil
        }
        
        let filter = fileModels.filter { $0.fileLabel == fileLabel }
        
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
        
        return contents
    }
}
