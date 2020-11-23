
import Foundation
import SwiftUI
import SFSafeSymbols
import CustomModalView

struct AlbumItemsScreen: View {
    @ObservedObject var viewModel:AlbumItemsViewModel
    let gridItemLayout = [GridItem(.adaptive(minimum: 50), spacing: 20)]

    var body: some View {
        RefreshableScrollView(refreshing: $viewModel.loading) {
            LazyVGrid(columns: gridItemLayout) {
                ForEach(viewModel.objects, id: \.fileGroupUUID) { item in
                    AlbumItemsScreenCell(object: item)
                }
            }
            .padding(10)
        }
        .alert(isPresented: $viewModel.presentAlert, content: {
            let message:String = viewModel.alertMessage
            viewModel.alertMessage = nil
            return Alert(title: Text(message))
        })
        .modal(isPresented: $viewModel.addNewItem) {
            AddItemModal(viewModel: viewModel)
                .padding(20)
        }
        .modalStyle(DefaultModalStyle())
        .navigationBarTitle("Album Contents")
        .navigationBarItems(trailing:
            HStack(spacing: 0) {
                Button(
                    action: {
                        viewModel.sync()
                    },
                    label: {
                        Image(systemName: SFSymbol.goforward.rawValue)
                            .imageScale(.large)
                            // The tappable area is too small; fat fingering. Trying to make it larger.
                            .frame(width: 50, height: 50)
                    }
                )
                
                Button(
                    action: {
                        viewModel.startNewAddItem()
                    },
                    label: {
                        Image(systemName: SFSymbol.plusCircle.rawValue)
                            .imageScale(.large)
                            // The tappable area is too small; fat fingering. Trying to make it larger.
                            .frame(width: 50, height: 50)
                    }
                )
            }
        )
    }
}

private struct AlbumItemsScreenCell: View {
    @ObservedObject var object:ServerObjectModel
    
    init(object:ServerObjectModel) {
        self.object = object
    }

    var body: some View {
        AnyIcon(object: object)
    }
}

private struct AddItemModal: View {
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
