
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

