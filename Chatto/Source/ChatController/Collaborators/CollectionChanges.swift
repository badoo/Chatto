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

public protocol UniqueIdentificable {
    var uid: String { get }
}

public struct CollectionChangeMove: Equatable, Hashable {
    public let indexPathOld: IndexPath
    public let indexPathNew: IndexPath
    public init(indexPathOld: IndexPath, indexPathNew: IndexPath) {
        self.indexPathOld = indexPathOld
        self.indexPathNew = indexPathNew
    }

    public var hashValue: Int { return indexPathOld.hashValue ^ indexPathNew.hashValue }
}

public func == (lhs: CollectionChangeMove, rhs: CollectionChangeMove) -> Bool {
    return lhs.indexPathOld == rhs.indexPathOld && lhs.indexPathNew == rhs.indexPathNew
}

public struct CollectionChanges {
    public let insertedIndexPaths: Set<IndexPath>
    public let deletedIndexPaths: Set<IndexPath>
    public let movedIndexPaths: [CollectionChangeMove]

    init(insertedIndexPaths: Set<IndexPath>, deletedIndexPaths: Set<IndexPath>, movedIndexPaths: [CollectionChangeMove]) {
        self.insertedIndexPaths = insertedIndexPaths
        self.deletedIndexPaths = deletedIndexPaths
        self.movedIndexPaths = movedIndexPaths
    }
}

func generateChanges(oldCollection: [UniqueIdentificable], newCollection: [UniqueIdentificable]) -> CollectionChanges {
    func generateIndexesById(_ uids: [String]) -> [String: Int] {
        var map = [String: Int](minimumCapacity: uids.count)
        for (index, uid) in uids.enumerated() {
            map[uid] = index
        }
        return map
    }

    let oldIds = oldCollection.map { $0.uid }
    let newIds = newCollection.map { $0.uid }
    let oldIndexsById = generateIndexesById(oldIds)
    let newIndexsById = generateIndexesById(newIds)
    var deletedIndexPaths = Set<IndexPath>()
    var insertedIndexPaths = Set<IndexPath>()
    var movedIndexPaths = [CollectionChangeMove]()

    // Deletetions
    for oldId in oldIds {
        let isDeleted = newIndexsById[oldId] == nil
        if isDeleted {
            deletedIndexPaths.insert(IndexPath(item: oldIndexsById[oldId]!, section: 0))
        }
    }

    // Insertions and movements
    for newId in newIds {
        let newIndex = newIndexsById[newId]!
        let newIndexPath = IndexPath(item: newIndex, section: 0)
        if let oldIndex = oldIndexsById[newId] {
            if oldIndex != newIndex {
                movedIndexPaths.append(CollectionChangeMove(indexPathOld: IndexPath(item: oldIndex, section: 0), indexPathNew: newIndexPath))
            }
        } else {
            // It's new
            insertedIndexPaths.insert(newIndexPath)
        }
    }

    return CollectionChanges(insertedIndexPaths: insertedIndexPaths, deletedIndexPaths: deletedIndexPaths, movedIndexPaths: movedIndexPaths)
}

func updated<T: Any>(collection: [IndexPath: T], withChanges changes: CollectionChanges) -> [IndexPath: T] {
    var result = collection

    changes.deletedIndexPaths.forEach { (indexPath) in
        result[indexPath] = nil
    }

    var movedDestinations = Set<IndexPath>()
    changes.movedIndexPaths.forEach { (move) in
        result[move.indexPathNew] = collection[move.indexPathOld]
        movedDestinations.insert(move.indexPathNew)
        if !movedDestinations.contains(move.indexPathOld) {
            result[move.indexPathOld] = nil
        }
    }

    changes.insertedIndexPaths.forEach { (indexPath) in
        result[indexPath] = nil
    }

    return result
}
