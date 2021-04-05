
import Foundation
import SwiftUI

struct ImageLargeMedia: View {
    let object: ServerObjectModel
    static let imageFileLabel = ImageObjectType.imageDeclaration.fileLabel
    @ObservedObject var model:GenericImageModel
    let tapOnLargeMedia: ()->()
    
    init(object: ServerObjectModel, tapOnLargeMedia: @escaping ()->()) {
        self.tapOnLargeMedia = tapOnLargeMedia
        self.object = object
        model = GenericImageModel(fileLabel: Self.imageFileLabel, fileGroupUUID: object.fileGroupUUID)
    }
    
    var body: some View {
        VStack {
            if model.image != nil || model.imageStatus == .gone {
                VStack {
                    if let image = model.image {
                        ZoomableScrollView {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                            Spacer()
                        }
                    }
                    else if model.imageStatus == .gone {
                        GoneImage()
                    }
                }
                .onTapGesture {
                    tapOnLargeMedia()
                }
            }
            else {
                EmptyView()
            }
        }
    }
}
