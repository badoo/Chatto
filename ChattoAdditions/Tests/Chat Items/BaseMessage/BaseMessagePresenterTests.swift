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
import Chatto
@testable import ChattoAdditions

class BaseMessagePresenterTests: XCTestCase {

    // BaseMessagePresenter is generic, let's use the photo one for instance
    var presenter: PhotoMessagePresenter<PhotoMessageViewModelDefaultBuilder, PhotoMessageTestHandler>!
    let decorationAttributes = ChatItemDecorationAttributes(bottomMargin: 0, showsTail: false)
    var interactionHandler: PhotoMessageTestHandler!
    override func setUp() {
        let viewModelBuilder = PhotoMessageViewModelDefaultBuilder()
        let sizingCell = PhotoMessageCollectionViewCell.sizingCell()
        let photoStyle = PhotoMessageCollectionViewCellDefaultStyle()
        let baseStyle = BaseMessageCollectionViewCellDefaultSyle()
        let messageModel = MessageModel(uid: "uid", senderId: "senderId", type: "photo-message", isIncoming: true, date: NSDate(), status: .Success)
        let photoMessageModel = PhotoMessageModel(messageModel: messageModel, imageSize: CGSize(width: 30, height: 30), image: UIImage())
        self.interactionHandler = PhotoMessageTestHandler()
        self.presenter = PhotoMessagePresenter(messageModel: photoMessageModel, viewModelBuilder: viewModelBuilder, interactionHandler: self.interactionHandler, sizingCell: sizingCell, baseCellStyle: baseStyle, photoCellStyle: photoStyle)
    }

    func testThat_WhenCellIsTappedOnFailIcon_ThenInteractionHandlerHandlesEvent() {
        let cell = PhotoMessageCollectionViewCell(frame: CGRect.zero)
        self.presenter.configureCell(cell, decorationAttributes: self.decorationAttributes)
        cell.failedButtonTapped()
        XCTAssertTrue(self.interactionHandler.didHandleTapOnFailIcon)
    }

    func testThat_WhenCellIsTappedOnBubble_ThenInteractionHandlerHandlesEvent() {
        let cell = PhotoMessageCollectionViewCell(frame: CGRect.zero)
        self.presenter.configureCell(cell, decorationAttributes: self.decorationAttributes)
        cell.bubbleTapped(UITapGestureRecognizer())
        XCTAssertTrue(self.interactionHandler.didHandleTapOnBubble)
    }

    func testThat_WhenCellIsLongPressedOnBubble_ThenInteractionHandlerHandlesEvent() {
        let cell = PhotoMessageCollectionViewCell(frame: CGRect.zero)
        self.presenter.configureCell(cell, decorationAttributes: self.decorationAttributes)
        cell.bubbleLongPressed()
        XCTAssertTrue(self.interactionHandler.didHandleLongPressOnBubble)
    }
}
