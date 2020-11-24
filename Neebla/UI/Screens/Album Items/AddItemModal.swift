
import Foundation
import SwiftUI
import CustomModalView

struct AddItemModal: View {
    @Environment(\.modalPresentationMode) var modalPresentationMode: Binding<ModalPresentationMode>
    @ObservedObject var viewModel:AlbumItemsViewModel
    let dimisser = MediaTypeListDismisser()
    
    init(viewModel:AlbumItemsViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        dimisser.didDismiss = { acquiredNewMediaItem in
            if acquiredNewMediaItem {
                // Update the view with the new media item.
                viewModel.updateAfterAddingItem()
                
                modalPresentationMode.wrappedValue.dismiss()
            }
        }
        
        return VStack(spacing: 32) {
            Text("Add new:")

            MediaTypeListView(album: viewModel.sharingGroupUUID, alertMessage: viewModel, dismisser: dimisser)

            Button(action: {
                modalPresentationMode.wrappedValue.dismiss()
            }) {
                Text("Cancel")
            }
        }
    }
}
