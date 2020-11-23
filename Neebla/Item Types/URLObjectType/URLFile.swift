
import Foundation
import iOSShared
import SMLinkPreview

class URLFile {
    enum URLFileError: Error {
        case couldNotConvertURLDataToString
    }
    
    struct URLFileContents {
        let url: URL
        
        // Title is optional because it's possible a title wasn't obtained in the LinkPreview
        let title: String?
        
        // Optional because there may have been no image obtained in the LinkPreview.
        let imageType:LinkPreview.LoadedImage.ImageType?
    }
    
    private static let maxNumberLinesInURLFile = 4
    private static let minNumberLinesInURLFile = 2
    private static let URLKey = "URL"
    private static let titleKey = "TITLE"
    private static let imageTypeKey = "IMAGETYPE"

    // Writes a properly formatted url file.
    static func create(contents: URLFileContents, localFile: URL) throws {
        // The format of .url files seems weakly defined. I'm extending it with a `TITLE`. Hopefully these files can (continue to) launch both on MacOS and Windows. No clue about Linux systems...
        // e.g., see http://www.lyberty.com/encyc/articles/tech/dot_url_format_-_an_unofficial_guide.html
        var mediaURLContents =
            "[InternetShortcut]\n" +
            "\(URLKey)=\(contents.url)\n"
        
        if let title = contents.title {
            mediaURLContents += "\(titleKey)=\(title)\n"
        }
        
        if let imageType = contents.imageType {
            mediaURLContents += "\(imageTypeKey)=\(imageType.rawValue)\n"
        }
        
        guard let data = mediaURLContents.data(using: .utf8) else {
            logger.error("Could not convert url data into string.")
            throw URLFileError.couldNotConvertURLDataToString
        }
        
        try data.write(to: localFile)
    }

    static func parse(localURLFile: URL) -> URLFileContents? {
        guard let fileData = try? Data(contentsOf: localURLFile) else {
            return nil
        }
        
        guard let fileString = String(data: fileData, encoding: .utf8) else {
            return nil
        }
        
        var lines = fileString.split(separator: "\n")
        
        guard lines.count >= minNumberLinesInURLFile,
            lines.count <= maxNumberLinesInURLFile else {
            return nil
        }
        
        // Remove the "[InternetShortcut]"
        lines.removeFirst()
        
        var contents = [String: String]()
        for line in lines {
            let result = line.split(separator: "=", maxSplits: 1).map({String($0)})
            guard result.count == 2 else {
                return nil
            }
            
            contents[result[0]] = result[1]
        }
        
        guard let contentURLString = contents[URLKey],
            let contentsURL = URL(string: contentURLString) else {
            return nil
        }
        
        let contentTitle = contents[titleKey]
        
        var contentImageType: LinkPreview.LoadedImage.ImageType?
        if let contentImageTypeString = contents[imageTypeKey] {
            contentImageType = LinkPreview.LoadedImage.ImageType(rawValue: contentImageTypeString)
        }
        
        return URLFileContents(url: contentsURL, title: contentTitle, imageType: contentImageType)
    }
}
