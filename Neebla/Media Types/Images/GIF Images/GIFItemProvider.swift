//
//  GIFItemProvider.swift
//  Neebla
//
//  Created by Christopher G Prince on 3/11/21.
//

import SwiftUI
import ServerShared
import iOSShared

class GIFItemProvider: SXItemProvider {
    static let gifUTI = "com.compuserve.gif"

    enum GIFItemProviderError: Error {
        case cannotGetImage
        case bizzareWrongType
        case couldNotConvertToGIF
        case couldNotGetSettings
        case couldNotGetData
        case noImagesInGIF
        case couldNotConvertToJPEG
    }

    var assets: UploadableMediaAssets {
        return gifAssets
    }

    private let gifAssets: GIFObjectTypeAssets
    
    required init(assets: GIFObjectTypeAssets) {
        self.gifAssets = assets
    }
    
    static func canHandle(item: NSItemProvider) -> Bool {
        let canHandle = item.hasItemConformingToTypeIdentifier(gifUTI)
        logger.debug("GIFItemProvider: canHandle: \(canHandle)")
        return canHandle
    }

    static func create(item: NSItemProvider, completion:@escaping (Result<SXItemProvider, Error>)->()) -> Any? {
        _ = getMediaAssets(item: item) { result in
            switch result {
            case .success(let assets):
                guard let assets = assets as? GIFObjectTypeAssets else {
                    // Should *not* get here. Just for safekeeping.
                    completion(.failure(GIFItemProviderError.bizzareWrongType))
                    return
                }
                
                let obj = Self.init(assets: assets)
                completion(.success(obj))
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
        
        return nil
    }

    static func getMediaAssets(item: NSItemProvider, completion: @escaping (Result<UploadableMediaAssets, Error>) -> ()) -> Any? {
        if item.hasItemConformingToTypeIdentifier(gifUTI) {
            return getMediaAsset(item: item, mimeType: GIFObjectTypeAssets.gifMimeType, typeIdentifier: gifUTI, completion: completion)
        }

        // Shouldn't get here.
        return nil
    }
    
    private static func getImageFrom(gifURL: URL, andSaveTo jpegURL: URL) throws {
        guard let gifData = try? Data(contentsOf: gifURL),
            let source =  CGImageSourceCreateWithData(gifData as CFData, nil) else {
            throw GIFItemProviderError.couldNotGetData
        }
        
        let imageCount = CGImageSourceGetCount(source)
        
        guard imageCount > 0 else {
            throw GIFItemProviderError.noImagesInGIF
        }
        
        // Just arbitrarily using the 0th image from the GIF
        guard let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw GIFItemProviderError.noImagesInGIF
        }
        
        let image = UIImage(cgImage: cgImage)

        guard let jpegQuality = try? SettingsModel.jpegQuality(db: Services.session.db) else {
            throw GIFItemProviderError.couldNotGetSettings
        }
        
        guard let jpegData = image.jpegData(compressionQuality: jpegQuality) else {
            throw GIFItemProviderError.couldNotConvertToJPEG
        }

        try jpegData.write(to: jpegURL)
    }
    
    private static func getMediaAsset(item: NSItemProvider, mimeType: MimeType, typeIdentifier: String, completion: @escaping (Result<UploadableMediaAssets, Error>) -> ()) -> Any? {
        let tempDir = Files.getDocumentsDirectory().appendingPathComponent(LocalFiles.temporary)
        item.loadFileRepresentation(forTypeIdentifier: typeIdentifier) { (url, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let url = url else {
                completion(.failure(GIFItemProviderError.cannotGetImage))
                return
            }
            
            // The file we get back isn't one we can do just anything with. E.g., we can't use the FileManager replaceItemAt method with it. Copy it.
            
            let gifFileCopy:URL
            let jpegIcon:URL
            
            do {
                gifFileCopy = try Files.createTemporary(withPrefix: "gif", andExtension: mimeType.fileNameExtension, inDirectory: tempDir, create: false)
                try FileManager.default.copyItem(at: url, to: gifFileCopy)
                
                jpegIcon = try Files.createTemporary(withPrefix: "icon", andExtension: GIFObjectTypeAssets.iconMimeType.fileNameExtension, inDirectory: tempDir, create: false)
                try getImageFrom(gifURL: gifFileCopy, andSaveTo: jpegIcon)
            } catch let error {
                logger.error("\(error)")
                completion(.failure(GIFItemProviderError.cannotGetImage))
                return
            }
                
            let assets = GIFObjectTypeAssets(iconFile: jpegIcon, gifFile: gifFileCopy)
            completion(.success(assets))
        }
        
        return nil
    }
    
    func preview(for config: IconConfig) -> AnyView {
        AnyView(
            GenericImageIcon(.url(gifAssets.iconFile), config: config)
        )
    }
    
    func upload(toAlbum sharingGroupUUID: UUID) throws {
        try GIFObjectType.uploadNewObjectInstance(assets: gifAssets, sharingGroupUUID: sharingGroupUUID)
    }
}
