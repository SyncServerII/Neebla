
import Foundation
import SwiftUI
import CustomModalView

struct ItemOptionsModal: View {
    @Environment(\.modalPresentationMode) var modalPresentationMode: Binding<ModalPresentationMode>
    
    var body: some View {
        return VStack(spacing: 15) {
            Text("Options:")
            
            Spacer()
                .frame(height: 10)
            
            Button(action: {
            }) {
                Text("View large image")
            }
            
            Button(action: {
            }) {
                Text("Discussion")
            }
            
            Spacer()
                .frame(height: 10)
                
            Button(action: {
                modalPresentationMode.wrappedValue.dismiss()
            }) {
                Text("Cancel")
            }
        }
    }
}
