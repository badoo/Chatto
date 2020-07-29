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
    private let textInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)

    func canCreateMessageContent(forModel model: DemoCompoundMessageModel) -> Bool {
        return true
    }

    func createContentView() -> UIView {
        let textView = TextView()
        textView.label.numberOfLines = 0
        textView.label.font = self.font
        return textView
    }

    func createContentPresenter(forModel model: DemoCompoundMessageModel) -> MessageContentPresenterProtocol {
        let layoutProvider = self.createTextLayoutProvider(forModel: model)
        return DefaultMessageContentPresenter<DemoCompoundMessageModel, TextView>(
            message: model,
            showBorder: false,
            onBinding: { message, textView in
                guard let textView = textView else { return }
                textView.label.text = message.text
                textView.label.textColor = message.isIncoming ? .black : .white
                textView.layoutProvider = layoutProvider
            }
        )
    }

    func createLayoutProvider(forModel model: DemoCompoundMessageModel) -> MessageManualLayoutProviderProtocol {
        self.createTextLayoutProvider(forModel: model)
    }

    func createMenuPresenter(forModel model: DemoCompoundMessageModel) -> ChatItemMenuPresenterProtocol? {
        return nil
    }

    private func createTextLayoutProvider(forModel model: DemoCompoundMessageModel) -> TextMessageLayoutProviderProtocol {
        TextMessageLayoutProvider(text: model.text,
                                  font: self.font,
                                  textInsets: self.textInsets)
    }
}

private final class TextView: UIView {

    let label = UILabel()
    var layoutProvider: TextMessageLayoutProviderProtocol? {
        didSet {
            guard self.layoutProvider != nil else { return }
            self.setNeedsLayout()
        }
    }

    init() {
        super.init(frame: .zero)
        self.addSubview(label)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let layoutProvider = self.layoutProvider else { return }
        self.label.frame = layoutProvider.layout(for: self.bounds.size, safeAreaInsets: self.safeAreaInsets).frame
    }
}
