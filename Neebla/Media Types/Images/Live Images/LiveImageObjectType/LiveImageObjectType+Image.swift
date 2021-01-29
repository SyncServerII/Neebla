
import UIKit
import iOSShared
import CoreServices

extension LiveImageObjectType {
    static let makerAppleDictionary = kCGImagePropertyMakerAppleDictionary as String
    static let kFigAppleMakerNote_AssetIdentifier = "17"

    // Gets the asset ID from the HEIC file, and writes it with JPEG image data to the JPEG output file.
    static func convertHEICImageToJPEG(heicURL: URL, outputJPEGImageURL: URL) throws {
        guard let imageSource = CGImageSourceCreateWithURL(heicURL as CFURL, nil) else {
            throw LiveImageObjectTypeError.imageConversionFailed("Failed with CGImageSourceCreateWithURL")
        }
        
        guard let metadata = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [AnyHashable: Any] else {
            throw LiveImageObjectTypeError.imageConversionFailed("Failed with CGImageSourceCopyPropertiesAtIndex")
        }
        
        guard let appleDictionary = metadata[Self.makerAppleDictionary] as? [AnyHashable: Any] else {
            throw LiveImageObjectTypeError.imageConversionFailed("Could not lookup makerAppleDictionary: \(Self.makerAppleDictionary)")
        }
        
        guard let assetID = appleDictionary[Self.kFigAppleMakerNote_AssetIdentifier] as? String else {
            throw LiveImageObjectTypeError.imageConversionFailed("Could not lookup makerAppleDictionary: \(Self.makerAppleDictionary)")
        }
        
        logger.debug("assetId: \(assetID)")
        
        try convertImageToLivePhotoFormat(heicURL: heicURL, outputJPEGImageURL: outputJPEGImageURL, assetID: assetID)
    }
    
    // Converts an HEIC image into a JPEG Live Photo format. i.e., writes it with the asset id.
    // Adapted from https://github.com/OlegAba/LPLivePhotoGenerator
    private static func convertImageToLivePhotoFormat(heicURL: URL, outputJPEGImageURL: URL, assetID: String) throws {
    
        guard let image = UIImage(contentsOfFile: heicURL.path) else {
            throw LiveImageObjectTypeError.couldNotLoadHEIC
        }
        
        let jpegQuality = try SettingsModel.jpegQuality(db: Services.session.db)
        
        guard let imageData = image.jpegData(compressionQuality: jpegQuality) else {
            throw LiveImageObjectTypeError.imageConversionFailed("Invalid JPEG image")
        }
        
        let destinationURL = outputJPEGImageURL as CFURL
        guard let imageDestination = CGImageDestinationCreateWithURL(destinationURL, kUTTypeJPEG, 1, nil) else {
            throw LiveImageObjectTypeError.imageConversionFailed("The specified directory does not exist")
        }
        
        defer { CGImageDestinationFinalize(imageDestination) }
        
        guard let cgImageSource: CGImageSource = CGImageSourceCreateWithData(imageData as CFData, nil) else {
            throw LiveImageObjectTypeError.imageConversionFailed("Image data is missing")
        }
        
        guard let imageSourceCopyProperties = CGImageSourceCopyPropertiesAtIndex(cgImageSource, 0, nil) as NSDictionary? else {
            throw LiveImageObjectTypeError.imageConversionFailed("Metadata of image is missing")
        }
        
        guard let metadata = imageSourceCopyProperties.mutableCopy() as? NSMutableDictionary else {
            throw LiveImageObjectTypeError.imageConversionFailed("Metadata of image could not be copied")
        }
        
        let makerNote = NSMutableDictionary()
        makerNote.setObject(assetID, forKey: kFigAppleMakerNote_AssetIdentifier as NSCopying)
        
        metadata.setObject(makerNote, forKey: kCGImagePropertyMakerAppleDictionary as String as NSCopying)
        CGImageDestinationAddImageFromSource(imageDestination, cgImageSource, 0, metadata)
    }
}
