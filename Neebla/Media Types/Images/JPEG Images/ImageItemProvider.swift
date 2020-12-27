
import SwiftUI
import ServerShared
import iOSShared

class ImageItemProvider: SXItemProvider {
    static let imageIdentifier = "public.jpeg"

    enum ImageItemProviderError: Error {
        case cannotGetImage
        case bizzareWrongType
    }

    private let imageURL: URL
    private let image:UIImage
    
    required init(url: URL) throws {
        self.imageURL = url
        let data = try Data(contentsOf: imageURL)
        guard let image = UIImage(data: data) else {
            throw ImageItemProviderError.cannotGetImage
        }
        self.image = image
    }
    
    static func canHandle(item: NSItemProvider) -> Bool {
        return item.hasItemConformingToTypeIdentifier(imageIdentifier)
    }

    static func create(item: NSItemProvider, completion:@escaping (Result<SXItemProvider, Error>)->()) {
        getMediaAssets(item: item) { result in
            switch result {
            case .success(let assets):
                guard let assets = assets as? ImageObjectTypeAssets else {
                    // Should *not* get here. Just for safekeeping.
                    completion(.failure(ImageItemProviderError.bizzareWrongType))
                    return
                }
                
                do {
                    let obj = try Self.init(url: assets.jpegFile)
                    completion(.success(obj))
                } catch let error {
                    completion(.failure(error))
                }
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    static func getMediaAssets(item: NSItemProvider, completion: @escaping (Result<UploadableMediaAssets, Error>) -> ()) {
        let tempDir = Files.getDocumentsDirectory().appendingPathComponent(LocalFiles.temporary)

        item.loadFileRepresentation(forTypeIdentifier: Self.imageIdentifier) { (url, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let url = url else {
                completion(.failure(ImageItemProviderError.cannotGetImage))
                return
            }
            
            // The file we get back isn't one we can do just anything with. E.g., we can't use the FileManager replaceItemAt method with it. Copy it.
            
            let imageFileCopy:URL
            do {
                imageFileCopy = try Files.createTemporary(withPrefix: "image", andExtension: FilenameExtensions.jpegImage, inDirectory: tempDir, create: false)
                try FileManager.default.copyItem(at: url, to: imageFileCopy)
            } catch let error {
                logger.error("\(error)")
                completion(.failure(ImageItemProviderError.cannotGetImage))
                return
            }
                
            let assets = ImageObjectTypeAssets(jpegFile: imageFileCopy)
            completion(.success(assets))
        }
    }
    
    var preview: AnyView {
        AnyView(
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
        )
    }
    
    func upload(toAlbum sharingGroupUUID: UUID) throws {
    }
}
