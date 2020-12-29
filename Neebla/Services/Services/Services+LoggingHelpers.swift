//
//  Services+LoggingHelpers.swift
//  iOSIntegration
//
//  Created by Christopher G Prince on 10/3/20.
//

import Foundation
import Logging
import FileLogging
import iOSShared

extension Services {
    private func logFileURL() -> URL {
        return Files.getDocumentsDirectory().appendingPathComponent(logFileName)
    }
    
    // Subsequent uses of the `logger` will log both to a file and the Xcode console.
    // Only call this once, during app launch.
    func setupLogging() throws {
        let loggingURL = logFileURL()
        let fileLogger = try FileLogging(to: loggingURL)

        LoggingSystem.bootstrap { label in
            let handlers:[LogHandler] = [
                FileLogHandler(label: label, fileLogger: fileLogger),
                StreamLogHandler.standardOutput(label: label)
            ]

            return MultiplexLogHandler(handlers)
        }
    }
    
    var currentLogFileContents: String? {
        let url = logFileURL()
        
        guard let data = try? Data(contentsOf: url) else {
            logger.error("Could not read data from log file URL: \(url)")
            return nil
        }
        
        guard let logString = String(data: data, encoding: .utf8) else {
            logger.error("Could not convert log data to a string")
            return nil
        }
        
        return logString
    }
}
