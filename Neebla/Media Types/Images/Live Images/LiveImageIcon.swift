
import Foundation
import SwiftUI

struct LiveImageIcon: View {
    let modelSetup: GenericImageIcon.ModelSetup
    let config: IconConfig
    
    var body: some View {
        ZStack {
            GenericImageIcon(model:
                GenericImageIcon.setupModel(modelSetup, iconSize: config.iconSize),
                    config: config)
                .lowerRightText("live")
        }
    }
}
