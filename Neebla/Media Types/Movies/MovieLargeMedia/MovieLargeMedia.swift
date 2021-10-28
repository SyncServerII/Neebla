//
//  MovieLargeMedia.swift
//  Neebla
//
//  Created by Christopher G Prince on 10/26/21.
//

import Foundation
import SwiftUI
import AVKit

struct MovieLargeMedia: View {
    let model:MovieViewModel
    let tapOnLargeMedia: ()->()

    init(object: ServerObjectModel, tapOnLargeMedia: @escaping ()->()) {
        self.tapOnLargeMedia = tapOnLargeMedia
        model = MovieViewModel(fileGroupUUID: object.fileGroupUUID)
    }
    
    var body: some View {
        VStack {
            if let movieURL = model.movieURL {
                ZoomableScrollView {
                    VideoPlayer(player: AVPlayer(url: movieURL))
                }
            }
            else {
                GoneImage()
            }
        }
    }
}
