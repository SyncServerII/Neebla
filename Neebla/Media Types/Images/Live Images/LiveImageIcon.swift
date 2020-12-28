
import Foundation
import SwiftUI

struct LiveImageIcon: View {
    let parameters: GenericImageIcon.Parameters
    
    init(_ parameters: GenericImageIcon.Parameters) {
        self.parameters = parameters
    }
    
    var body: some View {
        ZStack {
            GenericImageIcon(parameters)
            TextInLowerRight(text: "live")
        }
    }
}
