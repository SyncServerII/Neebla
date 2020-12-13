
import Foundation
import SwiftUI

struct NavBarIcon: View {
    let imageName: String
    let size: CGSize
    let blueAccent: Bool
    static let dimension: CGFloat = 50
    
    init(imageName: String, size: CGSize = CGSize(width: Self.dimension, height: Self.dimension), blueAccent: Bool = true) {
        self.imageName = imageName
        self.size = size
        self.blueAccent = blueAccent
    }
    
    var body: some View {
        Image(imageName)
            .renderingMode(.template)
            .resizable()
            .imageScale(.large)
            .frame(width: size.width, height: size.height)
            .if(blueAccent) {
                $0.accentColor(.blue)
            }
    }
}
