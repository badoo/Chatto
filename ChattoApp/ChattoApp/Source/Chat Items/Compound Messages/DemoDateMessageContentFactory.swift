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

struct DemoDateMessageContentFactory: MessageContentFactoryProtocol {

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateStyle = .medium
        return formatter
    }()

    private let textInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
    private let font = UIFont.systemFont(ofSize: 17)

    func canCreateMessageModule(forModel model: DemoCompoundMessageModel) -> Bool {
        return true
    }

    func createMessageModule(forModel model: DemoCompoundMessageModel) -> MessageContentModule {
        let text = DemoDateMessageContentFactory.dateFormatter.string(from: model.date)
        let label = UILabel()
        label.textAlignment = .right
        label.text = text
        let infoView = DateInfoView(label: label, insets: self.textInsets)
        return MessageContentModule(view: infoView, presenter: (), showBorder: true)
    }

    func createLayoutProvider(forModel model: DemoCompoundMessageModel) -> MessageManualLayoutProviderProtocol {
        let text = DemoDateMessageContentFactory.dateFormatter.string(from: model.date)
        return TextMessageLayoutProvider(text: text,
                                         font: self.font,
                                         textInsets: self.textInsets)
    }
}

private final class DateInfoView: UIView {
    private let label: UILabel
    private let insets: UIEdgeInsets

    init(label: UILabel, insets: UIEdgeInsets) {
        self.label = label
        self.insets = insets
        super.init(frame: .zero)
        self.addSubview(self.label)
        self.backgroundColor = UIColor(white: 0.95, alpha: 1)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.label.frame = self.bounds.inset(by: self.insets).inset(by: self.safeAreaInsets)
    }
}
