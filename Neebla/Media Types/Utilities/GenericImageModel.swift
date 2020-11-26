
import Foundation
import SQLite
import UIKit

class GenericImageModel: ObservableObject {
    private let fileLabel: String
    @Published var image: UIImage?
    
    enum ImageStatus {
        case none
        case loading
        case loaded
    }
    
    @Published var imageStatus: ImageStatus = .none

    // Starts loading image when initialized. Image loads asynchronously, but is assigned to `image` on the main thread.
    init(fileLabel: String, fileGroupUUID: UUID, imageScale: CGSize? = nil) {
        self.fileLabel = fileLabel
        loadImage(fileGroupUUID: fileGroupUUID, scale: imageScale)
    }

    private func loadImage(fileGroupUUID: UUID, scale: CGSize? = nil) {
        imageStatus = .loading
        
        func noImage() {
            DispatchQueue.main.async {
                self.imageStatus = .none
            }
        }
        
        // Toucan(image: image).resize(CGSize(width: Self.dimension, height: Self.dimension), fitMode: Toucan.Resize.FitMode.crop).image
        
        guard let imageFileModel = try? ServerFileModel.getFileFor(fileLabel: fileLabel, withFileGroupUUID: fileGroupUUID) else {
            noImage()
            return
        }
        
        guard let imageURL = imageFileModel.url else {
            noImage()
            return
        }
        
        // Example file name: Neebla.F7936567-A93E-4EA8-B4B5-F5D2A6ED653C.jpeg
        
        // Are we scaling?
        if let scale = scale {
            
        }
        
        DispatchQueue.global(qos: .background).async {
            if let imageData = try? Data(contentsOf: imageURL),
                let image = UIImage(data: imageData) {
                self.urlWithScaling(scale: CGSize(width: 50, height: 75), url: imageURL)
                DispatchQueue.main.async {
                    self.image = image
                    self.imageStatus = .loaded
                }
            }
            else {
                noImage()
            }
        }
    }
    
    // Example url: //Users/chris/Library/Developer/CoreSimulator/Devices/42DA56B4-C598-4F0C-ACA2-8B5A525CAEA6/data/Containers/Shared/AppGroup/2721EFA3-A9A5-422D-8F08-64F41C619D4F/Documents/objects/Neebla.F7936567-A93E-4EA8-B4B5-F5D2A6ED653C.jpeg
    // 50x75 scale (width x height), renamed with scaling: //Users/chris/Library/Developer/CoreSimulator/Devices/42DA56B4-C598-4F0C-ACA2-8B5A525CAEA6/data/Containers/Shared/AppGroup/2721EFA3-A9A5-422D-8F08-64F41C619D4F/Documents/objects/Neebla.F7936567-A93E-4EA8-B4B5-F5D2A6ED653C.50x75.jpeg
    // Removes any fractional component from width/height in scale
    func urlWithScaling(scale: CGSize, url: URL) {
        let oldExtension = url.pathExtension
        let urlWithoutExtension = url.deletingPathExtension()
        
        let width = Int(scale.width)
        let height = Int(scale.height)
        let newExtension = "\(width)x\(height).\(oldExtension)"
        let newURL = urlWithoutExtension.appendingPathExtension(newExtension)
        print("newURL: \(newURL)")
    }
}
