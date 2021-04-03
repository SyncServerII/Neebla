import Foundation
import SwiftUI
import SMLinkPreview
import iOSShared

struct URLPickerView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var model = URLPickerViewModel()
    let placeholderText: String = "Enter your website (web link/URL)"
    let picked: (URLObjectTypeAssets)->()

    init(picked: @escaping (URLObjectTypeAssets)->()) {
        self.picked = picked
    }
    
    var body: some View {
        ZStack {
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
                            picked(result)
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
            
            ProgressView("Loading...")
                .scaleEffect(2, anchor: .center)
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                .foregroundColor(.blue)
                .isHidden(!model.showProgressView, remove: true)
        }
    }
}
