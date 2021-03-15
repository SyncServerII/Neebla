//
//  AboutAppModel.swift
//  Neebla
//
//  Created by Christopher G Prince on 3/14/21.
//

import Foundation
import iOSShared

class AboutAppModel: ObservableObject {
    @Published var html: String?
    let aboutDocs = ("AboutApp", "html")
    
    init() {
        guard let fileURL = Bundle.main.url(forResource: aboutDocs.0, withExtension: aboutDocs.1) else {
            logger.error("Could not load file from bundle: \(aboutDocs)")
            return
        }
        
        guard let helpData = try? Data(contentsOf: fileURL) else {
            logger.error("Could not load data from file")
            return
        }
        
        html = String(data: helpData, encoding: .utf8)
        logger.debug("help string: \(String(describing: html))")
    }
}
