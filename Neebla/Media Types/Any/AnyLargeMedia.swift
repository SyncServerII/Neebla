
import Foundation
import SwiftUI

struct AnyLargeMedia: View {
    let object: ServerObjectModel
    
    var body: some View {
        switch object.objectType {
        case ImageObjectType.objectType:
            ImageLargeMedia(object: object)

        case URLObjectType.objectType:
            URLLargeMedia(object: object)
            
        default:
            EmptyView()
        }
    }
}
