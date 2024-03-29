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

import UIKit
import Chatto

public final class DefaultMessageContentPresenter<MessageType, ViewType: UIView>: MessageContentPresenterProtocol, MessageContentLoadingPresenterProtocol {

    public typealias ActionHandler = (_ message: MessageType, _ view: ViewType?) -> Void
    public typealias BindingClosure = (_ message: MessageType, _ view: ViewType?) -> Void
    public typealias UnbindingClosure = (_ view: ViewType?) -> Void
    public typealias MessageUpdateClosure = (_ newMessage: MessageType) -> Void

    public init(message: MessageType,
                showBorder: Bool,
                onBinding: BindingClosure?,
                onUnbinding: UnbindingClosure? = nil,
                onContentWillBeShown: ActionHandler? = nil,
                onContentWasHidden: ActionHandler? = nil,
                onContentWasTapped_deprecated: ActionHandler? = nil,
                onMessageUpdate: MessageUpdateClosure? = nil,
                contentLoadingStatus: Observable<MessageContentLoadingStatus> = .init(.loaded)) {
        self.message = message

        self.onBinding = onBinding
        self.onUnbinding = onUnbinding

        self.showBorder = showBorder
        self.onContentWillBeShown = onContentWillBeShown
        self.onContentWasHidden = onContentWasHidden
        self.onContentWasTapped_deprecated = onContentWasTapped_deprecated

        self.onMessageUpdate = onMessageUpdate
        self.contentLoadingStatus = contentLoadingStatus
    }

    private var message: MessageType
    private weak var viewReference: ViewReference?
    private var view: ViewType? { return self.viewReference?.view as? ViewType }

    private let onBinding: BindingClosure?
    private let onUnbinding: UnbindingClosure?

    private let onContentWillBeShown: ActionHandler?
    private let onContentWasHidden: ActionHandler?
    private let onContentWasTapped_deprecated: ActionHandler?

    private let onMessageUpdate: MessageUpdateClosure?

    // MARK: - MessageContentLoadingPresenterProtocol

    public let contentLoadingStatus: Observable<MessageContentLoadingStatus>

    // MARK: - MessageContentPresenterProtocol

    public weak var delegate: MessageContentPresenterDelegate?

    public let showBorder: Bool

    public func contentWillBeShown() { self.onContentWillBeShown?(self.message, self.view) }
    public func contentWasHidden() { self.onContentWasHidden?(self.message, self.view) }
    public func contentWasTapped_deprecated() { self.onContentWasTapped_deprecated?(self.message, self.view) }
    public func handleFailedIconTap() {}

    public func bindToView(with viewReference: ViewReference) {
        self.viewReference = viewReference
        self.onBinding?(self.message, self.view)
    }

    public func unbindFromView() {
        self.onUnbinding?(self.view)
    }

    public func updateMessage(_ newMessage: Any) {
        guard let message = newMessage as? MessageType else {
            assertionFailure("Unexpected message type: \(type(of: newMessage))")
            return
        }
        self.message = message
        self.onMessageUpdate?(self.message)
    }
}
