
import Foundation
import SwiftUI
import SFSafeSymbols
import CustomModalView

struct AlbumItemsScreen: View {
    @ObservedObject var viewModel:AlbumItemsViewModel
    
    /* It seems hard to get the spacing to work out reasonably. At first, it looked OK on iPhone 11 but not on iPhone 8-- on iPhone 8 there was no spacing. In this case I was using:
    
        let gridItemLayout = [GridItem(.adaptive(minimum: 50), spacing: 20)]
      
      Just changing the `spacing` doesn't really help. What seems to be going on is that the LazyVGrid is trying to fit as many cells as it can per row. And if that means no spacing, then there is no spacing.
      
      What's helping is to use the image dimension as the minimum. This is looking OK on iPhone 8 and iPhone 11.
    */
    let gridItemLayout = [
        GridItem(.adaptive(minimum: GenericImageIcon.dimension), spacing: 5)
    ]
    
    @State var object: ServerObjectModel?
    
    var body: some View {
        VStack {
            RefreshableScrollView(refreshing: $viewModel.loading) {
                LazyVGrid(columns: gridItemLayout) {
                    ForEach(viewModel.objects, id: \.fileGroupUUID) { item in
                        AlbumItemsScreenCell(object: item)
                            .onTapGesture {
                                object = item
                                viewModel.showCellDetails = true
                            }
                    } // end ForEach
                } // end LazyVGrid
            }.padding(5)
            
            // Had a problem with return animation for a while: https://stackoverflow.com/questions/65101561
            // The solution was to take the NavigationLink out of the scrollview/LazyVGrid above.
            if let object = object {
                // The `NavigationLink` works here because the `MenuNavBar` contains a `NavigationView`.
                NavigationLink(
                    destination:
                        ObjectDetailsView(object: object),
                    isActive:
                        $viewModel.showCellDetails) {
                    EmptyView()
                }
                .frame(width: 0, height: 0)
                .disabled(true)
            } // end if
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
