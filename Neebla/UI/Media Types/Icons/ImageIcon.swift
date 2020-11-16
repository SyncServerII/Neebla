
import Foundation
import SwiftUI
import SFSafeSymbols

struct ImageIcon: View {
    let loadingImage = SFSymbol.timer.rawValue
    @State var fileImage: UIImage? = nil
    var imageFile: URL?
    
    init(imageFile: URL?) {
        self.imageFile = imageFile

    }
    
    func loadImage() {
        if let imageFile = imageFile {
            DispatchQueue.global().async {
                if let imageData = try? Data(contentsOf: imageFile),
                    let image = UIImage(data: imageData) {
                    DispatchQueue.main.async {
                        self.fileImage = image
                    }
                }
            }
        }
    }
    
    var body: some View {
        Image(systemName: loadingImage)
    }
}
