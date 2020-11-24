
import Foundation
import SwiftUI
import SFSafeSymbols
import CustomModalView

struct AlbumItemsScreen: View {
    @ObservedObject var viewModel:AlbumItemsViewModel
    let gridItemLayout = [GridItem(.adaptive(minimum: 50), spacing: 20)]
    @State var objectTapped:ServerObjectModel?
    @State var showCellDetails = false
    
    var body: some View {
        RefreshableScrollView(refreshing: $viewModel.loading) {
            LazyVGrid(columns: gridItemLayout) {
                ForEach(viewModel.objects, id: \.fileGroupUUID) { item in
                    AlbumItemsScreenCell(object: item, showCellDetails: $showCellDetails, cellTapped: $objectTapped)
                }
            }
            .padding(10)
        }
        .alert(isPresented: $viewModel.presentAlert, content: {
            let message:String = viewModel.alertMessage
            viewModel.alertMessage = nil
            return Alert(title: Text(message))
        })
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
        .disabled(viewModel.addNewItem)
        .modal(isPresented: $viewModel.addNewItem) {
            AddItemModal(viewModel: viewModel)
                .padding(20)
        }
        .modalStyle(DefaultModalStyle())
        .sheet(isPresented: $showCellDetails) {
            ObjectDetailsView(object: $objectTapped)
        }
        .onDisappear {
            // I'm having a problem with the modal possibly being presented, the user navigating away, coming back and the modal still being present.
            if viewModel.addNewItem == true {
                viewModel.addNewItem = false
            }
        }
    }
}

