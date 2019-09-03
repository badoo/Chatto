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

public final class ViewReference {

    public weak var view: UIView?

    public init(to view: UIView?) {
        self.view = view
    }
}

public protocol MessageContentPresenterDelegate: AnyObject {
    func presenterDidInvalidateLayout(_ presenter: MessageContentPresenterProtocol)
}

public protocol MessageContentPresenterProtocol {

    var delegate: MessageContentPresenterDelegate? { get set }

    /// Very likely it should be moved to other place but we didn't decide yet where.
    var showBorder: Bool { get }

    func contentWillBeShown()
    func contentWasHidden()

    /// It will be removed in the future. View taps should be handled by presenters themselves.
    func contentWasTapped_deprecated()

    func bindToView(with viewReference: ViewReference)
    func unbindFromView()

    var supportsMessageUpdating: Bool { get }

    /// Please note, that returning `false` from `supportsMessageUpdating`
    /// doesn't mean that this method won't be called.
    func updateMessage(_ newMessage: Any)
}

public extension MessageContentPresenterProtocol {
    var supportsMessageUpdating: Bool { return false }
}
