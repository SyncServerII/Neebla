
import Foundation
import SwiftUI

// From https://medium.com/@wendyabrantes/swift-ui-square-image-modifier-3a4370ca561f
struct RatioModifier: ViewModifier {
    let ratio: CGFloat
   
    init(ratio: CGFloat) {
        self.ratio = ratio
    }
    
    func body(content: Content) -> some View {
        GeometryReader { geo in
            content
                .aspectRatio(contentMode: .fill)
        }
        .aspectRatio(ratio, contentMode: .fit)
    }
}

extension Image {
    func ratioImage(ratio: CGFloat) -> some View {
        self.modifier(RatioModifier(ratio: ratio))
    }
    
    func squareImage() -> some View {
        ratioImage(ratio: 1.0)
    }
}
