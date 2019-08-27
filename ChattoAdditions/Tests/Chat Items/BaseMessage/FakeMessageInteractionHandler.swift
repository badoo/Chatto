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
import Foundation

final class FakeMessageInteractionHandler: BaseMessageInteractionHandlerProtocol {

    typealias ViewModelT = MessageViewModel

    var invokedUserDidTapOnFailIcon = false
    var invokedUserDidTapOnFailIconCount = 0
    var invokedUserDidTapOnFailIconParameters: (viewModel: ViewModelT, failIconView: UIView)?
    var invokedUserDidTapOnFailIconParametersList = [(viewModel: ViewModelT, failIconView: UIView)]()
    func userDidTapOnFailIcon(viewModel: ViewModelT, failIconView: UIView) {
        invokedUserDidTapOnFailIcon = true
        invokedUserDidTapOnFailIconCount += 1
        invokedUserDidTapOnFailIconParameters = (viewModel, failIconView)
        invokedUserDidTapOnFailIconParametersList.append((viewModel, failIconView))
    }
    var invokedUserDidTapOnAvatar = false
    var invokedUserDidTapOnAvatarCount = 0
    var invokedUserDidTapOnAvatarParameters: (viewModel: ViewModelT, Void)?
    var invokedUserDidTapOnAvatarParametersList = [(viewModel: ViewModelT, Void)]()
    func userDidTapOnAvatar(viewModel: ViewModelT) {
        invokedUserDidTapOnAvatar = true
        invokedUserDidTapOnAvatarCount += 1
        invokedUserDidTapOnAvatarParameters = (viewModel, ())
        invokedUserDidTapOnAvatarParametersList.append((viewModel, ()))
    }
    var invokedUserDidTapOnBubble = false
    var invokedUserDidTapOnBubbleCount = 0
    var invokedUserDidTapOnBubbleParameters: (viewModel: ViewModelT, Void)?
    var invokedUserDidTapOnBubbleParametersList = [(viewModel: ViewModelT, Void)]()
    func userDidTapOnBubble(viewModel: ViewModelT) {
        invokedUserDidTapOnBubble = true
        invokedUserDidTapOnBubbleCount += 1
        invokedUserDidTapOnBubbleParameters = (viewModel, ())
        invokedUserDidTapOnBubbleParametersList.append((viewModel, ()))
    }
    var invokedUserDidBeginLongPressOnBubble = false
    var invokedUserDidBeginLongPressOnBubbleCount = 0
    var invokedUserDidBeginLongPressOnBubbleParameters: (viewModel: ViewModelT, Void)?
    var invokedUserDidBeginLongPressOnBubbleParametersList = [(viewModel: ViewModelT, Void)]()
    func userDidBeginLongPressOnBubble(viewModel: ViewModelT) {
        invokedUserDidBeginLongPressOnBubble = true
        invokedUserDidBeginLongPressOnBubbleCount += 1
        invokedUserDidBeginLongPressOnBubbleParameters = (viewModel, ())
        invokedUserDidBeginLongPressOnBubbleParametersList.append((viewModel, ()))
    }
    var invokedUserDidEndLongPressOnBubble = false
    var invokedUserDidEndLongPressOnBubbleCount = 0
    var invokedUserDidEndLongPressOnBubbleParameters: (viewModel: ViewModelT, Void)?
    var invokedUserDidEndLongPressOnBubbleParametersList = [(viewModel: ViewModelT, Void)]()
    func userDidEndLongPressOnBubble(viewModel: ViewModelT) {
        invokedUserDidEndLongPressOnBubble = true
        invokedUserDidEndLongPressOnBubbleCount += 1
        invokedUserDidEndLongPressOnBubbleParameters = (viewModel, ())
        invokedUserDidEndLongPressOnBubbleParametersList.append((viewModel, ()))
    }
    var invokedUserDidSelectMessage = false
    var invokedUserDidSelectMessageCount = 0
    var invokedUserDidSelectMessageParameters: (viewModel: ViewModelT, Void)?
    var invokedUserDidSelectMessageParametersList = [(viewModel: ViewModelT, Void)]()
    func userDidSelectMessage(viewModel: ViewModelT) {
        invokedUserDidSelectMessage = true
        invokedUserDidSelectMessageCount += 1
        invokedUserDidSelectMessageParameters = (viewModel, ())
        invokedUserDidSelectMessageParametersList.append((viewModel, ()))
    }
    var invokedUserDidDeselectMessage = false
    var invokedUserDidDeselectMessageCount = 0
    var invokedUserDidDeselectMessageParameters: (viewModel: ViewModelT, Void)?
    var invokedUserDidDeselectMessageParametersList = [(viewModel: ViewModelT, Void)]()
    func userDidDeselectMessage(viewModel: ViewModelT) {
        invokedUserDidDeselectMessage = true
        invokedUserDidDeselectMessageCount += 1
        invokedUserDidDeselectMessageParameters = (viewModel, ())
        invokedUserDidDeselectMessageParametersList.append((viewModel, ()))
    }
}
