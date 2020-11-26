import Foundation
import SwiftUI
import CustomModalView

struct DefaultModalStyle: ModalStyle {
    let padding: CGFloat?
    let animation: Animation? = .easeInOut(duration: 0.5)
    
    init(padding: CGFloat? = nil) {
        self.padding = padding
    }
    
    func makeBackground(configuration: ModalStyle.BackgroundConfiguration, isPresented: Binding<Bool>) -> some View {
        configuration.background
            .edgesIgnoringSafeArea(.all)
            .foregroundColor(.black)
            .opacity(0.3)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .zIndex(1000)
            .onTapGesture {
                isPresented.wrappedValue = false
            }
    }
    
    func makeModal(configuration: ModalStyle.ModalContentConfiguration, isPresented: Binding<Bool>) -> some View {
        configuration.content
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .zIndex(1001)
            .padding(padding ?? 0)
    }
}


