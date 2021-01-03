//
//  AddressNavigation.swift
//  SharedImages
//
//  Created by Christopher G Prince on 4/6/19.
//  Copyright © 2019 Spastic Muffin, LLC. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit
import MapKit
import iOSShared

class AddressNavigation {
    let geocoder = CLGeocoder()
    
    func navigate(to address: String) {
        geocoder.geocodeAddressString(address) { placemarks, error in
            if let error = error {
                logger.error("\(error)")
                Services.session.serverInterface.userEvent = .showAlert(title: "Alert!", message: "Could not lookup address.")
                return
            }
            
            guard let placemarks = placemarks, placemarks.count > 0 else {
                Services.session.serverInterface.userEvent = .showAlert(title: "Alert!", message: "Problem looking up address.")
                return
            }
                        
            let mapItems = placemarks.map {
                MKMapItem(placemark: MKPlacemark(placemark: $0))
            }
            
            guard MKMapItem.openMaps(with: mapItems, launchOptions: nil) else {
                Services.session.serverInterface.userEvent = .showAlert(title: "Alert!", message: "Could not open maps app.")
                return
            }
        }
    }
}
