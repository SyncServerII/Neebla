
import Foundation
import SwiftUI

// Make the body of screens look a little nicer on iPad by not taking up all the real-estate.

struct iPadConditionalScreenBodySizer<Content: View>: View {
    let content: Content
    @EnvironmentObject var appEnv: AppEnv
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        GeometryReader { proxy in
            if UIDevice.isPad {
                HStack {
                    Spacer()
                    VStack {
                        Spacer()
                        content
                        .frame(
                            width:
                                appEnv.isLandScape ? proxy.size.width * 0.6 : proxy.size.width * 0.9,
                            height:
                                appEnv.isLandScape ? proxy.size.height * 0.9: proxy.size.height * 0.6)
                        Spacer()
                    }
                    Spacer()
                }
            }
            else {
                content
            }
        }
    }
}
