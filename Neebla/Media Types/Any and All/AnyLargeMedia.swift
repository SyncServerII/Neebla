
import Foundation
import SwiftUI

struct AnyLargeMedia: View {
    let object: ServerObjectModel
    
    var body: some View {
        VStack {
            switch object.objectType {
            case ImageObjectType.objectType:
                ImageLargeMedia(object: object)

            case URLObjectType.objectType:
                URLLargeMedia(object: object)
                
            case LiveImageObjectType.objectType:
                LiveImageLargeMedia(object: object)
                
            default:
                EmptyView()
            }
        }
        .onAppear() {
            Downloader.session.objectAccessed(object: object)
        }
    }
}
