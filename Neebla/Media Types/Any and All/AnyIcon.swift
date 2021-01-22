
import Foundation
import SwiftUI

// None of the icon's should have specific content in the upper right when normally rendered. This is so that `AnyIcon` can put `upperRightView` there.

struct AnyIcon: View {
    let object: ServerObjectModel
    let upperRightView: AnyView?
    let config: IconConfig
    private var badgeText: String?
    
    init(object: ServerObjectModel, config: IconConfig, upperRightView: AnyView? = nil) {
        self.object = object
        self.upperRightView = upperRightView
        if let count = try? object.getCommentsUnreadCount(), count > 0 {
            badgeText = "\(count)"
        }
        self.config = config
    }
    
    var body: some View {
        ZStack {
            VStack {
                switch object.objectType {
                
                case ImageObjectType.objectType:
                    ImageIcon(object: object, config: config)
                
                case URLObjectType.objectType:
                    URLIcon(object: object, config: config)
                    
                case LiveImageObjectType.objectType:
                    LiveImageIcon(.object(fileLabel: LiveImageObjectType.imageDeclaration.fileLabel, object: object), config: config)
                
                default:
                    EmptyView()
                }
            }
        }
        .if(upperRightView != nil) {
            $0.upperRightView(upperRightView!)
        }
        .if(badgeText != nil) {
            $0.upperLeftBadge(badgeText!)
        }
        .onAppear() {
            Downloader.session.objectAccessed(object: object)
        }
    }
}
