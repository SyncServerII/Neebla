
import Foundation
import SwiftUI

struct ObjectDetailsView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var object:ServerObjectModel?
    
    init(object:Binding<ServerObjectModel?>) {
        self._object = object
    }
    
    var body: some View {
        VStack {
            // Top buttons
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }, label: {
                    Text("Cancel")
                })
                .padding(.leading, 10)
                .padding(.top, 10)
                
                Spacer()
            }
            .frame(height: 40)

            if let object = object {
                AnyLargeMedia(object: object)
            }
            else {
                Rectangle()
                .fill(Color.white)
            }
            
            Spacer()
        }
    }
}
