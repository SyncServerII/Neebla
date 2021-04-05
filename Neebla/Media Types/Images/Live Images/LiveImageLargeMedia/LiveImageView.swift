
import Foundation
import SwiftUI
import PhotosUI
import iOSShared

struct LiveImageView: UIViewRepresentable {
    let view: PHLivePhotoView
    let model:LiveImageViewModel
    // let delegate = LiveImageLargeMediaDelegate()
    
    init(model:LiveImageViewModel) {
        self.model = model
        
        let view = PHLivePhotoView()
        // Without this, in landscape mode, I don't get proper scaling of the image.
        view.contentMode = .scaleAspectFit
        
        self.view = view
        
        // Using this to (try to) replay live image repeatedly.
        // view.delegate = delegate
                
        guard let imageURL = model.imageURL,
            let movieURL = model.movieURL else {
            return
        }
        
        LiveImageViewModel.getLivePhoto(image: imageURL, movie: movieURL, previewImage: nil) { livePhoto in
            view.livePhoto = livePhoto
        }
    }
    
    func makeUIView(context: Context) -> UIView {
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        guard !model.error else {
            return
        }
        
        guard !model.started else {
            return
        }
        
        model.started = true
        view.startPlayback(with: .full)
    }
}

// This isn't working: https://stackoverflow.com/questions/66620332
private class LiveImageLargeMediaDelegate: NSObject, PHLivePhotoViewDelegate {
    func livePhotoView(_ livePhotoView: PHLivePhotoView, didEndPlaybackWith playbackStyle: PHLivePhotoViewPlaybackStyle) {
//        livePhotoView.stopPlayback()
//        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(200)) {
//            livePhotoView.startPlayback(with: .full)
//        }
    }
}
