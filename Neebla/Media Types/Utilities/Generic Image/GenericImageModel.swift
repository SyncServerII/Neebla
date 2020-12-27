
import Foundation
import SQLite
import UIKit
import iOSShared

// Currently using: https://github.com/petrpavlik/Toucan because the main repo doesn't yet support SPM.
import Toucan

class GenericImageModel: ObservableObject {
    @Published var image: UIImage?
    
    enum ImageStatus {
        case none
        case loading
        case loaded
    }

    @Published var imageStatus: ImageStatus = .none

    // Starts loading image when initialized. Image loads asynchronously, but is assigned to `image` on the main thread when finished loading.
    init(fileLabel: String, fileGroupUUID: UUID, imageScale: CGSize? = nil) {
        loadImage(fileGroupUUID: fileGroupUUID, fileLabel: fileLabel, scale: imageScale)
    }
    
    init(fullSizeImageURL: URL, imageScale: CGSize? = nil) {
        loadImage(fullSizeImageURL: fullSizeImageURL, scale: imageScale)
    }
        
    private func loadImage(fileGroupUUID: UUID, fileLabel: String, scale: CGSize? = nil) {
        imageStatus = .loading
                
        guard let imageFileModel = try? ServerFileModel.getFileFor(fileLabel: fileLabel, withFileGroupUUID: fileGroupUUID) else {
            noImageHelper()
            return
        }
        
        guard let fullSizeImageURL = imageFileModel.url else {
            noImageHelper()
            return
        }
        
        loadImage(fullSizeImageURL: fullSizeImageURL, scale: scale)
    }
    
    private func loadImage(fullSizeImageURL: URL, scale: CGSize?) {
        // Are we scaling?
        if let scale = scale {
            let iconURL = self.iconURLWithScaling(scale: scale, url: fullSizeImageURL)
            if FileManager.default.fileExists(atPath: iconURL.path) {
                DispatchQueue.global(qos: .background).async {
                    self.loadImageFrom(url: iconURL)
                }
            }
            else {
                // Need to load full-sized image, scale, save, and return scaled image.
                DispatchQueue.global(qos: .background).async {
                    guard let imageData = try? Data(contentsOf: fullSizeImageURL),
                        let image = UIImage(data: imageData) else {
                        logger.error("Could not load full sized image.")
                        self.noImageHelper()
                        return
                    }
                    
                    guard let scaledImage = Toucan(image: image).resize(scale, fitMode: Toucan.Resize.FitMode.crop).image else {
                        logger.error("Could not scale full sized image.")
                        self.noImageHelper()
                        return
                    }
                    
                    guard let settings = try? SettingsModel.getSingleton(db: Services.session.db) else {
                        logger.error("Could not get settings.")
                        self.noImageHelper()
                        return
                    }

                    guard let data = scaledImage.jpegData(compressionQuality: settings.jpegQuality) else {
                        logger.error("Could not get jpeg data for scaled image.")
                        self.noImageHelper()
                        return
                    }
                    
                    do {
                        try data.write(to: iconURL)
                    } catch let error {
                        logger.error("Could not write icon file: \(error)")
                        self.noImageHelper()
                        return
                    }
                    
                    DispatchQueue.main.async {
                        self.image = scaledImage
                        self.imageStatus = .loaded
                    }
                }
            }
        }
        else {
            // Not scaling.
            DispatchQueue.global(qos: .background).async {
                self.loadImageFrom(url: fullSizeImageURL)
            }
        }
    }
    
    private func loadImageFrom(url: URL) {
        if let imageData = try? Data(contentsOf: url),
            let image = UIImage(data: imageData) {
            
            DispatchQueue.main.async {
                self.image = image
                self.imageStatus = .loaded
            }
        }
        else {
            self.noImageHelper()
        }
    }
    
    private func noImageHelper() {
        DispatchQueue.main.async {
            self.imageStatus = .none
        }
    }
    
    // Example url: //Users/chris/Library/Developer/CoreSimulator/Devices/42DA56B4-C598-4F0C-ACA2-8B5A525CAEA6/data/Containers/Shared/AppGroup/2721EFA3-A9A5-422D-8F08-64F41C619D4F/Documents/objects/Neebla.F7936567-A93E-4EA8-B4B5-F5D2A6ED653C.jpeg
    // 50x75 scale (width x height), renamed with scaling: //Users/chris/Library/Developer/CoreSimulator/Devices/42DA56B4-C598-4F0C-ACA2-8B5A525CAEA6/data/Containers/Shared/AppGroup/2721EFA3-A9A5-422D-8F08-64F41C619D4F/Documents/objects/Neebla.F7936567-A93E-4EA8-B4B5-F5D2A6ED653C.50x75.jpeg
    // Removes any fractional component from width/height in scale
    // Also-- new url is in the icons directory.
    func iconURLWithScaling(scale: CGSize, url: URL) -> URL {
        let iconsDir = Files.getDocumentsDirectory().appendingPathComponent(
            LocalFiles.icons)

        let oldExtension = url.pathExtension
        let urlWithoutExtension = url.deletingPathExtension()
        
        let filename = urlWithoutExtension.lastPathComponent

        let width = Int(scale.width)
        let height = Int(scale.height)
        let newExtension = "\(width)x\(height).\(oldExtension)"
        
        let newFilename = filename + "." + newExtension
        
        return iconsDir.appendingPathComponent(newFilename)
    }
}
