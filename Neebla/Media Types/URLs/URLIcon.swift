
import Foundation
import SwiftUI

struct URLIcon: View {
    @StateObject var model:URLModel
    @StateObject var imageModel:GenericImageModel
    let config: IconConfig
    
    var body: some View {
        ZStack {
            GenericImageIcon(model:imageModel, config: config)
                .lowerRightText("url")

            if imageModel.imageStatus == .none {
                // If there is no image, put some text from the .url file into the icon.
                DescriptionText(description: model.description ?? "")
            }
        }.onAppear() {
            model.getDescriptionText()
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

