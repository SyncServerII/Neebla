
import Foundation
import SwiftUI
import SwiftUIRefresh
import SFSafeSymbols
import CustomModalView

struct AlbumItemsScreen: View {
    @ObservedObject var viewModel:AlbumItemsViewModel

    var body: some View {
        List(viewModel.objects, id: \.fileGroupUUID) { item in
            AlbumItemsScreenRow(object: item)
        }
        .pullToRefresh(isShowing: $viewModel.isShowingRefresh) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                viewModel.sync()
            }
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

    var body: some View {
        VStack {
            Text(object.fileGroupUUID.uuidString)
        }
    }
}

private struct AddItemModal: View {
    @Environment(\.modalPresentationMode) var modalPresentationMode: Binding<ModalPresentationMode>
    @ObservedObject var viewModel:AlbumItemsViewModel
    
    init(viewModel:AlbumItemsViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        VStack(spacing: 32) {
            Text("Add new:")

            MediaTypeListView(album: viewModel.sharingGroupUUID, alertMessage: viewModel)
            
            Button(action: {
                modalPresentationMode.wrappedValue.dismiss()
            }) {
                Text("Cancel")
            }
        }
    }
}
