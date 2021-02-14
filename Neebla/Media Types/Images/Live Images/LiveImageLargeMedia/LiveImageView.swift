
import Foundation
import SwiftUI
import PhotosUI
import iOSShared

struct LiveImageView: UIViewRepresentable {
    let view: PHLivePhotoView
    let model:LiveImageViewModel?
    
    init(fileGroupUUID: UUID) {
        let view = PHLivePhotoView()
        // Without this, in landscape mode, I don't get proper scaling of the image.
        view.contentMode = .scaleAspectFit
        
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
        guard let model = model else {
            return
        }
        
        guard !model.started else {
            return
        }
        
        model.started = true
        view.startPlayback(with: .full)
    }
}

