
import Foundation
import SwiftUI

// Make the body of screens look a little nicer on iPad by not taking up all the real-estate.

struct iPadConditionalScreenBodySizer<Content: View>: View {
    let content: Content
    @EnvironmentObject var appEnv: AppEnv
    let iPadBackgroundColor: Color?
    
    init(iPadBackgroundColor: Color? = nil, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.iPadBackgroundColor = iPadBackgroundColor
    }
    
    var body: some View {
        if UIDevice.isPad {
            GeometryReader { proxy in
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
                        .if(iPadBackgroundColor != nil) {
                            $0.background(iPadBackgroundColor!)
                        }
                        Spacer()
                    }
                    Spacer()
                }
            }
        }
        else {
            content
        }
    }
}
