
import Foundation
import SwiftUI

struct ImageLargeMedia: View {
    @StateObject var model:GenericImageModel
    let tapOnLargeMedia: ()->()
    
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
