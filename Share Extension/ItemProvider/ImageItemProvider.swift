
import SwiftUI
import ServerShared

struct ImageItemProvider: ItemProvider {
    let mimeType: MimeType = .jpeg
    
    static let typeIdentifiers = ["public.jpeg"]
    
    var shouldUploadCopy = true
    
    enum ImageItemProviderError: Error {
        case cannotGetImage
    }
    
    let imageURL: URL
    let image:UIImage
    
    init(url: URL) throws {
        self.imageURL = url
        let data = try Data(contentsOf: imageURL)
        guard let image = UIImage(data: data) else {
            throw ImageItemProviderError.cannotGetImage
        }
        self.image = image
    }
    
    var preview: AnyView {
        AnyView(
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
        )
    }
    
    var itemURL: URL {
        return imageURL
    }
}
