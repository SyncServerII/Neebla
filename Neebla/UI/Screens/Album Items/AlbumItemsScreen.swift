
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
                    AlbumItemsScreenRow(object: item)
                }
            }
            .padding(10)
        }
        .alert(isPresented: $viewModel.presentAlert, content: {
            Alert(title: Text(viewModel.alertMessage))
        })
        .modal(isPresented: $viewModel.addNewItem) {
            AddItemModal(viewModel: viewModel)
                .padding(20)
        }
        .modalStyle(DefaultModalStyle())
        .navigationBarTitle("Album Images")
        .navigationBarItems(trailing:
            Button(
                action: {
                    viewModel.startNewAddItem()
                },
                label: {
                    Image(systemName: SFSymbol.plusCircle.rawValue)
                }
            )
        )
    }
}

private struct AlbumItemsScreenRow: View {
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
                // Do a sync to update the view with the new media item.
                viewModel.sync()
                
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
