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
import ChattoAdditions

final class DemoEmojiDecorationViewFactory: MessageDecorationViewFactoryProtocol {

    private let font = UIFont.systemFont(ofSize: 40)

    func canCreateDecorationView(for model: DemoCompoundMessageModel) -> Bool {
        return model.emoji != nil
    }

    func makeDecorationView(for model: DemoCompoundMessageModel) -> UIView {
        let label = UILabel()
        label.font = self.font
        label.text = model.emoji
        return label
    }

    func makeLayoutProvider(for model: DemoCompoundMessageModel) -> MessageDecorationViewLayoutProviderProtocol {
        DemoEmojiDecorationViewLayoutProvider(emoji: model.emoji!,
                                              isIncoming: model.isIncoming,
                                              font: self.font)
    }
}

private final class DemoEmojiDecorationViewLayoutProvider: Hashable, MessageDecorationViewLayoutProviderProtocol {

    private let emoji: String
    private let font: UIFont
    private let isIncoming: Bool

    init(emoji: String, isIncoming: Bool, font: UIFont) {
        self.emoji = emoji
        self.isIncoming = isIncoming
        self.font = font
    }

    func makeLayout(from bubbleBounds: CGRect) -> MessageDecorationViewLayout {
        let size = self.emojiSize
        return MessageDecorationViewLayout(
            frame: .init(
                origin: .init(
                    x: (self.isIncoming ? bubbleBounds.maxX : 0) - size.width / 2,
                    y: bubbleBounds.size.height - size.height - 18
                ),
                size: size
            )
        )
    }

    var safeAreaInsets: UIEdgeInsets {
        let width = self.emojiSize.width
        let horizontalInset = width / 2
        var insets: UIEdgeInsets = .zero
        if self.isIncoming {
            insets.right = horizontalInset
        } else {
            insets.left = horizontalInset
        }
        return insets
    }

    private lazy var emojiSize: CGSize = {
        let textLayoutProvider = TextMessageLayoutProvider(text: self.emoji,
                                                           font: self.font,
                                                           textInsets: .zero)
        return textLayoutProvider.sizeThatFits(size: UIView.layoutFittingExpandedSize, safeAreaInsets: .zero)
    }()

    static func == (lhs: DemoEmojiDecorationViewLayoutProvider, rhs: DemoEmojiDecorationViewLayoutProvider) -> Bool {
        return lhs.emoji == rhs.emoji
            && lhs.font == rhs.font
            && lhs.isIncoming == rhs.isIncoming
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.emoji)
        hasher.combine(self.font)
        hasher.combine(self.isIncoming)
    }
}
