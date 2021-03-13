
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
            // Each large media view needs to deal with zooming. When I take care it at this top level, with URL media, when I return from the browser with a URL, it's showing a comment.
            switch object.objectType {
            case ImageObjectType.objectType:
                ImageLargeMedia(object: object)

            case URLObjectType.objectType:
                URLLargeMedia(object: object)
                
            case LiveImageObjectType.objectType:
                LiveImageLargeMedia(object: object)
                
            case GIFObjectType.objectType:
                GIFLargeMedia(object: object)
                
            default:
                EmptyView()
            }
        }
        // The badge is not showing up the way I want it on `LiveImageLargeMedia`. It is not showing up within the image. Just the upper/left of the screen. Not sure how to resolve that.
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
