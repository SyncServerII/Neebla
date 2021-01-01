
import Foundation
import UIKit

extension UIDevice {
    static var isPad: Bool {
        Self.current.userInterfaceIdiom == .pad
    }
}
