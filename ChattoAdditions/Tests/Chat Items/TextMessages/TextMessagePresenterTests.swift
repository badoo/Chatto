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

class TextMessagePresenterTests: XCTestCase, UICollectionViewDataSource {

    var presenter: TextMessagePresenter<TextMessageViewModelDefaultBuilder<TextMessageModel<MessageModel>>, TextMessageTestHandler>!
    let decorationAttributes = ChatItemDecorationAttributes(bottomMargin: 0, messageDecorationAttributes: BaseMessageDecorationAttributes())
    override func setUp() {
        super.setUp()
        let viewModelBuilder = TextMessageViewModelDefaultBuilder<TextMessageModel<MessageModel>>()
        let sizingCell = TextMessageCollectionViewCell.sizingCell()
        let textStyle = TextMessageCollectionViewCellDefaultStyle()
        let baseStyle = BaseMessageCollectionViewCellDefaultStyle()
        let messageModel = MessageModel(uid: "uid", senderId: "senderId", type: "text-message", isIncoming: true, date: NSDate() as Date, status: .success)
        let textMessageModel = TextMessageModel(messageModel: messageModel, text: "Some text")
        self.presenter = TextMessagePresenter(
            messageModel: textMessageModel,
            viewModelBuilder: viewModelBuilder,
            interactionHandler: TextMessageTestHandler(),
            sizingCell: sizingCell,
            baseCellStyle: baseStyle,
            textCellStyle: textStyle,
            layoutCache: NSCache(),
            menuPresenter: TextMessageMenuItemPresenter()
        )
    }

    func testThat_RegistersAndDequeuesCells() {

        let collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: UICollectionViewFlowLayout())
        TextMessagePresenter<TextMessageViewModelDefaultBuilder<TextMessageModel<MessageModel>>, TextMessageTestHandler>.registerCells(collectionView)
        collectionView.dataSource = self
        collectionView.reloadData()
        XCTAssertNotNil(self.presenter.dequeueCell(collectionView: collectionView, indexPath: IndexPath(item: 0, section: 0)))
        collectionView.dataSource = nil
    }

    func testThat_heightForCelReturnsPositiveHeight() {
        let height = self.presenter.heightForCell(maximumWidth: 320, decorationAttributes: self.decorationAttributes)
        XCTAssertTrue(height > 0)
    }

    func testThat_CellIsConfigured() {
        let cell = TextMessageCollectionViewCell(frame: CGRect.zero)
        self.presenter.configureCell(cell, decorationAttributes: self.decorationAttributes)
        XCTAssertEqual("Some text", cell.bubbleView.textMessageViewModel.text)
    }

    func testThat_CanCalculateHeightInBackground() {
        XCTAssertTrue(self.presenter.canCalculateHeightInBackground)
    }

    func testThat_ShouldShowMenuReturnsTrue() {
        let cell = TextMessageCollectionViewCell(frame: CGRect.zero)
        self.presenter.cellWillBeShown(cell) // Needs to have a reference to the current cell before getting menu calls
        XCTAssertTrue(self.presenter.shouldShowMenu())
    }

    func testThat_CanPerformCopyAction() {
        #if swift(>=2.3)
            XCTAssertTrue(self.presenter.canPerformMenuControllerAction(#selector(UIResponderStandardEditActions.copy(_:))))
        #else
            XCTAssertTrue(self.presenter.canPerformMenuControllerAction(#selector(NSObject.copy(_:))))
        #endif
    }

    // MARK: Helpers

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return self.presenter.dequeueCell(collectionView: collectionView, indexPath: indexPath as IndexPath)
    }
}

class TextMessageTestHandler: BaseMessageInteractionHandlerProtocol {
    typealias ViewModelT = TextMessageViewModel<TextMessageModel<MessageModel>>

    func userDidTapOnFailIcon(viewModel: ViewModelT, failIconView: UIView) {
    }

    func userDidTapOnAvatar(viewModel: ViewModelT) {
    }

    func userDidTapOnBubble(viewModel: ViewModelT) {
    }

    func userDidBeginLongPressOnBubble(viewModel: ViewModelT) {
    }

    func userDidEndLongPressOnBubble(viewModel: ViewModelT) {
    }

    func userDidSelectMessage(viewModel: ViewModelT) {
    }

    func userDidDeselectMessage(viewModel: ViewModelT) {
    }
}
