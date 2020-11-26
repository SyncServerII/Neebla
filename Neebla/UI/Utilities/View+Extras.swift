
import Foundation
import SwiftUI

extension View {
    public func enabled(_ enabled: Bool) -> some View {
        return self.disabled(!enabled)
    }
}
