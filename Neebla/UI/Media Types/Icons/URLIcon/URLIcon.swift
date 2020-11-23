
import Foundation
import SwiftUI

struct URLIcon: View {
    let urlFileLabel = URLObjectType.previewImageDeclaration.fileLabel
    @State var imageStatus: GenericImageIcon.ImageStatus = .loading
    let object: ServerObjectModel
    @ObservedObject var model:URLIconModel
    
    init(object: ServerObjectModel) {
        self.object = object
        model = URLIconModel(object: object)
        model.getDescriptionText()
    }
    
    var body: some View {
        ZStack {
            GenericImageIcon(fileLabel: urlFileLabel, object: object, imageStatus: $imageStatus)
            if imageStatus == .none || imageStatus == .loaded {
                URLTextInLowerRight()
            }
            if imageStatus == .none {
                // If there is no image, put some text from the .url file into the icon.
                DescriptionText(description: model.description ?? "")
            }
        }
    }
}

struct DescriptionText: View {
    let description: String
    
    var body: some View {
        VStack {
            Text(description)
            Spacer()
        }
    }
}

// Put "url" text in the lower right of the icon.
struct URLTextInLowerRight: View {
    var body: some View {
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
