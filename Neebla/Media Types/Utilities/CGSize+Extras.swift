//
//  CGSize+Extras.swift
//  Neebla
//
//  Created by Christopher G Prince on 2/13/21.
//

import Foundation
import UIKit

extension CGSize {
    static let minimumAspectRatio: CGFloat = 0.1
    
    func aspectRatioOK(minimumAspectRatio: CGFloat = Self.minimumAspectRatio) -> Bool {
        if width == 0 || height == 0 {
            return false
        }
        
        let maxDim = max(width, height)
        let minDim = min(width, height)
        return (minDim / maxDim) >= minimumAspectRatio
    }
}
