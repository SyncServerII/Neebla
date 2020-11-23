import Foundation
import SwiftUI
import SMLinkPreview
import iOSShared

struct URLPickerView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding private var resultURL: LinkMedia?
    @ObservedObject var model = URLPickerModel()
    
    let placeholderText: String = "Enter your website (web link/URL)"
    
    init(resultURL: Binding<LinkMedia?>) {
        _resultURL = resultURL
    }
    
    var body: some View {
        VStack {
            SearchBar(placeholderText: placeholderText, model: model)

            if let linkData = model.linkData {
                URLPreviewView(linkData: linkData, model: model)
            }
            else {
                Rectangle()
                    .fill(Color.white)
            }
            
            // Bottom buttons
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }, label: {
                    Text("Cancel")
                })
                .padding(.leading, 10)
                
                Spacer()
                
                Button(action: {
                    if let result = model.getResult() {
                        resultURL = result
                        presentationMode.wrappedValue.dismiss()
                    }
                }, label: {
                    Text("Add")
                })
                .enabled(model.addButtonEnabled)
                .padding(.trailing, 10)
            }
            .frame(height: 40)
            .border(Color.black)
        }
    }
}
