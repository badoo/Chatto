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

struct DummyViewModel {
    let text: String
}

final class DummyView: UIView, ChatItemContentView, ManualLayoutViewProtocol {

    private let label = UILabel()
    private var layout: DummyViewLayout?

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupLabel()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.updateLayout()
    }

    func subscribe(for viewModel: DummyViewModel) {
        self.label.text = viewModel.text
    }

    // MARK: - ManualLayoutViewProtocol

    func apply(layout: DummyViewLayout) {
        self.layout = layout
        self.updateLayout()
    }

    // MARK: - Private

    private func updateLayout() {
        guard let layout = self.layout else { return }
        self.label.frame = layout.label
    }

    private func setupLabel() {
        self.label.numberOfLines = 0
        self.label.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.label)
    }
}

struct DummyViewLayout: LayoutModel, SizeContainer {
    let label: CGRect
    let size: CGSize
}

struct DummyLayoutProvider: LayoutProviderProtocol {

    private let textLayoutProvider: TextMessageLayoutProvider

    init(viewModel: DummyViewModel) {
        // TODO: Pass text style
        self.textLayoutProvider = TextMessageLayoutProvider(
            text: viewModel.text,
            font: UIFont.systemFont(ofSize: 17),
            textInsets: .zero
        )
    }

    func layout(for context: LayoutContext) -> DummyViewLayout {
        let textLayout = self.textLayoutProvider.layout(for: context.allowedSize(), safeAreaInsets: .zero)
        return DummyViewLayout(textLayout: textLayout)
    }
}

private extension DummyViewLayout {
    init(textLayout: TextMessageLayout) {
        self.label = textLayout.frame
        self.size = textLayout.size
    }
}

private extension LayoutContext {
    func allowedSize() -> CGSize {
        CGSize(width: self.maxWidth, height: .greatestFiniteMagnitude)
    }
}

struct DummyLayoutProviderFactory: LayoutProviderFactoryProtocol {
    func makeLayoutProvider(for viewModel: DummyViewModel) -> DummyLayoutProvider {
        DummyLayoutProvider(viewModel: viewModel)
    }
}

final class DummyContentViewFactory: ViewFactoryProtocol {

    typealias ContentView = DummyView

    func makeView() -> ContentView {
        DummyView()
    }
}

final class StaticDummyViewModelFactory<ChatItem>: ViewModelFactoryProtocol {

    private let text: String

    init(text: String) { self.text = text }

    func makeViewModel(for chatItem: ChatItem) -> DummyViewModel {
        DummyViewModel(text: self.text)
    }
}

final class DummyViewModelFactory<ChatItem>: ViewModelFactoryProtocol {
    func makeViewModel(for chatItem: ChatItem) -> DummyViewModel {
        DummyViewModel(text: String(describing: chatItem))
    }
}
