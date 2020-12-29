
import Foundation

class PriorityQueue<T: AnyObject & BasicEquatable> {
    enum PriorityQueueError: Error {
        case badMaxLength
        case badResetLength
        case badLength
    }
    
    let maxLength: UInt
    
    // The current queue. current[0] is the head.
    private(set) var current = [T]()
    
    init(maxLength: UInt) throws {
        guard maxLength > 0 else {
            throw PriorityQueueError.badMaxLength
        }
        
        self.maxLength = maxLength
    }
    
    // Add an object at the head. If the object is already present, the queue doesn't grow, and the object just floats to the head, removed from where it was before. If the object was not present, and the queue is not at maxLength, adds a new element to the head, increasing the length. If the queue is already at maxLength, the object at the tail is removed. and the new one goes at the head.
    func add(object: T) {
        if let first = (current.firstIndex { $0.basicallyEqual(object) }) {
            // Object already exists in queue; remove it from where it; put it at beginning below.
            current.remove(at: first)
        }
        else if current.count >= maxLength {
            // Queue is at max length. Discard oldest.
            current.removeLast()
        }
        
        current.insert(object, at: 0)
    }

    // Count must be <= current.count, and this sequence of current is returned,
    // and those are removed from head, reducing the number of objects in the queue by
    // this number.
    @discardableResult
    func getInitial(_ count: UInt) throws -> [T] {
        guard count > 0 else {
            return []
        }
        
        return try reset(first: count)
    }
    
    // Returns all elements, resetting the queue.
    @discardableResult
    func getAll() throws -> [T] {
        return try reset()
    }
    
    // If first is nil, resets current to empty, returning the prior contents of the queue.
    // Otherwise, first must be <= current.count, and this sequence of current is returned,
    // and those are removed from head, reducing the number of objects in the queue by
    // this number.
    @discardableResult
    private func reset(first: UInt? = nil) throws -> [T] {
        if let first = first {
            guard first <= current.count else {
                throw PriorityQueueError.badResetLength
            }
            
            let result = Array(current[..<Int(first)])
            current.removeFirst(Int(first))
            return result
        }
        else {
            let result = current
            current = []
            return result
        }
    }
}
