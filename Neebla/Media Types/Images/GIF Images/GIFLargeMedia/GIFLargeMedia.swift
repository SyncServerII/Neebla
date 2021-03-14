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
    let tapOnLargeMedia: ()->()
    @State var loop: Bool = true
    
    init(object: ServerObjectModel, tapOnLargeMedia: @escaping ()->()) {
        gifModel = GIFModel(object: object)
        self.tapOnLargeMedia = tapOnLargeMedia
    }
    
    var body: some View {
        GeometryReader { proxy in
            VStack {
                if let gifData = gifModel.gifData {
                    ZoomableScrollView {
                        SwiftyGif(gifData: gifData, size: proxy.size, loop: $loop)
                            .onTapGesture {
                                tapOnLargeMedia()
                            }
                            
                        Spacer()
                    }
                    
                    HStack {
                        Spacer()
                        CheckBoxView(checked: $loop, text: "Repeat")
                            // Without this, the text is running into the RHS
                            .padding(.trailing, 20)
                    }
                }
                else {
                    Rectangle()
                }
            }
        }
    }
}



