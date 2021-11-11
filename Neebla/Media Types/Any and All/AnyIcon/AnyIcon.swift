
import Foundation
import SwiftUI
import iOSShared

// None of the icon's should have specific content in the upper right when normally rendered. This is so that `AnyIcon` can put `upperRightView` there.

struct AnyIconMain: View {
    @StateObject var object: ServerObjectModel
    let objectType:String
    let config: IconConfig
    
    var body: some View {
        switch objectType {
        
        case ImageObjectType.objectType:
            ImageIcon(object: object, config: config)

        case URLObjectType.objectType:
            URLIcon(object: object, config: config)
            
        case LiveImageObjectType.objectType:
            LiveImageIcon(object: object, config: config)
            
        case GIFObjectType.objectType:
            GIFIcon(object: object, config: config)

        case MovieObjectType.objectType:
            MovieIcon(object: object, config: config)
        
        default:
            EmptyView()
        }
    }
}

struct AnyIcon<Content: View>: View {
    @StateObject var model:AnyIconModel
    let config: IconConfig
    
    // If emptyUpperRightView is true, then upperRightView is ignored.
    let emptyUpperRightView: Bool
    
    let upperRightView: () -> Content
    let badgeSize = CGSize(width: 20, height: 20)
    
    var body: some View {
        ZStack {
            VStack {
                if model.mediaItemBadge == .hide {
                    ImageSizer(image: Image("Hidden"))
                        .background(Color.white)
                        .frame(width: config.iconSize.width, height: config.iconSize.height)
                        .cornerRadius(ImageSizer.cornerRadius)
                }
                else {
                    AnyIconMain(object: model.object, objectType: model.object.objectType, config: config)
                }
            }
        }
        .if(!emptyUpperRightView) {
            $0.upperRightView({ upperRightView() })
        }
        // Not showing a .hide badge because we show a special image for this. And because it seems a little confusing to have both the special image and a hide badge.
        .if(emptyUpperRightView && model.mediaItemBadge != .hide) {
            $0.upperRightView({
                // iPad has enough space to show more than one badge in icon view.
                if UIDevice.isPad {
                    MediaItemMultipleBadgeView(object: model.object, maxNumberOthersBadges: 2, size: badgeSize)
                }
                else {
                    MediaItemSingleBadgeView(badge: model.mediaItemBadge, size: badgeSize)
                }
            })
        }
        
        // Using the `.if` modifier here caused problems. Changing it to be more specific solved the problem. https://stackoverflow.com/questions/69783232/
        // See also https://www.objc.io/blog/2021/08/24/conditional-view-modifiers/
        .upperLeftBadge(model.unreadCountBadgeText)
        
        .if(model.newItem) {
            $0.lowerLeftIcon("New")
        }
        .onAppear() {
            Downloader.session.objectAccessed(object: model.object)
        }
    }
}
