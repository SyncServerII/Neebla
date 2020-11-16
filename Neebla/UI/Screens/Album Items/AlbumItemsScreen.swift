
import Foundation
import SwiftUI
import SwiftUIRefresh
import SFSafeSymbols
import CustomModalView

struct AlbumItemsScreen: View {
    @ObservedObject var viewModel:AlbumItemsViewModel

    var body: some View {
        List(viewModel.objects, id: \.fileGroupUUID) { item in
            AlbumItemsScreenRow(object: item, viewModel: viewModel)
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
    @ObservedObject var viewModel:AlbumItemsViewModel
    private let filesForObject: [ServerFileModel]
    
    init(object:ServerObjectModel, viewModel:AlbumItemsViewModel) {
        self.object = object
        self.viewModel = viewModel
        filesForObject = viewModel.filesFor(fileGroupUUID: object.fileGroupUUID)
    }

    var body: some View {
        VStack {
            Text("\(object.fileGroupUUID.uuidString); files: \(filesForObject.count)")
            ForEach(filesForObject, id: \.fileUUID) { file in
                if let url = file.url {
                    Text("\(url)")
                }
            }
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
