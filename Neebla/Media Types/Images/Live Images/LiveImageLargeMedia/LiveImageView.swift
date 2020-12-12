
import Foundation
import SwiftUI
import PhotosUI

struct LiveImageView: UIViewRepresentable {
    let view: PHLivePhotoView
    let model:LiveImageViewModel?
    
    init(fileGroupUUID: UUID) {
        let view = PHLivePhotoView()
        self.view = view
        model = LiveImageViewModel(fileGroupUUID: fileGroupUUID)
        
        guard let model = model else {
            return
        }
        
        model.getLivePhoto(previewImage: nil) { livePhoto in
            view.livePhoto = livePhoto
        }
    }
    
    func makeUIView(context: Context) -> UIView {
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
    }
}
