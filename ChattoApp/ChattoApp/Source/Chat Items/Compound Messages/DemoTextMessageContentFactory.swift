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
import ChattoAdditions

struct DemoTextMessageContentFactory: MessageContentFactoryProtocol {

    private let font = UIFont.systemFont(ofSize: 17)
    private let textInsets = UIEdgeInsets.zero

    func canCreateMessageContent(forModel model: DemoCompoundMessageModel) -> Bool {
        return true
    }

    func createContentView() -> UIView {
        let label = LabelWithInsets()
        label.numberOfLines = 0
        label.font = self.font
        label.textInsets = self.textInsets
        return label
    }

    func createContentPresenter(forModel model: DemoCompoundMessageModel) -> MessageContentPresenterProtocol {
        return DefaultMessageContentPresenter<DemoCompoundMessageModel, LabelWithInsets>(
            message: model,
            showBorder: false,
            onBinding: { message, label in
                label?.text = message.text
                label?.textColor = message.isIncoming ? .black : .white
            }
        )
    }

    func createLayoutProvider(forModel model: DemoCompoundMessageModel) -> MessageManualLayoutProviderProtocol {
        return TextMessageLayoutProvider(text: model.text,
                                         font: self.font,
                                         textInsets: self.textInsets)
    }

    func createMenuPresenter(forModel model: DemoCompoundMessageModel) -> ChatItemMenuPresenterProtocol? {
        return nil
    }
}

private final class LabelWithInsets: UILabel {
    var textInsets: UIEdgeInsets = .zero
    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: self.textInsets + self.safeAreaInsets))
    }
}

private func + (lhs: UIEdgeInsets, rhs: UIEdgeInsets) -> UIEdgeInsets {
    return UIEdgeInsets(top: lhs.top + rhs.top,
                        left: lhs.left + rhs.left,
                        bottom: lhs.bottom + rhs.bottom,
                        right: lhs.right + rhs.right)
}
