
import Foundation
import SwiftUI
import SMLinkPreview

struct URLPreviewItemProvider: UIViewRepresentable {
    let linkData:LinkData
    
    init(linkData:LinkData) {
        self.linkData = linkData
    }
    
    func makeUIView(context: Context) -> UIView {
        return LinkPreview.create(with: linkData)
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
    }
}
