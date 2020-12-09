
import Foundation
import SwiftUI

struct TextInLowerRight: View {
    let text: String
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Text(text)
                    .foregroundColor(Color.black)
                    // To get leading & trailing white-colored space
                    .padding([.leading, .trailing], 5)
                    .background(Color.white.opacity(0.7))
                    // To get leading & trailing clear space
                    .padding([.trailing, .bottom], 4)
            }
        }
    }
}
