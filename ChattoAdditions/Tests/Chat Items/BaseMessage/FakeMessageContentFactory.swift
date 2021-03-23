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

import Chatto
import ChattoAdditions
import UIKit

final class FakeMessageContentFactory<T: MessageModelProtocol>: MessageContentFactoryProtocol {
    var fakeContentView: UIView = UIView()
    var canCreateMessageContentValue = true
    var fakeContentPresenter = FakeMessageContentPresenter()
    var fakeLayoutProvider = FakeMessageManualLayoutProvider()

    func canCreateMessageContent(forModel model: T) -> Bool {
        return self.canCreateMessageContentValue
    }

    func createContentView() -> UIView {
        return self.fakeContentView
    }

    func createContentPresenter(forModel model: T) -> MessageContentPresenterProtocol {
        return self.fakeContentPresenter
    }

    func createLayoutProvider(forModel model: T) -> MessageManualLayoutProviderProtocol {
        return self.fakeLayoutProvider
    }

    func createMenuPresenter(forModel model: T) -> ChatItemMenuPresenterProtocol? {
        return nil
    }
}

final class FakeMessageContentPresenter: FailableMessageContentPresenterProtocol {
    var contentTransferStatus: Observable<TransferStatus>?
    weak var delegate: MessageContentPresenterDelegate?
    var showBorder: Bool = false

    var wasHandleFailedIconTapCalled = false

    func contentWillBeShown() {
    }

    func contentWasHidden() {
    }

    func contentWasTapped_deprecated() {
    }

    func bindToView(with viewReference: ViewReference) {
    }

    func unbindFromView() {
    }

    func updateMessage(_ newMessage: Any) {
    }

    func handleFailedIconTap() {
        self.wasHandleFailedIconTapCalled = true
    }
}

final class FakeMessageManualLayoutProvider: MessageManualLayoutProviderProtocol {
    var asHashable: AnyHashable { return "" as AnyHashable }
    func layoutThatFits(size: CGSize, safeAreaInsets: UIEdgeInsets) -> LayoutInfo {
        return LayoutInfo(size: .zero, contentInsets: .zero)
    }
}
