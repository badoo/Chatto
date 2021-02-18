//
// The MIT License (MIT)
//
// Copyright (c) 2015-present Badoo Trading Limited.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import XCTest
@testable import ChattoAdditions

final class MessageViewModelTests: XCTestCase {
    private let dateFormatter = DateFormatter()
    private var messageModel: FakeMessageModel!
    private var viewModel: MessageViewModel!

    override func setUp() {
        super.setUp()
        self.messageModel = FakeMessageModel()
        self.viewModel = MessageViewModel(dateFormatter: self.dateFormatter,
                                          messageModel: self.messageModel,
                                          avatarImage: nil,
                                          decorationAttributes: BaseMessageDecorationAttributes())
    }

    // MARK: - Failed Icon
    func test_GivenModelWithSuccessState_WhenContentTransferStatusSetToFailed_ThenViewModelStatusIsFailed() {
        self.messageModel.status = .success
        self.viewModel.messageContentTransferStatus = .failed
        XCTAssertEqual(viewModel.status, .failed)
    }

    func test_GivenModelWithFailedState_WhenContentTransferStatusSetToSuccess_ThenViewModelStatusIsFailed() {
        self.messageModel.status = .failed
        self.viewModel.messageContentTransferStatus = .success
        XCTAssertEqual(viewModel.status, .failed)
    }

    func test_GivenModelWithSuccessState_WhenContentTransferIsNotSet_ThenViewModelStatusIsSuccess() {
        self.messageModel.status = .success
        self.viewModel.messageContentTransferStatus = nil
        XCTAssertEqual(viewModel.status, .success)
    }

    func test_WhenViewModelStateIsFailed_ThenIsShowingFailedIconIsTrue() {
        self.forceViewModelState(to: .failed)
        XCTAssert(self.viewModel.isShowingFailedIcon)
    }

    func test_WhenViewModelStateIsSuccess_ThenIsShowingFailedIconIsFalse() {
        self.forceViewModelState(to: .success)
        XCTAssertFalse(self.viewModel.isShowingFailedIcon)
    }

    // MARK: - Flags logic
    func test_WhenViewModelReplyStateIsRequested_ThenTheValueIsTakenFromTheMessageModel() {
        let flagValues = [true, false]
        for flag in flagValues {
            self.messageModel.canReply = flag
            XCTAssertEqual(self.viewModel.canReply, flag)
        }
    }

    func test_WhenViewModelDirecitionIsRequested_ThenTheValueIsTakenFromTheMessageModel() {
        let flagValues = [true, false]
        for flag in flagValues {
            self.messageModel.isIncoming = flag
            XCTAssertEqual(self.viewModel.isIncoming, flag)
        }
    }

    // MARK: - Private helpers
    private func forceViewModelState(to state: MessageStatus) {
        self.messageModel.status = state
    }
}
