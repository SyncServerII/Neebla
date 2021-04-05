
import Foundation
import SMLinkPreview
import UIKit
import iOSShared

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
        
        guard let urlText = text,
            let url = URL(string: urlText.trimmingCharacters(in: .whitespaces)) else {
            logger.error("Malformed URL text: '\(String(describing: text))'")
            showAlert(AlertyHelper.alert(title: "Alert!", message: "That URL doesn't seem right. Try removing it and pasting/typing it again?"))
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
            else {
                showAlert(AlertyHelper.alert(title: "Alert!", message: "Could not load that URL. Please try again."))
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
