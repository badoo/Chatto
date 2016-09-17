/*
The MIT License (MIT)

Copyright (c) 2015-present Badoo Trading Limited.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/
import Foundation

public struct ReadOnlyOrderedDictionary<T>: Collection where T: UniqueIdentificable {

    fileprivate let items: [T]
    fileprivate let itemIndexesById: [String: Int] // Maping to the position in the array instead the item itself for better performance

    public init(items: [T]) {
        var dictionary = [String: Int](minimumCapacity: items.count)
        for (index, item) in items.enumerated() {
            dictionary[item.uid] = index
        }
        self.items = items
        self.itemIndexesById = dictionary
    }

    public func indexOf(_ uid: String) -> Int? {
        return self.itemIndexesById[uid]
    }

    public subscript(index: Int) -> T {
        return self.items[index]
    }

    public subscript(uid: String) -> T? {
        if let index = self.indexOf(uid) {
            return self.items[index]
        }
        return nil
    }

    public func makeIterator() -> IndexingIterator<[T]> {
        return self.items.makeIterator()
    }

    public var startIndex: Int {
        return 0
    }

    public var endIndex: Int {
        return self.items.count
    }
}
