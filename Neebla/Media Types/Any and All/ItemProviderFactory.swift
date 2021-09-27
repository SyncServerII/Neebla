//
//  ItemProviderFactory.swift
//  Share
//
//  Created by Christopher G Prince on 10/6/20.
//

import Foundation

class ItemProviderFactory {
    var handle: Any?
    
    enum ItemProviderFactoryError: Error {
        case couldNotHandleItem
        case couldNotGetURL
    }
    
    // The order in this list matters. If one provider works, the following are not tried.
    static let providers:[SXItemProvider.Type] = [
        // Try this first. If we put `ImageItemProvider` first and the image available is JPEG, it will succeed and the live image will never succeed.
        LiveImageItemProvider.self,

        ImageItemProvider.self,
        URLItemProvider.self,
        GIFItemProvider.self
    ]
    
    func create(using attachments: [NSItemProvider], completion: @escaping (Result<SXItemProvider, Error>)->()) {
        
        // `canHandle` can have false positives. May have to try more than one.
        let dispatchGroup = DispatchGroup()
        var success = false
        
        for provider in Self.providers {
            for attachment in attachments {
                if provider.canHandle(item: attachment) {
                    dispatchGroup.enter()
                    
                    handle = provider.create(item: attachment) { result in
                        dispatchGroup.leave()
                        
                        switch result {
                        case .success(let provider):
                            success = true
                            completion(.success(provider))
                            return
                            
                        case .failure:
                            // Continue in loop
                            break
                        }
                    }
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            guard success else {
                completion(.failure(ItemProviderFactoryError.couldNotHandleItem))
                return
            }
        }
    }
}
