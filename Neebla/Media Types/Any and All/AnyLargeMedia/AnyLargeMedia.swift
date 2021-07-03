
import Foundation
import SwiftUI

struct AnyLargeMediaMain: View {
    let object: ServerObjectModel
    let tapOnLargeMedia: ()->()

    var body: some View {
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
}

struct AnyLargeMedia: View {
    let object: ServerObjectModel
    let tapOnLargeMedia: ()->()
    let tapOnKeywordIcon: ()->()
    @ObservedObject var model:AnyLargeMediaModel
    let badgeSize = CGSize(width: 40, height: 40)
    
    init(object: ServerObjectModel, tapOnLargeMedia: @escaping ()->(), tapOnKeywordIcon: @escaping ()->()) {
        self.object = object
        self.tapOnLargeMedia = tapOnLargeMedia
        self.tapOnKeywordIcon = tapOnKeywordIcon
        model = AnyLargeMediaModel(object: object)
    }
    
    var body: some View {
        VStack {
            if model.mediaItemBadge == .hide {
                Image("Hidden")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .background(Color.white)
            }
            else {
                AnyLargeMediaMain(object: object, tapOnLargeMedia: tapOnLargeMedia)
            }
        }
        // The badge is not showing up the way I want it on `LiveImageLargeMedia`. It is not showing up within the image. Just the upper/left of the screen. Not sure how to resolve that.
        .if(model.unreadCountBadgeText != nil) {
            $0.overlay(
                BadgeOverlay(text: model.unreadCountBadgeText!).padding([.leading, .top], 5),
                alignment: .topLeading)
        }
        .upperRightView({
            VStack {
                MediaItemMultipleBadgeView(object: object, maxNumberOthersBadges: 4, size: badgeSize)
                KeywordsBadgeView(object: object, size: badgeSize) {
                    tapOnKeywordIcon()
                }
            }
        })
    }
}
