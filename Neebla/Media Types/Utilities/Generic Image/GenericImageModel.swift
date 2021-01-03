
import Foundation
import SQLite
import UIKit
import iOSShared

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
        imageStatus = .loading

        guard let scale = scale else {
            // Not scaling.
            DispatchQueue.global(qos: .background).async {
                self.loadImageFrom(url: fullSizeImageURL)
            }
            return
        }
        
        // Scaling
        let iconURL = self.iconURLWithScaling(scale: scale, url: fullSizeImageURL)
        if FileManager.default.fileExists(atPath: iconURL.path) {
            DispatchQueue.global(qos: .background).async {
                self.loadImageFrom(url: iconURL)
            }
            return
        }

        // Need to load full-sized image, scale, save, and return scaled image.
        DispatchQueue.global(qos: .background).async {
            guard let imageData = try? Data(contentsOf: fullSizeImageURL),
                let image = UIImage(data: imageData) else {
                logger.error("Could not load full sized image.")
                self.noImageHelper()
                return
            }
            
            guard let scaledImage = image.squareCropAndScaleTo(dimension: scale.height) else {
                 logger.error("Could not scale full sized image.")
                self.noImageHelper()
                return
            }
            
            // Looks like this is causing sharing extension to fail:
            // https://github.com/gavinbunney/Toucan/issues/81
            /*
            guard let scaledImage = Toucan(image: image).resize(scale, fitMode: Toucan.Resize.FitMode.crop).image else {
                logger.error("Could not scale full sized image.")
                self.noImageHelper()
                return
            }*/
            
            guard let jpegQuality = try? SettingsModel.jpegQuality(db: Services.session.db) else {
                logger.error("Could not get settings.")
                self.noImageHelper()
                return
            }

            guard let data = scaledImage.jpegData(compressionQuality: jpegQuality) else {
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

extension UIImage {
    // With centering
    func squareCropAndScaleTo(dimension: CGFloat) -> UIImage? {
        // First, do a square crop with centering.
        let smallestCurrentDimension = min(size.height, size.width)
        let x = (self.size.width - smallestCurrentDimension)/2
        let y = (self.size.height - smallestCurrentDimension)/2
        
        guard let squareImage = croppedInRect(rect: CGRect(x: x, y: y, width: smallestCurrentDimension, height: smallestCurrentDimension)) else {
            return nil
        }
        
        return squareImage.resize(toTargetSize: CGSize(width: dimension, height: dimension))
    }
    
    // Adapted from https://stackoverflow.com/questions/32041420/cropping-image-with-swift-and-put-it-on-center-position
    func croppedInRect(rect: CGRect) -> UIImage? {
        func rad(_ degree: Double) -> CGFloat {
            return CGFloat(degree / 180.0 * .pi)
        }

        var rectTransform: CGAffineTransform
        switch imageOrientation {
        case .left:
            rectTransform = CGAffineTransform(rotationAngle: rad(90)).translatedBy(x: 0, y: -self.size.height)
        case .right:
            rectTransform = CGAffineTransform(rotationAngle: rad(-90)).translatedBy(x: -self.size.width, y: 0)
        case .down:
            rectTransform = CGAffineTransform(rotationAngle: rad(-180)).translatedBy(x: -self.size.width, y: -self.size.height)
        default:
            rectTransform = .identity
        }
        rectTransform = rectTransform.scaledBy(x: self.scale, y: self.scale)
        
        guard let cgImage = cgImage else {
            return nil
        }
        
        guard let imageRef = cgImage.cropping(to: rect.applying(rectTransform)) else {
            return nil
        }
        
        let result = UIImage(cgImage: imageRef, scale: self.scale, orientation: self.imageOrientation)
        return result
    }

    // https://gist.github.com/licvido/55d12a8eb76a8103c753
    func resize(toTargetSize targetSize: CGSize) -> UIImage {
        let newScale = self.scale // change this if you want the output image to have a different scale
        let originalSize = self.size

        let widthRatio = targetSize.width / originalSize.width
        let heightRatio = targetSize.height / originalSize.height

        // Figure out what our orientation is, and use that to form the rectangle
        let newSize: CGSize
        if widthRatio > heightRatio {
            newSize = CGSize(width: floor(originalSize.width * heightRatio), height: floor(originalSize.height * heightRatio))
        } else {
            newSize = CGSize(width: floor(originalSize.width * widthRatio), height: floor(originalSize.height * widthRatio))
        }

        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(origin: .zero, size: newSize)

        // Actually do the resizing to the rect using the ImageContext stuff
        let format = UIGraphicsImageRendererFormat()
        format.scale = newScale
        format.opaque = true
        let newImage = UIGraphicsImageRenderer(bounds: rect, format: format).image() { _ in
            self.draw(in: rect)
        }

        return newImage
    }
}
