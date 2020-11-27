//
//  PriorityQueueTests.swift
//  PriorityQueueTests
//
//  Created by Christopher G Prince on 11/26/20.
//

import XCTest
@testable import Neebla

class TestObject: BasicEquatable {
    let id = UUID()
    
    func basicallyEqual(_ other: TestObject) -> Bool {
        return id == other.id
    }
}

class PriorityQueueTests: XCTestCase {
    var queue = try! PriorityQueue<TestObject>(maxLength: 2);
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testAddToEmpty() throws {
        let obj = TestObject()
        XCTAssert(queue.current.count == 0)
        queue.add(object: obj)
        XCTAssert(queue.current.count == 1)
        XCTAssert(queue.current[0].id == obj.id)
    }
    
    func testAddToNonEmptyNonFull() throws {
        let obj1 = TestObject()
        queue.add(object: obj1)
        let obj2 = TestObject()
        queue.add(object: obj2)
        XCTAssert(queue.current.count == 2)
        XCTAssert(queue.current[0].id == obj2.id)
        XCTAssert(queue.current[1].id == obj1.id)
    }
    
    func testAddToFull() throws {
        let obj1 = TestObject()
        queue.add(object: obj1)
        let obj2 = TestObject()
        queue.add(object: obj2)
        let obj3 = TestObject()
        queue.add(object: obj3)
        XCTAssert(queue.current.count == 2)
        XCTAssert(queue.current[0].id == obj3.id)
        XCTAssert(queue.current[1].id == obj2.id)
    }
    
    func testAddWhereObjectExists() throws {
        let obj1 = TestObject()
        queue.add(object: obj1)
        let obj2 = TestObject()
        queue.add(object: obj2)
        
        queue.add(object: obj2)
        
        XCTAssert(queue.current[0].id == obj2.id)
        XCTAssert(queue.current[1].id == obj1.id)
    }
    
    func testFullReset() throws {
        let obj1 = TestObject()
        queue.add(object: obj1)
        let obj2 = TestObject()
        queue.add(object: obj2)
        
        let result = try queue.reset()
        
        XCTAssert(result[0].id == obj2.id)
        XCTAssert(result[1].id == obj1.id)
        
        XCTAssert(queue.current.count == 0)
    }
    
    func testPartialReset() throws {
        let obj1 = TestObject()
        queue.add(object: obj1)
        let obj2 = TestObject()
        queue.add(object: obj2)
        
        let result = try queue.reset(first: 1)
        
        XCTAssert(result[0].id == obj2.id)
        
        XCTAssert(queue.current.count == 1)
        XCTAssert(queue.current[0].id == obj1.id)
    }
}
