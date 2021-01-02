//
//  MediaPicker.swift
//  Neebla
//
//  Created by Christopher G Prince on 1/1/21.
//

import Foundation
import SwiftUI

protocol MediaPicker {
    var mediaPickerEnabled: Bool { get }
    var mediaPickerUIDisplayName: String {get}
    var mediaPicker: AnyView { get }
    init(itemPicked: @escaping (UploadableMediaAssets)->())
}
