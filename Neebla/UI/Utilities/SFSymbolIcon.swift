
import Foundation
import SwiftUI
import SFSafeSymbols

struct SFSymbolIcon: View {
    let symbol: SFSymbol
    
    var body: some View {
        Image(systemName: symbol.rawValue)
            .accentColor(.blue)
            .imageScale(.large)
            // The tappable area is too small; fat fingering. Trying to make it larger.
            .frame(width: Icon.dimension, height: Icon.dimension)
    }
}
