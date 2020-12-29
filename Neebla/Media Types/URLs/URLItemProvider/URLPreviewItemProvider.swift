
import Foundation
import SwiftUI
import SMLinkPreview

struct URLPreviewItemProvider: UIViewRepresentable {
    let linkData:LinkData
    
    init(linkData:LinkData) {
        self.linkData = linkData
    }
    
    func makeUIView(context: Context) -> UIView {
        let sizing = LinkPreviewSizing(resizingAllowed: false, titleLabelNumberOfLines: 1)
        return LinkPreview.create(with: linkData, sizing: sizing)
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
    }
}
