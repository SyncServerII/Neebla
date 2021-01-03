
import Foundation
import SwiftUI

struct AnyLargeMedia: View {
    let object: ServerObjectModel
    private var badgeText: String?
    
    init(object: ServerObjectModel) {
        self.object = object
        if let count = try? object.getCommentsUnreadCount(), count > 0 {
            badgeText = "\(count)"
        }
    }
    
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
        .if(badgeText != nil) {
            $0.overlay(
                BadgeOverlay(text: badgeText!).padding([.leading, .top], 5),
                alignment: .topLeading)
        }
        .onAppear() {
            Downloader.session.objectAccessed(object: object)
        }
    }
}
