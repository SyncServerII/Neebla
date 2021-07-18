
import Foundation
import SwiftUI

// None of the icon's should have specific content in the upper right when normally rendered. This is so that `AnyIcon` can put `upperRightView` there.

struct AnyIconMain: View {
    @ObservedObject var model:AnyIconModel
    let config: IconConfig
    
    var body: some View {
        switch model.object.objectType {
        
        case ImageObjectType.objectType:
            ImageIcon(object: model.object, config: config)
        
        case URLObjectType.objectType:
            URLIcon(object: model.object, config: config)
            
        case LiveImageObjectType.objectType:
            LiveImageIcon(.object(fileLabel: LiveImageObjectType.imageDeclaration.fileLabel, object:  model.object), config: config)
            
        case GIFObjectType.objectType:
            GIFIcon(object: model.object, config: config)
        
        default:
            EmptyView()
        }
    }
}

struct AnyIcon<Content: View>: View {
    @ObservedObject var model:AnyIconModel
    let upperRightView: () -> Content
    let config: IconConfig
    let badgeSize = CGSize(width: 20, height: 20)
    let emptyUpperRightView: Bool
    
    // If emptyUpperRightView is true, then upperRightView is ignored.
    init(object: ServerObjectModel, config: IconConfig, emptyUpperRightView: Bool = false, @ViewBuilder upperRightView: @escaping () -> Content) {
        model = AnyIconModel(object: object)
        self.upperRightView = upperRightView
        self.config = config
        self.emptyUpperRightView = emptyUpperRightView
    }
    
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
                    AnyIconMain(model: model, config: config)
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
        .if(model.unreadCountBadgeText != nil) {
            $0.upperLeftBadge(model.unreadCountBadgeText!)
        }
        .onAppear() {
            Downloader.session.objectAccessed(object: model.object)
        }
    }
}
