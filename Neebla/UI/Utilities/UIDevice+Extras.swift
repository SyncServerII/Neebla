
import Foundation
import UIKit

extension UIDevice {
    static var isPad: Bool {
        Self.current.userInterfaceIdiom == .pad
    }
    
    static var isPortrait: Bool {
        UIDevice.current.orientation.isPortrait
    }
}
