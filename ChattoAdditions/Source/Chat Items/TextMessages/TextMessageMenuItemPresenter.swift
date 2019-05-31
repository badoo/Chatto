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

public final class TextMessageMenuItemPresenter: ChatItemMenuPresenterProtocol {

    // MARK: - Private properties

    private let pasteboard: UIPasteboard
    private let textProvider: () -> String

    // MARK: - Instantiation

    public init(pasteboard: UIPasteboard = .general, textProvider: @escaping () -> String) {
        self.pasteboard = pasteboard
        self.textProvider = textProvider
    }

    // MARK: - ChatItemMenuPresenterProtocol

    public func shouldShowMenu() -> Bool {
        return true
    }

    public func canPerformMenuControllerAction(_ action: Selector) -> Bool {
        return action == .copy
    }

    public func performMenuControllerAction(_ action: Selector) {
        guard action == .copy else {
            assertionFailure("Unexpected action")
            return
        }
        self.pasteboard.string = self.textProvider()
    }
}

private extension Selector {
    static var copy: Selector {
        return #selector(UIResponderStandardEditActions.copy(_:))
    }
}
