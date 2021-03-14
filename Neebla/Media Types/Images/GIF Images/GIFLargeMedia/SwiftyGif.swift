//
//  SwiftyGif.swift
//  Neebla
//
//  Created by Christopher G Prince on 3/12/21.
//

import Foundation
import SwiftUI
import iOSShared
import Gifu

struct SwiftyGif: UIViewRepresentable {
    let gifData:Data
    let size: CGSize
    @Binding var loop: Bool
    
    init(gifData: Data, size: CGSize, loop: Binding<Bool>) {
        self.gifData = gifData
        self.size = size
        self._loop = loop
    }
    
    func makeUIView(context: Context) -> GIFImageView {
        let imageView = GIFImageView()
        imageView.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        imageView.contentMode = .scaleAspectFit
        
        // Need resizing and animating in order to get the GIF to size correctly in the large image view.
        imageView.setShouldResizeFrames(true)
        imageView.animate(withGIFData: gifData)

        return imageView
    }

    func updateUIView(_ gifImageView: GIFImageView, context: Context) {
        if loop {
            gifImageView.startAnimatingGIF()
        }
        else {
            gifImageView.stopAnimatingGIF()
        }
    }
}
