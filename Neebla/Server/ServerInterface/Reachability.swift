//
//  Reachability.swift
//  Neebla
//
//  Created by Christopher G Prince on 2/21/21.
//

import Foundation
import Combine
import Hyperconnectivity
import iOSShared

class Reachability: ObservableObject, NetworkReachability {
    @Published private(set) var isReachable: Bool = false
    private var cancellable: AnyCancellable!
    
    init() {
        cancellable = Hyperconnectivity.Publisher()
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
            .sink(receiveValue: { [weak self] connectivityResult in
                self?.isReachable = connectivityResult.isConnected
                logger.debug("isReachable: \(String(describing: self?.isReachable))")
            })
    }
}
