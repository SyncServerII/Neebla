
import Foundation
import SwiftUI

// None of the icon's should have specific content in the upper right when normally rendered. This is so that `AnyIcon` can put `upperRightView` there.

struct AnyIcon: View {
    let object: ServerObjectModel
    let upperRightView: AnyView?
    private var badgeText: String?
    
    init(object: ServerObjectModel, upperRightView: AnyView? = nil) {
        self.object = object
        self.upperRightView = upperRightView
        if let count = try? object.getCommentsUnreadCount(), count > 0 {
            badgeText = "\(count)"
        }
    }
    
    var body: some View {
        ZStack {
            VStack {
                switch object.objectType {
                
                case ImageObjectType.objectType:
                    ImageIcon(object: object)
                
                case URLObjectType.objectType:
                    URLIcon(object: object)
                    
                case LiveImageObjectType.objectType:
                    LiveImageIcon(.object(fileLabel: LiveImageObjectType.imageDeclaration.fileLabel, object: object))
                
                default:
                    EmptyView()
                }
            }
            
            ViewInUpperRight {
                if let upperRightView = upperRightView {
                    upperRightView
                }
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
