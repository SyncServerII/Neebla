import Foundation
import SwiftUI

struct AlbumItemsScreenCell: View {
    @ObservedObject var object:ServerObjectModel

    var body: some View {
        AnyIcon(object: object)
    }
}
