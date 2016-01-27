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

class BaseChatItemPresenterTests: XCTestCase {

    var presenter: BaseChatItemPresenter<UICollectionViewCell>!

    override func setUp() {
        self.presenter = BaseChatItemPresenter()
    }

    func testThat_WhenCellWillBeShown_ThenCapturesCell() {
        let cell = UICollectionViewCell()
        self.presenter.cellWillBeShown(cell)
        XCTAssert(cell === self.presenter.cell)
    }

    func testThat_WhenCellWillBeShown_ThenCapturesCellWeakly() {
        var cell: UICollectionViewCell? = UICollectionViewCell()
        self.presenter.cellWillBeShown(cell!)
        cell = nil
        XCTAssertNil(self.presenter.cell)
    }

    func testThat_WhenCellWasHidden_ThenCellIsNil() {
        let cell = UICollectionViewCell()
        self.presenter.cellWillBeShown(cell)
        self.presenter.cellWasHidden(cell)
        XCTAssertNil(self.presenter.cell)
    }

    func testThat_WhenNotLastShownCellIsHidden_ThenCellIsNotNil() {
        let cell1 = UICollectionViewCell()
        let cell2 = UICollectionViewCell()
        self.presenter.cellWillBeShown(cell1)
        self.presenter.cellWillBeShown(cell2)
        self.presenter.cellWasHidden(cell1)
        XCTAssert(cell2 === self.presenter.cell)
    }
}
