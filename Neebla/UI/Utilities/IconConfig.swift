//
//  IconConfig.swift
//  Neebla
//
//  Created by Christopher G Prince on 1/21/21.
//

import Foundation
import UIKit

struct IconConfig {
    // Icons are square; this the height and width needed.
    let dimension: CGFloat
    
    var iconSize: CGSize {
        return CGSize(width: dimension, height: dimension)
    }
    
    enum ScreenSize {
        case small // e.g., iPhone
        case large // e.g., iPad
        
        var isSmall: Bool {
            return self == .small
        }
    }
    
    // The `dimension` will be larger for iPad. Some icons can use the extra space to change the quality of the icon. i.e., not just its size.
    let screenSize: ScreenSize
    
    // MARK: Specific configs
    static let iPadIconDimension: CGFloat = 200
    static let iPhoneIconDimension: CGFloat = 75
    
    static let large = IconConfig(dimension: iPadIconDimension, screenSize: .large)
    static let small = IconConfig(dimension: iPhoneIconDimension, screenSize: .small)
}
