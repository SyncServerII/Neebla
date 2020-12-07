
import Foundation
import SMLinkPreview
import UIKit

class URLPickerViewModel: ObservableObject {
    @Published var addButtonEnabled: Bool = false
    @Published var linkData: LinkData?
    @Published var loadedImage: LinkPreview.LoadedImage?
    
    // The url that the user has entered, and confirmed to add.
    @Published var selectedURL: URL?
    
    func onTextChange(text: String?) {
        addButtonEnabled = false
    }
    
    func onSearchButtonTapped(text: String?) {
        guard let text = text, let url = URL(string: text) else {
            return
        }

        LocalServices.session.previewGenerator.getPreview(for: url) { [weak self] linkData in
            guard let self = self else { return }
            
            self.linkData = linkData
            if let _ = linkData {
                self.selectedURL = url
            }

            self.addButtonEnabled = linkData != nil
        }
    }
    
    func getResult() -> URLObjectTypeAssets? {
        guard let linkData = linkData else {
            return nil
        }
        
        return URLObjectTypeAssets(linkData: linkData, image: loadedImage)
    }
}
