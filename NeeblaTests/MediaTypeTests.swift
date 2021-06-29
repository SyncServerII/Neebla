//
//  MediaTypeTests.swift
//  NeeblaTests
//
//  Created by Christopher G Prince on 2/13/21.
//

import XCTest
@testable import Neebla

class MediaTypeTests: XCTestCase {
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testCGSizeExtras() throws {
        let dataSet: [(width:CGFloat, height:CGFloat, expected: Bool)] = [
            (width: 0, height: 100, expected: false),
            (width: 100, height: 0, expected: false),
            (width: 4, height: 100, expected: false),
            (width: 100, height: 4, expected: false),
            (width: 10, height: 100, expected: true),
            (width: 100, height: 10, expected: true),
            (width: 100, height: 100, expected: true),
        ]
        
        for datum in dataSet {
            let size = CGSize(width: datum.width, height:datum.height)
            XCTAssert(size.isOK() == datum.expected, "\(size)")
        }
    }
}
