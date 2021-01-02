//
//  URLMediaPicker.swift
//  Neebla
//
//  Created by Christopher G Prince on 1/1/21.
//

import Foundation
import SwiftUI

struct URLMediaPicker: MediaPicker {
    let mediaPickerEnabled: Bool = true
    let mediaPickerUIDisplayName: String = "Web link (URL)"
    let itemPicked:(UploadableMediaAssets)->()
    
    init(itemPicked: @escaping (UploadableMediaAssets)->()) {
        self.itemPicked = itemPicked
    }

    var mediaPicker: AnyView {
        AnyView(
            URLPickerView() { pickedURL in
                itemPicked(pickedURL)
            }
        )
    }
}

