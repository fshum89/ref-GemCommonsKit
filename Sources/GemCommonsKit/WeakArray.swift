//
//  Copyright (c) 2021 gematik GmbH
//  
//  Licensed under the Apache License, Version 2.0 (the License);
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  
//      http://www.apache.org/licenses/LICENSE-2.0
//  
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an 'AS IS' BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation

/// A Collection similar to an array, but wraps its Elements in a `WeakRef`.
public class WeakArray<T: Any> {
    private var _array = [WeakRef<AnyObject>]()

    /// Initialize an empty WeakArray
    public init() {}

    /// Add an object reference to the array
    /// - Parameter object: the object to weak reference before adding it to the array
    public func add(object: T) {
        let ref = makePointer(object)
        _array.append(ref)
    }

    /// Dereference the object at index when not released
    /// - Parameter index: index to get
    /// - Returns: The object when not deinitialized
    public func object(at index: Int) -> T? {
        guard index < count, let pointer = _array[index].value else {
            return nil
        }
        guard let object = pointer as? T else {
            return nil
        }
        return object
    }

    /// Insert an object reference at a specified index
    /// - Parameters:
    ///     - object: the object to weak reference before adding it to the array
    ///     - index: the index to insert at
    public func insert(object: T, at index: Int) {
        guard index < count else {
            return
        }
        _array.insert(makePointer(object), at: index)
    }

    /// Replace a weak reference with a new object
    /// - Parameters:
    ///     - index: the index to replace
    ///     - object: the object to weak reference before replacing the reference at index
    public func replaceObject(at index: Int, with object: T) {
        guard index < count else {
            return
        }
        _array[index] = makePointer(object)
    }

    /// Remove an object reference at a specified index
    /// - Parameter index: index of the reference to remove
    public func removeObject(at index: Int) {
        guard index < count else {
            return
        }
        _array.remove(at: index)
    }

    /// Get the current count of available (not-released) object references
    /// - Note: complexity O(n) - since we filter out the zeroed `WeakRef`s
    /// - Returns: the current active reference count
    public var count: Int {
        _array = _array.filter { $0.value != nil }
        return _array.count
    }

    /// Dereference the object at index when not released
    /// - Parameter index: index to get
    /// - See: object(at:)
    /// - Returns: The object when not deinitialized
    public subscript(index: Int) -> T? {
        return self.object(at: index)
    }

    /// Find the index of an object in the array
    /// - Parameter object: the object to search for
    /// - Note: complexity O(2n)
    /// - Returns: the index when found else nil
    public func index(of object: T) -> Int? {
        let anyObject = object as AnyObject
        for index in 0..<count {
            if let current = self[index] as AnyObject?, current === anyObject {
                return index
            }
        }
        return nil
    }
}

private func makePointer(_ object: Any) -> WeakRef<AnyObject> {
    let strongObject = object as AnyObject
    let ref = WeakRef(strongObject)
    return ref
}

extension WeakArray {
    /// Convenience initializer for weak referencing an entire array
    /// - Parameter objects: the object to weak reference in the newly initialized WeakArray
    public convenience init(objects: [T]) {
        self.init()
        objects.forEach {
            add(object: $0)
        }
    }

    /// Get objects referenced by `Self` as a strong array
    /// - Returns: Array with available objects
    public var array: [T] {
        return _array.compactMap {
            $0.value as? T
        }
    }
}

extension Array where Element: AnyObject {
    /// Create a WeakArray with elements from `Self`
    /// - Returns: WeakArray with references to all Elements in `Self`
    public var weakArray: WeakArray<Element> {
        return WeakArray(objects: self)
    }
}
