
import Foundation
import SwiftUI

struct NavBarIcon: View {
    let imageName: String
    let size: CGSize
    static let dimension: CGFloat = 50
    
    init(imageName: String, size: CGSize = CGSize(width: Self.dimension, height: Self.dimension)) {
        self.imageName = imageName
        self.size = size
    }
    
    var body: some View {
        Image(imageName)
            .renderingMode(.template)
            .resizable()
            .accentColor(.blue)
            .imageScale(.large)
            .frame(width: size.width, height: size.height)
    }
}
