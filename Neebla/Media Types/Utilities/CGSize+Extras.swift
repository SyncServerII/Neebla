//
//  CGSize+Extras.swift
//  Neebla
//
//  Created by Christopher G Prince on 2/13/21.
//

import Foundation
import UIKit

extension CGSize {
    static let minimumDimension: CGFloat = 10
    
    // If an image has height or width smaller than some bound, it seems unlikely it will be viewable.
    func isOK(minimumDimension: CGFloat = Self.minimumDimension) -> Bool {
        if width < minimumDimension || height < minimumDimension {
            return false
        }
        
        return true
    }
}
