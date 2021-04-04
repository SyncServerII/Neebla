
import Foundation
import SMLinkPreview
import UIKit

class URLPickerViewModel: ObservableObject {
    @Published var addButtonEnabled: Bool = false
    @Published var linkData: LinkData?
    @Published var loadedImage: LinkPreview.LoadedImage?
    
    // The url that the user has entered, and confirmed to add.
    @Published var selectedURL: URL?
    
    @Published var currentlyLoading: Bool = false
    
    private var boundedCancel:BoundedCancel?
        
    func onTextChange(text: String?) {
        addButtonEnabled = false
    }
    
    func onSearchButtonTapped(text: String?) {
        guard !currentlyLoading else {
            return
        }
        
        guard let text = text, let url = URL(string: text) else {
            return
        }
        
        currentlyLoading = true
        
        var getPreview:((LinkData?)->())?
        
        boundedCancel = BoundedCancel(maxInterval: 10, cancel: {
            getPreview = nil
            self.currentlyLoading = false
        })
        
        getPreview = { linkData in
            self.boundedCancel?.minimumCancel()
            self.currentlyLoading = false

            self.linkData = linkData
            if let _ = linkData {
                self.selectedURL = url
            }

            self.addButtonEnabled = linkData != nil
        }

        LocalServices.session.previewGenerator.getPreview(for: url) { linkData in
            getPreview?(linkData)
        }
    }
    
    func getResult() -> URLObjectTypeAssets? {
        guard let linkData = linkData else {
            return nil
        }
        
        return URLObjectTypeAssets(linkData: linkData, image: loadedImage)
    }
}
