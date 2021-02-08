
import Foundation
import SwiftUI

// None of the icon's should have specific content in the upper right when normally rendered. This is so that `AnyIcon` can put `upperRightView` there.

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
                switch model.object.objectType {
                
                case ImageObjectType.objectType:
                    ImageIcon(object: model.object, config: config)
                
                case URLObjectType.objectType:
                    URLIcon(object: model.object, config: config)
                    
                case LiveImageObjectType.objectType:
                    LiveImageIcon(.object(fileLabel: LiveImageObjectType.imageDeclaration.fileLabel, object:  model.object), config: config)
                
                default:
                    EmptyView()
                }
            }
        }
        .if(upperRightView != nil) {
            $0.upperRightView(upperRightView!)
        }
        .if(model.badgeText != nil) {
            $0.upperLeftBadge(model.badgeText!)
        }
        .onAppear() {
            Downloader.session.objectAccessed(object: model.object)
        }
    }
}
