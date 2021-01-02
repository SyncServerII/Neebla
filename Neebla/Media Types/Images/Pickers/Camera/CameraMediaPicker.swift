//
//  CameraMediaPicker.swift
//  Neebla
//
//  Created by Christopher G Prince on 1/1/21.
//

import Foundation
import SwiftUI

struct CameraMediaPicker: MediaPicker {
    let mediaPickerEnabled: Bool = UIImagePickerController.isSourceTypeAvailable(.camera)
    let mediaPickerUIDisplayName: String = "Camera image"
    let itemPicked:(UploadableMediaAssets)->()
    
    init(itemPicked: @escaping (UploadableMediaAssets)->()) {
        self.itemPicked = itemPicked
    }

    var mediaPicker: AnyView {
        AnyView(
            CameraPickerView() { imageAsset in
                itemPicked(imageAsset)
            }
        )
    }
}
