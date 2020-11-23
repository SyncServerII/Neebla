
import Foundation
import SwiftUI

struct URLIcon: View {
    let urlFileLabel = URLObjectType.previewImageDeclaration.fileLabel
    @State var showingImage: Bool = false
    let object: ServerObjectModel

    var body: some View {
        ZStack {
            GenericImageIcon(fileLabel: urlFileLabel, object: object, showingImage: $showingImage)
            if showingImage {
                // Along with the `ZStack`, this puts "url" in the lower right of the icon.
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text(" url ")
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
    }
}
