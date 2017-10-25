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

import XCTest
@testable import Chatto

class CollectionChangesTests: XCTestCase {

    func testThatDoesNotGenerateChangesForEmptyCollections() {
        let changes = generateChanges(oldCollection: [], newCollection: [])
        XCTAssertEqual(changes.insertedIndexPaths, [])
        XCTAssertEqual(changes.deletedIndexPaths, [])
        XCTAssertEqual(changes.movedIndexPaths, [])
    }

    func testThatDoesNotGenerateChangesForEqualCollections() {
        let changes = generateChanges(
            oldCollection: [Item(uid: "a"), Item(uid: "b")],
            newCollection: [Item(uid: "a"), Item(uid: "b")]
        )
        XCTAssertEqual(changes.insertedIndexPaths, [])
        XCTAssertEqual(changes.deletedIndexPaths, [])
        XCTAssertEqual(changes.movedIndexPaths, [])
    }

    func testThatGeneratesInsertions() {
        let changes = generateChanges(
            oldCollection: [],
            newCollection: [Item(uid: "a"), Item(uid: "b")]
        )
        XCTAssertEqual(changes.deletedIndexPaths, [])
        XCTAssertEqual(changes.movedIndexPaths, [])
        XCTAssertEqual(Set(changes.insertedIndexPaths), Set([IndexPath(item: 0, section: 0), IndexPath(item: 1, section: 0)]))
    }

    func testThatGeneratesDeletions() {
        let changes = generateChanges(
            oldCollection: [Item(uid: "a"), Item(uid: "b")],
            newCollection: []
        )
        XCTAssertEqual(changes.deletedIndexPaths, Set([IndexPath(item: 0, section: 0), IndexPath(item: 1, section: 0)]))
        XCTAssertEqual(changes.movedIndexPaths.count, 0)
        XCTAssertEqual(changes.insertedIndexPaths.count, 0)
    }

    func testThatGeneratesMovements() {
        let changes = generateChanges(
            oldCollection: [Item(uid: "a"), Item(uid: "b"), Item(uid: "c")],
            newCollection: [Item(uid: "a"), Item(uid: "c"), Item(uid: "b")]
        )
        XCTAssertEqual(changes.deletedIndexPaths, [])
        XCTAssertEqual(Set(changes.movedIndexPaths), Set([Move(1, to: 2), Move(2, to: 1)]))
        XCTAssertEqual(changes.insertedIndexPaths, [])
    }

    func testThatGeneratesInsertionsDeletionsAndMovements() {
        let changes = generateChanges(
            oldCollection: [Item(uid: "a"), Item(uid: "b"), Item(uid: "c")],
            newCollection: [Item(uid: "d"), Item(uid: "c"), Item(uid: "a")]
        )
        XCTAssertEqual(changes.deletedIndexPaths, [IndexPath(item: 1, section: 0)])
        XCTAssertEqual(changes.insertedIndexPaths, [IndexPath(item: 0, section: 0)])
        XCTAssertEqual(Set(changes.movedIndexPaths), [Move(0, to: 2), Move(2, to: 1)])
    }

    func testThatAppliesChangesToCollection() {
        // (0, 1, 2, 3, 4) -> (2, 3, new, 4)

        let indexPath0 = IndexPath(item: 0, section: 0)
        let indexPath1 = IndexPath(item: 1, section: 0)
        let indexPath2 = IndexPath(item: 2, section: 0)
        let indexPath3 = IndexPath(item: 3, section: 0)
        let indexPath4 = IndexPath(item: 4, section: 0)

        let collection = [
            indexPath0: 0,
            indexPath1: 1,
            indexPath2: 2,
            indexPath3: 3,
            indexPath4: 4
        ]

        let deletions = Set([indexPath0, indexPath1])
        let insertions = Set([indexPath2])
        let movements = [
            CollectionChangeMove(indexPathOld: indexPath2, indexPathNew: indexPath0),
            CollectionChangeMove(indexPathOld: indexPath3, indexPathNew: indexPath1),
            CollectionChangeMove(indexPathOld: indexPath4, indexPathNew: indexPath3)
        ]

        let changes = CollectionChanges(insertedIndexPaths: insertions,
                                        deletedIndexPaths: deletions,
                                        movedIndexPaths: movements)
        let result = updated(collection: collection, withChanges: changes)

        let expected = [
            indexPath0: 2,
            indexPath1: 3,
            // indexPath2: new
            indexPath3: 4
        ]

        XCTAssertEqual(result, expected)
    }
}

func Item(uid: String) -> UniqueIdentificable {
    return UniqueIdentificableItem(uid: uid)
}

func Move(_ from: Int, to: Int) -> CollectionChangeMove {
    return CollectionChangeMove(indexPathOld: IndexPath(item: from, section: 0), indexPathNew: IndexPath(item: to, section: 0))
}

struct UniqueIdentificableItem: UniqueIdentificable {
    let uid: String
    init(uid: String) {
        self.uid = uid
    }
}
