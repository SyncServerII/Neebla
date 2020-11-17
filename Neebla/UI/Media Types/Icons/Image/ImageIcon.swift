
import Foundation
import SwiftUI
import SFSafeSymbols

struct ImageIcon: IconTypeView, View {
    let model = ImageIconModel()
    let object: ServerObjectModel

    let loadingImage = SFSymbol.timer.rawValue
    @State var fileImage: UIImage? = nil
    let dimension: CGFloat = 75
    
    init(object: ServerObjectModel) {
        self.object = object
    }
    
    var body: some View {
        model.loadImage(fileGroupUUID: object.fileGroupUUID) { image in
            fileImage = image
        }

        return VStack {
            if let fileImage = fileImage {
                VStack {
                    Image(uiImage: fileImage)
                        .resizable()
                        .squareImage()
                        .cornerRadius(4.0)
                }.frame(width:dimension, height:dimension)
            }
            else {
                Image(systemName: loadingImage)
            }
        }
    }
}

// From https://medium.com/@wendyabrantes/swift-ui-square-image-modifier-3a4370ca561f
struct RatioModifier: ViewModifier {
    let ratio: CGFloat
   
    init(ratio: CGFloat) {
        self.ratio = ratio
    }
    
    func body(content: Content) -> some View {
        GeometryReader { geo in
            content
                .aspectRatio(contentMode: .fill)
        }
        .aspectRatio(ratio, contentMode: .fit)
    }
}

extension Image {
    func ratioImage(ratio: CGFloat) -> some View {
        self.modifier(RatioModifier(ratio: ratio))
    }
    
    func squareImage() -> some View {
        ratioImage(ratio: 1.0)
    }
}
