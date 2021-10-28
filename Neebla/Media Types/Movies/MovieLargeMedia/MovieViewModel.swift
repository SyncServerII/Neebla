//
//  MovieViewModel.swift
//  Neebla
//
//  Created by Christopher G Prince on 10/26/21.
//

import Foundation
import iOSShared

class MovieViewModel {
    let movieFileLabel = MovieObjectType.movieDeclaration.fileLabel
    var movieURL: URL?
    
    init(fileGroupUUID: UUID) {
        do {
            let movieFileModel = try ServerFileModel.getFileFor(fileLabel: movieFileLabel, withFileGroupUUID: fileGroupUUID)
            guard let url = movieFileModel.url else {
                logger.error("No movie URL")
                return
            }
            movieURL = url
        } catch let error {
            logger.error("\(error)")
        }
    }
}
