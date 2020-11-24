import Foundation
import SwiftUI

struct AlbumItemsScreenCell: View {
    @ObservedObject var object:ServerObjectModel
    @Binding var showCellDetails:Bool
    @Binding var cellTapped:ServerObjectModel?
    
    init(object:ServerObjectModel, showCellDetails:Binding<Bool>, cellTapped: Binding<ServerObjectModel?>) {
        self.object = object
        self._showCellDetails = showCellDetails
        self._cellTapped = cellTapped
    }

    var body: some View {
        AnyIcon(object: object)
            .onTapGesture {
                self.cellTapped = object
                self.showCellDetails = true
            }
    }
}
