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

public protocol TextMessageMenuItemPresenterProtocol {
    func shouldShowMenu(for text: String, item: MessageModelProtocol) -> Bool
    func canPerformMenuControllerAction(_ action: Selector, for text: String, item: MessageModelProtocol) -> Bool
    func performMenuControllerAction(_ action: Selector, for text: String, item: MessageModelProtocol)
}

public final class TextMessageMenuItemPresenter: TextMessageMenuItemPresenterProtocol {

    // MARK: - Private properties

    private let pasteboard: UIPasteboard

    // MARK: - Instantiation

    public init(pasteboard: UIPasteboard = .general) {
        self.pasteboard = pasteboard
    }

    // MARK: - TextMessageMenuItemPresenterProtocol

    public func shouldShowMenu(for text: String, item: MessageModelProtocol) -> Bool {
        return true
    }

    public func canPerformMenuControllerAction(_ action: Selector, for text: String, item: MessageModelProtocol) -> Bool {
        return action == .copy
    }

    public func performMenuControllerAction(_ action: Selector, for text: String, item: MessageModelProtocol) {
        guard action == .copy else {
            assertionFailure("Unexpected action")
            return
        }
        self.pasteboard.string = text
    }
}

private extension Selector {
    static var copy: Selector {
        return #selector(UIResponderStandardEditActions.copy(_:))
    }
}
