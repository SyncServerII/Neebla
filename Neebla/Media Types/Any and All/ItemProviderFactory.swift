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
        case couldNotGetContent
    }
    
    // The order in this list matters. If one provider works, the following are not tried.
    static let providers:[SXItemProvider.Type] = [
        // Try this first. If we put `ImageItemProvider` first and the image available is JPEG, it will succeed and the live image will never succeed.
        LiveImageItemProvider.self,

        MovieItemProvider.self,
        ImageItemProvider.self,
        URLItemProvider.self,
        GIFItemProvider.self
    ]
    
    func create(using attachments: [NSItemProvider], completion: @escaping (Result<SXItemProvider, Error>)->()) {
    
        // 10/27/21; This is ugly. It is serializing the calls to the different `provider.create` methods. I thought I had this working before with DispatchGroup, but really it did it all in parallel! Not what I wanted. Maybe change to using the new Swift `await` primitive (iOS 15 only I think)?
        
        // `canHandle` can have false positives. May have to try more than one.
        var success = false
        var possibleFinalError: Error?
        let createQueue = DispatchQueue(label: "ItemProviderFactory")
        
        DispatchQueue.global().async {
            let semaphore = DispatchSemaphore(value: 0)
            
            for provider in Self.providers {
                for attachment in attachments {
                    if provider.canHandle(item: attachment) {
                        
                        createQueue.async {
                            self.handle = provider.create(item: attachment) { result in
                                switch result {
                                case .success(let provider):
                                    success = true
                                    completion(.success(provider))
                                    semaphore.signal()
                                    return
                                    
                                case .failure(let error):
                                    // Some of these are real failures and ought to be displayed to the user. E.g., if we get a .failure, and then no other provider actually can handle the item.
                                    possibleFinalError = error
                                    
                                    // Continue in loop
                                    semaphore.signal()
                                    break
                                }
                            }
                        }
                        
                        semaphore.wait()
                        
                        if success {
                            return
                        }
                    }
                }
            } // end for
            
            guard success else {
                completion(.failure(possibleFinalError ?? ItemProviderFactoryError.couldNotHandleItem))
                return
            }
        } // end DispatchQueue.global().async
    }
    
    func create(from content: ItemProviderContent) -> Result<UploadableMediaAssets, Error> {
        for provider in Self.providers {
            if let result = provider.create(from: content) {
                return result
            }
        }
        
        return .failure(ItemProviderFactoryError.couldNotGetContent)
    }
}
