//
//  MovieItemProvider.swift
//  Neebla
//
//  Created by Christopher G Prince on 10/25/21.
//

import SwiftUI
import ServerShared
import iOSShared
import AVKit

class MovieItemProvider: SXItemProvider {
    enum MovieItemProviderError: Error, UserDisplayable {
        case cannotGetLivePhoto
        case failedCreatingURL
        case couldNotGetMovie
        case bizzareWrongType
        case couldNotConvertToJPEG
        case badSize
        case movieIsTooBig
        case couldNotGetSettings
        
        var userDisplayableMessage: (title: String, message: String)? {
            if self == .badSize {
                return MovieItemProviderError.badSize
            }
            if self == .movieIsTooBig {
                return MovieItemProviderError.movieTooBig
            }
            return nil
        }
    }
    
    // static let movieUTI = "public.movie"
    // Using "quicktime" here in the hopes that that means .mov format only.
    static let movieUTI = "com.apple.quicktime-movie"
    
    var assets: UploadableMediaAssets {
        return movieAssets
    }

    private let movieAssets: MovieObjectTypeAssets
    
    required init(assets: MovieObjectTypeAssets) {
        self.movieAssets = assets
    }
    
    static func canHandle(item: NSItemProvider) -> Bool {
        let conformsToMovie = item.hasItemConformingToTypeIdentifier(movieUTI)
        let canHandle = conformsToMovie
        return canHandle
    }
    
    static func create(item: NSItemProvider, completion: @escaping (Result<SXItemProvider, Error>) -> ()) -> Any? {

        _ = getMediaAssets(item: item) { result in
            switch result {
            case .success(let assets):
                guard let assets = assets as? MovieObjectTypeAssets else {
                    // Should *not* get here. Just for safekeeping.
                    completion(.failure(MovieItemProviderError.bizzareWrongType))
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
        
        return item.loadFileRepresentation(forTypeIdentifier: movieUTI) { (url, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let url = url else {
                completion(.failure(MovieItemProviderError.couldNotGetMovie))
                return
            }

            completion(getMediaAssets(from: url))
        }
    }
    
    static func create(from content: ItemProviderContent) -> Result<UploadableMediaAssets, Error>? {
        guard case .movie(let url) = content else {
            return nil
        }
        
        return getMediaAssets(from: url)
    }
    
    private static func getMediaAssets(from url: URL) -> Result<UploadableMediaAssets, Error> {

        // What is the size of the file? We're imposing system limits on the sizes of movies.
        let resourceValues: URLResourceValues

        do {
            resourceValues = try url.resourceValues(forKeys: [.fileSizeKey])
        } catch let error {
            return .failure(error)
        }
        
        guard let fileSize = resourceValues.fileSize else {
            return .failure(MovieItemProviderError.badSize)
        }
        
        guard fileSize <= Services.session.serverInterface.config.maxFileSizeBytes else {
            return .failure(MovieItemProviderError.movieIsTooBig)
        }

        // `loadFileRepresentation` removes the file it provides, after the completion handler returns. We need to copy it.
        
        let movieFileCopy:URL
        
        let tempDir = Files.getDocumentsDirectory().appendingPathComponent( LocalFiles.temporary)
        
        do {
            movieFileCopy = try Files.createTemporary(withPrefix: "movie", andExtension: "mov", inDirectory: tempDir, create: false)
            try FileManager.default.copyItem(at: url, to: movieFileCopy)
        } catch let error {
            logger.error("Could not create url: error: \(error)")
            return .failure(MovieItemProviderError.failedCreatingURL)
        }

        guard let jpegQuality = try? SettingsModel.jpegQuality(db: Services.session.db) else {
            logger.error("Could not get settings.")
            return .failure(MovieItemProviderError.couldNotGetSettings)
        }
        
        let thumbnailFile:URL
        
        do {
            let image = try videoThumbnail(video: movieFileCopy)
            thumbnailFile = try Files.createTemporary(withPrefix: "thumbnail", andExtension: MimeType.jpeg.fileNameExtension, inDirectory: tempDir, create: false)
        
            guard let jpegData = image.jpegData(compressionQuality: jpegQuality) else {
                return .failure(MovieItemProviderError.couldNotConvertToJPEG)
            }
        
            try jpegData.write(to: thumbnailFile)
        } catch let error {
            logger.error("Failed generating movie thumbnail: \(error)")
            return .failure(error)
        }
        
        let assets = MovieObjectTypeAssets(thumbnailFile: thumbnailFile, movieFile: movieFileCopy)
        return .success(assets)
    }
    
    // Adapted from https://stackoverflow.com/questions/32680526/display-a-preview-image-from-a-video-swift
    private static func videoThumbnail(video: URL) throws -> UIImage {
        let asset = AVURLAsset(url: video)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        let timestamp = CMTime(seconds: 1, preferredTimescale: 60)
        let imageRef = try generator.copyCGImage(at: timestamp, actualTime: nil)
        return UIImage(cgImage: imageRef)
    }

    func preview(for config: IconConfig) -> AnyView {
        return AnyView(
            GenericImageIcon(model:
                GenericImageIcon.setupModel(.url(self.movieAssets.thumbnailFile), iconSize: config.iconSize),
                    config: config)
        )
    }
    
    func upload(toAlbum sharingGroupUUID: UUID) throws {
        try MovieObjectType.uploadNewObjectInstance(assets: movieAssets, sharingGroupUUID: sharingGroupUUID)
    }
}
