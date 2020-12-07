import Foundation
import SwiftUI

// From: https://axelhodler.medium.com/creating-a-search-bar-for-swiftui-e216fe8c8c7f
struct SearchBar: UIViewRepresentable {
    let placeholderText: String
    let model: URLPickerViewModel
    
    init(placeholderText: String, model: URLPickerViewModel) {
        self.model = model
        self.placeholderText = placeholderText
    }

    class Coordinator: NSObject, UISearchBarDelegate {
        let model: URLPickerViewModel
        
        init(model: URLPickerViewModel) {
            self.model = model
        }

        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            model.onTextChange(text: searchText)
        }
        
        func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
            // Without the http or https, the link data lookup doesn't work.
            searchBar.text = addHttpIfNeeded(urlString: searchBar.text)
            
            model.onSearchButtonTapped(text: searchBar.text)
        }
        
        private func addHttpIfNeeded(urlString: String?) -> String? {
            if var urlString = urlString {
                // What if the initial part of the string has spaces? I'm going to also remove trailing spaces -- I think that won't alter the URL.
                urlString = urlString.trimmingCharacters(in: .whitespaces)

                if urlString.hasPrefix("http://") || urlString.hasPrefix("https://") {
                    return urlString
                }
                
                // Just picking one of https or http.
                return "http://" + urlString
            }
            
            return nil
        }
    }

    func makeCoordinator() -> SearchBar.Coordinator {
        return Coordinator(model: model)
    }

    func makeUIView(context: UIViewRepresentableContext<SearchBar>) -> UISearchBar {
        let searchBar = UISearchBar(frame: .zero)
        searchBar.delegate = context.coordinator
        searchBar.searchBarStyle = .minimal
        searchBar.placeholder = placeholderText
        searchBar.autocapitalizationType = .none
        return searchBar
    }

    func updateUIView(_ uiView: UISearchBar, context: UIViewRepresentableContext<SearchBar>) {
    }
}
