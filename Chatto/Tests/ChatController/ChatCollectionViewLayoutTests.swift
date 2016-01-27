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

class ChatCollectionViewLayoutModelTests: XCTestCase {

    func testThat_WhenEmptyDataIsProvided_ThenLayoutIsCorrectlyCreated() {
        let width: CGFloat = 320
        let layoutModel = ChatCollectionViewLayoutModel.createModel(width, itemsLayoutData: [])
        XCTAssertEqual(width, layoutModel.calculatedForWidth)
        XCTAssertEqual(CGSize(width: 320, height: 0), layoutModel.contentSize)
        XCTAssertEqual([], layoutModel.layoutAttributes)
        XCTAssertEqual([[]], layoutModel.layoutAttributesBySectionAndItem)
    }

    func testThatLayoutIsCorrectlyCreated() {
        let width: CGFloat = 320
        let layoutModel = ChatCollectionViewLayoutModel.createModel(
            width,
            itemsLayoutData: [(height: 10, bottomMargin: 1), (height: 15, bottomMargin: 2)]
        )
        let expectedLayoutAttributes = [
            Atttributes(item: 0, frame: CGRect(x: 0, y: 0, width: width, height: 10)),
            Atttributes(item: 1, frame: CGRect(x: 0, y: 11, width: width, height: 15))
        ]
        XCTAssertEqual(width, layoutModel.calculatedForWidth)
        XCTAssertEqual(CGSize(width: 320, height: 28), layoutModel.contentSize)
        XCTAssertEqual(expectedLayoutAttributes, layoutModel.layoutAttributes)
        XCTAssertEqual([expectedLayoutAttributes], layoutModel.layoutAttributesBySectionAndItem)
    }

}

private func Atttributes(item item: Int, frame: CGRect) -> UICollectionViewLayoutAttributes {
    let indexPath = NSIndexPath(forItem: item, inSection: 0)
    let attributes = UICollectionViewLayoutAttributes(forCellWithIndexPath: indexPath)
    attributes.frame = frame
    return attributes
}
