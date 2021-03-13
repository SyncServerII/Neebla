//
//  GIFLargeMedia.swift
//  Neebla
//
//  Created by Christopher G Prince on 3/11/21.
//

import Foundation
import SwiftUI
import iOSShared

struct GIFLargeMedia: View {
    let gifModel:GIFModel
    
    init(object: ServerObjectModel) {
        gifModel = GIFModel(object: object)
    }
    
    var body: some View {
        GeometryReader { proxy in
            VStack {
                if let gifData = gifModel.gifData {
                    ZoomableScrollView {
                        SwiftyGif(gifData: gifData, size: proxy.size)
                        Spacer()
                    }
                }
                else {
                    Rectangle()
                }
            }
        }
    }
}



