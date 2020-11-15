//
//  ItemProviderFactory.swift
//  Share
//
//  Created by Christopher G Prince on 10/6/20.
//

import Foundation

class ItemProviderFactory {
    enum ItemProviderFactoryError: Error {
        case noTypeIdentifiers
        case noMatchingTypeIdentifiers
        case couldNotGetURL
    }
    
    static let providers:[ItemProvider.Type] = [
        ImageItemProvider.self
    ]
    
    static func create(using attachment: NSItemProvider, completion: @escaping (Result<ItemProvider, Error>)->()) throws {
        
        for provider in providers {
            guard provider.typeIdentifiers.count > 0 else {
                throw ItemProviderFactoryError.noTypeIdentifiers
            }
            
            var type: String?
            
            for typeIdentifier in provider.typeIdentifiers {
                if attachment.hasItemConformingToTypeIdentifier(typeIdentifier) {
                    type = typeIdentifier
                }
            }
            
            guard let typeIdentifier = type else {
                continue
            }

            attachment.loadItem(forTypeIdentifier: typeIdentifier, options: nil) { data, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let url = data as? URL else {
                    completion(.failure(ItemProviderFactoryError.couldNotGetURL))
                    return
                }
                
                do {
                    let result = try provider.init(url: url)
                    completion(.success(result))
                }
                catch let error {
                    completion(.failure(error))
                }
            }
            
            return
        }
        
        throw ItemProviderFactoryError.noMatchingTypeIdentifiers
    }
}
