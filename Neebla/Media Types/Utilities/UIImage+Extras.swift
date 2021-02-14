//
//  UIImage+Extras.swift
//  Neebla
//
//  Created by Christopher G Prince on 2/13/21.
//

import Foundation
import UIKit

extension UIImage {
    static func size(of imageAt: URL) -> CGSize? {
        guard let image = UIImage(contentsOfFile: imageAt.path) else {
            return nil
        }
        
        return image.size
    }
}
