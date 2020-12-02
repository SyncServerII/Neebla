
import Foundation
import SwiftUI
import SFSafeSymbols
import CustomModalView

struct AlbumItemsScreen: View {
    @ObservedObject var viewModel:AlbumItemsViewModel
    let gridItemLayout = [GridItem(.adaptive(minimum: 50), spacing: 20)]
    @State var object: ServerObjectModel?
    @State var enableNavLink: Bool = false
    
    var body: some View {        
        RefreshableScrollView(refreshing: $viewModel.loading) {
            LazyVGrid(columns: gridItemLayout) {
                ForEach(viewModel.objects, id: \.fileGroupUUID) { item in
                    AlbumItemsScreenCell(object: item)
                        .onTapGesture {
                            object = item
                            viewModel.showCellDetails = true
                        }

                    // Without this conditional, "spacer" cells show up in the grid.
                    if viewModel.showCellDetails, let object = object {
                        // The `NavigationLink` works here because the `MenuNavBar` contains a `NavigationView`.
                        NavigationLink(
                            destination:
                                // If I just use `item` directly in this-- oddly, it doesn't reference the same object as for `AlbumItemsScreenCell` above.
                                ObjectDetailsView(object: object),
                            isActive:
                                $viewModel.showCellDetails) {
                        }
                    } // end if
                } // end ForEach
            } // end LazyVGrid
            .padding(10)
        }
        .alert(isPresented: $viewModel.presentAlert, content: {
            let message:String = viewModel.alertMessage
            viewModel.alertMessage = nil
            return Alert(title: Text(message))
        })
        .navigationBarTitle("Album Contents")
        .navigationBarItems(trailing:
            AlbumItemsScreenNavButtons(viewModel: viewModel)
        )
        .disabled(viewModel.addNewItem)
        .modal(isPresented: $viewModel.addNewItem) {
            AddItemModal(viewModel: viewModel)
                .padding(20)
        }
        .modalStyle(DefaultModalStyle())
        .onDisappear {
            // I'm having a problem with the modal possibly being presented, the user navigating away, coming back and the modal still being present.
            // See also https://github.com/jankaltoun/CustomModalView/issues/1
            if viewModel.addNewItem == true {
                viewModel.addNewItem = false
            }
        }
    }
}

private struct AlbumItemsScreenNavButtons: View {
    @ObservedObject var viewModel:AlbumItemsViewModel
    
    var body: some View {
        HStack(spacing: 0) {
            Button(
                action: {
                    viewModel.sync()
                },
                label: {
                    SFSymbolNavBar(symbol: .goforward)
                }
            )
            
            Button(
                action: {
                    viewModel.startNewAddItem()
                },
                label: {
                    SFSymbolNavBar(symbol: .plusCircle)
                }
            )
        }
    }
}
