
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

struct AnyIcon: View {
    @ObservedObject var model:AnyIconModel
    let upperRightView: AnyView?
    let config: IconConfig
    
    init(object: ServerObjectModel, config: IconConfig, upperRightView: AnyView? = nil) {
        model = AnyIconModel(object: object)
        self.upperRightView = upperRightView
        self.config = config
    }
    
    var body: some View {
        ZStack {
            VStack {
                if model.mediaItemBadge == .hide {
                    Image("Hidden")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
                else {
                    AnyIconMain(model: model, config: config)
                }
            }
        }
        .if(upperRightView != nil) {
            $0.upperRightView(upperRightView!)
        }
        .if(upperRightView == nil && model.mediaItemBadge != nil) {
            $0.upperRightView(
                AnyView(
                    MediaItemBadgeView(badge: model.mediaItemBadge, size: CGSize(width: 20, height: 20))
                )
            )
        }
        .if(model.unreadCountBadgeText != nil) {
            $0.upperLeftBadge(model.unreadCountBadgeText!)
        }
        .onAppear() {
            Downloader.session.objectAccessed(object: model.object)
        }
    }
}
