//
//  PhotoLibraryMediaPicker.swift
//  Neebla
//
//  Created by Christopher G Prince on 1/1/21.
//

import Foundation
import SwiftUI
import iOSShared

struct PhotoLibraryMediaPicker: MediaPicker {
    let mediaPickerEnabled: Bool = true
    let mediaPickerUIDisplayName: String = "Photo library image"
    let itemPicked:(UploadableMediaAssets)->()

    init(itemPicked: @escaping (UploadableMediaAssets)->()) {
        self.itemPicked = itemPicked
    }

    var mediaPicker: AnyView {
        AnyView(
            PhotoPicker() { result in
                switch result {
                case .success(let assets):
                    itemPicked(assets)
                case .failure(let error):
                    logger.error("\(error)")
                    showAlert(AlertyHelper.error(message: "Error picking photo"))
                }
            }
        )
    }
}
