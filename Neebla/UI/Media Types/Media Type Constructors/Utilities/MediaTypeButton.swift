
import Foundation
import SwiftUI

struct MediaTypeButton<M: MediaConstructorType>: View {
    let mediaType: M
    let action:()->()
    
    init(mediaType: M, action:@escaping ()->()) {
        self.mediaType = mediaType
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            action()
        }, label: {
            Text(mediaType.uiDisplayName)
        })
    }
}
