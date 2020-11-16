
import Foundation
import SwiftUI
import SFSafeSymbols

struct ImageIcon: IconTypeView, View {
    let model = ImageIconModel()
    let object: ServerObjectModel

    let loadingImage = SFSymbol.timer.rawValue
    @State var fileImage: UIImage? = nil
    
    init(object: ServerObjectModel) {
        self.object = object
    }
    
    var body: some View {
        model.loadImage(fileGroupUUID: object.fileGroupUUID) { image in
            fileImage = image
        }
        
        return VStack {
            if let fileImage = fileImage {
                Image(uiImage: fileImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 75)
            }
            else {
                Image(systemName: loadingImage)
            }
        }
    }
}
