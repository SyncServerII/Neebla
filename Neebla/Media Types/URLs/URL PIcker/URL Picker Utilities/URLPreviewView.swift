
import Foundation
import SwiftUI
import SMLinkPreview

// Making use of a side-effect here, of setting model.loadImage
struct URLPreviewView: UIViewRepresentable {
    let linkData:LinkData
    @ObservedObject var model:URLPickerViewModel
    
    init(linkData:LinkData, model:URLPickerViewModel) {
        self.linkData = linkData
        self.model = model
    }
    
    func makeUIView(context: Context) -> LinkPreview {
        let preview = LinkPreview.create(with: linkData) { loadedImage in
            model.loadedImage = loadedImage
        }
        return preview
    }
    
    func updateUIView(_ linkPreview: LinkPreview, context: Context) {
    }
}
