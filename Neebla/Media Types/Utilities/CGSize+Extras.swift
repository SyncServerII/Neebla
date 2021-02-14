//
//  CGSize+Extras.swift
//  Neebla
//
//  Created by Christopher G Prince on 2/13/21.
//

import Foundation
import UIKit

private let minimumAspectRatio: CGFloat = 0.05

extension CGSize {
    var aspectRatioOK: Bool {
        let maxDim = max(width, height)
        let minDim = min(width, height)
        return (minDim / maxDim) < minimumAspectRatio
    }
}
