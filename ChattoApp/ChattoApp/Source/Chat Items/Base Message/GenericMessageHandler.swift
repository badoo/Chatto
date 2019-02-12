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

import ChattoAdditions

final class GenericMessageHandler<ViewModel: DemoMessageViewModelProtocol & MessageViewModelProtocol>: BaseMessageInteractionHandlerProtocol {

    private let baseHandler: BaseMessageHandler

    init(baseHandler: BaseMessageHandler) {
        self.baseHandler = baseHandler
    }

    func userDidTapOnFailIcon(viewModel: ViewModel, failIconView: UIView) {
        self.baseHandler.userDidTapOnFailIcon(viewModel: viewModel)
    }

    func userDidTapOnAvatar(viewModel: ViewModel) {
        self.baseHandler.userDidTapOnAvatar(viewModel: viewModel)
    }

    func userDidTapOnBubble(viewModel: ViewModel) {
        self.baseHandler.userDidTapOnBubble(viewModel: viewModel)
    }

    func userDidBeginLongPressOnBubble(viewModel: ViewModel) {
        self.baseHandler.userDidBeginLongPressOnBubble(viewModel: viewModel)
    }

    func userDidEndLongPressOnBubble(viewModel: ViewModel) {
        self.baseHandler.userDidEndLongPressOnBubble(viewModel: viewModel)
    }

    func userDidSelectMessage(viewModel: ViewModel) {
        self.baseHandler.userDidSelectMessage(viewModel: viewModel)
    }

    func userDidDeselectMessage(viewModel: ViewModel) {
        self.baseHandler.userDidDeselectMessage(viewModel: viewModel)
    }
}
