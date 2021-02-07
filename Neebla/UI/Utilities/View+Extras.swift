
import Foundation
import SwiftUI

extension View {
    public func enabled(_ enabled: Bool) -> some View {
        return self.disabled(!enabled)
    }
    
    // https://forums.swift.org/t/conditionally-apply-modifier-in-swiftui/32815/16
	@ViewBuilder func `if`<T>(_ condition: Bool, transform: (Self) -> T) -> some View where T : View {
		if condition {
			transform(self)
		} else {
			self
		}
	}
}

// https://stackoverflow.com/questions/56490250/dynamically-hiding-view-in-swiftui
extension View {
    /// Hide or show the view based on a boolean value.
    ///
    /// Example for visibility:
    /// ```
    /// Text("Label")
    ///     .isHidden(true)
    /// ```
    ///
    /// Example for complete removal:
    /// ```
    /// Text("Label")
    ///     .isHidden(true, remove: true)
    /// ```
    ///
    /// - Parameters:
    ///   - hidden: Set to `false` to show the view. Set to `true` to hide the view.
    ///   - remove: Boolean value indicating whether or not to remove the view.
    @ViewBuilder func isHidden(_ hidden: Bool, remove: Bool = false) -> some View {
        if hidden {
            if !remove {
                self.hidden()
            }
        } else {
            self
        }
    }
    
    public func isHiddenRemove(_ hiddenRemove: Bool) -> some View {
        return isHidden(hiddenRemove, remove: hiddenRemove)
    }
}
