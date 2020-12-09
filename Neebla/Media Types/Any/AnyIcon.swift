
import Foundation
import SwiftUI

struct AnyIcon: View {
    let object: ServerObjectModel
    
    var body: some View {
        return VStack {
            switch object.objectType {
            
            case ImageObjectType.objectType:
                ImageIcon(object: object)
            
            case URLObjectType.objectType:
                URLIcon(object: object)
                
            case LiveImageObjectType.objectType:
                LiveImageIcon(object:object)
            
            default:
                EmptyView()
            }
        }
        .onAppear() {
            Downloader.session.objectAccessed(object: object)
        }
    }
}
