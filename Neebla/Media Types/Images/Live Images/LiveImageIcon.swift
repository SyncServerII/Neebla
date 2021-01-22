
import Foundation
import SwiftUI

struct LiveImageIcon: View {
    let modelSetup: GenericImageIcon.ModelSetup
    let config: IconConfig
    
    init(_ modelSetup: GenericImageIcon.ModelSetup, config: IconConfig) {
        self.modelSetup = modelSetup
        self.config = config
    }
    
    var body: some View {
        ZStack {
            GenericImageIcon(modelSetup, config: config)
                .lowerRightText("live")
        }
    }
}
