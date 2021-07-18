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

protocol AsyncImageViewProtocol: AnyObject {
    var viewModel: AsyncImageViewModelProtocol? { get set }
}

protocol AsyncImageViewModelProtocol: AnyObject {
    var image: Observable<UIImage?> { get }
}

final class AsyncImageViewModel: AsyncImageViewModelProtocol, ChatItemLifecycleViewModel {
    let image: Observable<UIImage?> = .init(nil)

    private let message: PhotoMessageModelProtocol

    init(message: PhotoMessageModelProtocol) {
        self.message = message
    }

    func load() {
        var generator = SystemRandomNumberGenerator()
        let seconds = Double(generator.next() % 400) / 100
        let deadline: DispatchTime = .now() + seconds + 2
        DispatchQueue.main.asyncAfter(deadline: deadline) { [weak self] in
            guard let self = self else { return }
            self.image.value = self.message.image
        }
    }

    func willShow() {
        self.load()
    }

}

final class AsyncImageView: UIView, AsyncImageViewProtocol, ManualLayoutViewProtocol {

    private let imageView = UIImageView()

    private var layout: AsyncImageViewLayout?

    var viewModel: AsyncImageViewModelProtocol? {
        didSet {
            guard let viewModel = self.viewModel else { return }
            self.imageView.image = viewModel.image.value
            viewModel.image.observe(self) { [weak self] _, new in
                guard self?.viewModel === viewModel else { return }
                self?.imageView.image = new
            }
        }
    }

    init() {
        super.init(frame: .zero)
        self.setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.updateLayout()
    }

    // MARK: - ManualLayoutViewProtocol

    func apply(layout: AsyncImageViewLayout) {
        self.layout = layout
        self.updateLayout()
    }

    // MARK: - Private

    private func updateLayout() {
        guard let layout = self.layout else { return }
        self.imageView.frame = layout.image
    }

    private func setupSubviews() {
        self.imageView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.imageView)
    }
}

struct AsyncImageViewLayout: LayoutModel, SizeContainer {
    let image: CGRect
    let size: CGSize
}

struct AsyncImageLayoutProvider: LayoutProviderProtocol {
    private let ratio: CGFloat = 1.5

    init() {}

    func layout(for context: LayoutContext) throws -> AsyncImageViewLayout {
        let width = context.maxWidth
        let size = CGSize(
            width: width,
            height: width * self.ratio
        )

        let image = CGRect(
            origin: .zero,
            size: size
        )

        return AsyncImageViewLayout(
            image: image,
            size: size
        )
    }
}

struct AsyncImageLayoutProviderFactory: LayoutProviderFactoryProtocol {
    func makeLayoutProvider(for viewModel: AsyncImageViewModel) -> AsyncImageLayoutProvider {
        AsyncImageLayoutProvider()
    }
}

struct AsyncImageViewFactory: ViewFactoryProtocol {
    func makeView() -> AsyncImageView {
        AsyncImageView()
    }
}

struct AsyncImageViewModelFactory<ChatItem: PhotoMessageModelProtocol>: ViewModelFactoryProtocol {
    func makeViewModel(for chatItem: ChatItem) -> AsyncImageViewModel {
        AsyncImageViewModel(message: chatItem)
    }
}
