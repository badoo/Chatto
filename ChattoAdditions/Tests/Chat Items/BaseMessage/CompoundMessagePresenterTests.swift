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

@testable import ChattoAdditions
import XCTest

@available(iOS 11, *)
final class CompoundMessagePresenterTests: XCTestCase {

    func test_WhenPresenterIsUpdatedWithTheSameMessage_ThenUpdateContentNotCalled_AndUpdateExistingContentPresentersNotCalled() {
        let message = TestHelpers.makeMessage(withId: "123")
        let sameMessage = message
        let presenter = TestHelpers.makeTestableCompoundMessagePresenter(with: message)

        presenter.update(with: sameMessage)

        XCTAssertEqual(0, presenter.invokedUpdateContentCount)
        XCTAssertEqual(0, presenter.invokedUpdateExistingContentPresentersCount)
    }

    func test_WhenPresenterIsUpdatedWithMessageWithAnotherContent_ThenUpdateContentCalled_ButUpdateExistingContentPresentersNotCalled() {
        let date = Date()
        let anotherDate = date.addingTimeInterval(1)
        let message = TestHelpers.makeMessage(withId: "123", date: date)
        let sameMessageWithAnotherId = TestHelpers.makeMessage(withId: "123", date: anotherDate)
        let presenter = TestHelpers.makeTestableCompoundMessagePresenter(with: message)

        presenter.update(with: sameMessageWithAnotherId)

        XCTAssertEqual(1, presenter.invokedUpdateContentCount)
        XCTAssertEqual(0, presenter.invokedUpdateExistingContentPresentersCount)
    }

    func test_WhenPresenterIsUpdatedWithSameMessageWithAnotherId_ThenUpdateContentNotCalled_ButUpdateExistingContentPresentersCalled() {
        let message = TestHelpers.makeMessage(withId: "123")
        let sameMessageWithAnotherId = message.makeSameMessage(butAnotherId: "456")
        let presenter = TestHelpers.makeTestableCompoundMessagePresenter(with: message)

        presenter.update(with: sameMessageWithAnotherId)

        XCTAssertEqual(0, presenter.invokedUpdateContentCount)
        XCTAssertEqual(1, presenter.invokedUpdateExistingContentPresentersCount)
    }

    func test_GivenFailableContentPresenter_WhenItsContentIsFailedToLoad_ThenViewModelStatusUpdatedToFailed() throws {
        let contentTransferStatus = Observable<TransferStatus>(.idle)
        let (presenter, viewModel) = try self.makeRealPresenter(contentTransferStatus: contentTransferStatus)
        contentTransferStatus.value = .failed
        XCTAssertEqual(viewModel.messageContentTransferStatus, .failed)
        // to get rid of the warning about not used variable
        XCTAssert(presenter === presenter)
    }

    func test_GivenFailableContentPresenter_WhenItsContentTurnsToFailedToSuccess_ThenViewModelStatusUpdatedToSuccess() throws {
        let contentTransferStatus = Observable<TransferStatus>(.failed)
        let (presenter, viewModel) = try self.makeRealPresenter(contentTransferStatus: contentTransferStatus)
        contentTransferStatus.value = .success
        XCTAssertEqual(viewModel.messageContentTransferStatus, .success)
        // to get rid of the warning about not used variable
        XCTAssert(presenter === presenter)
    }

    func test_GivenContentPresenterWithFailedContentAndMessageWithFailedDeliveryStauts_WhenFailIconTapped_ThenInteractionHandlerCalled() throws {
        let fakeMessage = MessageModel(uid: "111",
                                       senderId: "123",
                                       type: "text",
                                       isIncoming: true,
                                       date: Date(timeIntervalSince1970: 0),
                                       status: .failed)
        let interactionHandler = FakeMessageInteractionHandler.niceMock()
        let (presenter, _) = try self.makeRealPresenter(
            message: fakeMessage,
            interactionHandler: interactionHandler,
            contentTransferStatus: .init(.failed)
        )

        presenter.onCellFailedButtonTapped(UIView())
        XCTAssert(interactionHandler._userDidTapOnFailIcon.wasCalled)
    }

    func test_GivenContentPresenterWithFailedContentAndMessageWithSuccessDeliveryStauts_WhenFailIconTapped_ThenContentPresenterCalled() throws {
        let contentPresenter = FakeMessageContentPresenter()
        let (presenter, _) = try self.makeRealPresenter(
            contentPresenter: contentPresenter,
            contentTransferStatus: .init(.failed)
        )

        presenter.onCellFailedButtonTapped(UIView())
        XCTAssert(contentPresenter.wasHandleFailedIconTapCalled)
    }

    private func makeRealPresenter(
        message: MessageModel = TestHelpers.makeMessage(withId: "123"),
        contentPresenter: FakeMessageContentPresenter = FakeMessageContentPresenter(),
        interactionHandler: FakeMessageInteractionHandler? = nil,
        contentTransferStatus: Observable<TransferStatus> = .init(.success)
    ) throws -> (CompoundMessagePresenter<FakeViewModelBuilder, FakeMessageInteractionHandler>, MessageViewModel) {
        let viewModelBuilder = TestHelpers.makeFakeViewModelBuilder()
        contentPresenter.contentTransferStatus = contentTransferStatus

        let contentFactory = FakeMessageContentFactory<MessageModel>()
        contentFactory.fakeContentPresenter = contentPresenter
        let viewModel = try XCTUnwrap(viewModelBuilder.stubbedCreateViewModelResult)

        let presenter = CompoundMessagePresenter<FakeViewModelBuilder, FakeMessageInteractionHandler>(
            messageModel: message,
            viewModelBuilder: viewModelBuilder,
            interactionHandler: interactionHandler,
            contentFactories: [.init(contentFactory)],
            sizingCell: CompoundMessageCollectionViewCell(frame: .zero),
            baseCellStyle: StubMessageCollectionViewCellStyle(),
            compoundCellStyle: StubCompoundBubbleViewStyle(),
            cache: Cache<CompoundBubbleLayoutProvider.Configuration, CompoundBubbleLayoutProvider>(),
            accessibilityIdentifier: nil
        )
        return (presenter, viewModel)
    }
}
