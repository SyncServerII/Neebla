
import Foundation
import SwiftUI

struct AnyLargeMedia: View {
    let object: ServerObjectModel
    let tapOnLargeMedia: ()->()
    @ObservedObject var model:AnyLargeMediaModel
    
    // TODO: Need to update badge text when badge count gets updated for this file model.
    
    init(object: ServerObjectModel, tapOnLargeMedia: @escaping ()->()) {
        self.object = object
        self.tapOnLargeMedia = tapOnLargeMedia
        model = AnyLargeMediaModel(object: object)
    }
    
    var body: some View {
        VStack {
            // Each large media view needs to deal with zooming. When I take care of it at this top level, with URL media, when I return from the browser with a URL, it's showing a comment.
            switch object.objectType {
            case ImageObjectType.objectType:
                ImageLargeMedia(object: object, tapOnLargeMedia: {
                    tapOnLargeMedia()
                })

            case URLObjectType.objectType:
                URLLargeMedia(object: object, tapOnLargeMedia: {
                    tapOnLargeMedia()
                })
                    
            case LiveImageObjectType.objectType:
                LiveImageLargeMedia(object: object, tapOnLargeMedia: {
                    tapOnLargeMedia()
                })
                    
            case GIFObjectType.objectType:
                GIFLargeMedia(object: object, tapOnLargeMedia: {
                    tapOnLargeMedia()
                })
                    
            default:
                EmptyView()
            }
        }
        // The badge is not showing up the way I want it on `LiveImageLargeMedia`. It is not showing up within the image. Just the upper/left of the screen. Not sure how to resolve that.
        .if(model.mediaItemUnreadCountBadgeText != nil) {
            $0.overlay(
                BadgeOverlay(text: model.mediaItemUnreadCountBadgeText!).padding([.leading, .top], 5),
                alignment: .topLeading)
        }
        .onAppear() {
            Downloader.session.objectAccessed(object: object)
        }
    }
}
