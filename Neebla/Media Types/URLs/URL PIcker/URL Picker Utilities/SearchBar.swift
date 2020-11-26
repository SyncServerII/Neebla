import Foundation
import SwiftUI

// From: https://axelhodler.medium.com/creating-a-search-bar-for-swiftui-e216fe8c8c7f
struct SearchBar: UIViewRepresentable {
    let placeholderText: String
    let model: URLPickerModel
    
    init(placeholderText: String, model: URLPickerModel) {
        self.model = model
        self.placeholderText = placeholderText
    }

    class Coordinator: NSObject, UISearchBarDelegate {
        let model: URLPickerModel
        
        init(model: URLPickerModel) {
            self.model = model
        }

        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            model.onTextChange(text: searchText)
        }
        
        func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
            model.onSearchButtonTapped(text: searchBar.text)
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
