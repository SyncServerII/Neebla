
import Foundation
import SwiftUI
import SMLinkPreview

struct URLPreviewView: UIViewRepresentable {
    let linkData:LinkData
    @ObservedObject var model:URLPickerViewModel
    
    init(linkData:LinkData, model:URLPickerViewModel) {
        self.linkData = linkData
        self.model = model
    }
    
    func makeUIView(context: Context) -> LinkPreview {
        LinkPreview.create()
    }
    
    func updateUIView(_ linkPreview: LinkPreview, context: Context) {
        linkPreview.setup(with: linkData)
    }
}
