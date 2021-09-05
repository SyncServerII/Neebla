
import Foundation
import SwiftUI

struct URLLargeMedia: View {
    @StateObject var model:GenericImageModel
    @StateObject var urlModel:URLModel
    let tapOnLargeMedia: ()->()
    
    var body: some View {
        VStack {
            ZoomableScrollView {
                VStack {
                    if let image = model.image {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }
                    else if model.imageStatus == .gone {
                        GoneImage()
                    }
                    else {
                        EmptyView()
                    }
                }
                .onTapGesture {
                    tapOnLargeMedia()
                }
                
                if let contents = urlModel.contents, let url = contents.url {
                    Link(url.absoluteString, destination: url)
                        .font(.title)
                        .foregroundColor(.blue)
                }
                else if urlModel.gone {
                    Text("(Problem getting URL)")
                }
                
                Spacer()
            }
        }.onAppear() {
            urlModel.getContents()
        }
    }
}
