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
import UIKit

// swiftlint:disable all

public final class FakeMessageInteractionHandler: BaseMessageInteractionHandlerProtocol {

    public typealias MessageType = MessageModel
    public typealias ViewModelType = MessageViewModel

    private var isNiceMock: Bool

    convenience init() {
        self.init(isNiceMock: false)
    }

    static func niceMock() -> FakeMessageInteractionHandler {
        return FakeMessageInteractionHandler(isNiceMock: true)
    }

    private init(isNiceMock: Bool) {
        self.isNiceMock = isNiceMock
    }

    var _userDidTapOnFailIcon = _UserDidTapOnFailIcon()
    var _userDidTapOnAvatar = _UserDidTapOnAvatar()
    var _userDidTapOnBubble = _UserDidTapOnBubble()
    var _userDidBeginLongPressOnBubble = _UserDidBeginLongPressOnBubble()
    var _userDidEndLongPressOnBubble = _UserDidEndLongPressOnBubble()
    var _userDidSelectMessage = _UserDidSelectMessage()
    var _userDidDeselectMessage = _UserDidDeselectMessage()

    var onUserDidTapOnFailIcon: ((MessageType, ViewModelType, UIView) -> Void)? = nil
    public func userDidTapOnFailIcon(message: MessageType, viewModel: ViewModelType, failIconView: UIView) -> Void {
        if let fakeImplementation = self.onUserDidTapOnFailIcon {
            fakeImplementation(message, viewModel, failIconView)
        } else {
            if !self.isNiceMock { fatalError("\(String(describing: self)) \(#function) is not implemented. Add your implementation or use .niceMock()") }
            self._userDidTapOnFailIcon.history.append((message, viewModel, failIconView))
        }
    }

    var onUserDidTapOnAvatar: ((MessageType, ViewModelType) -> Void)? = nil
    public func userDidTapOnAvatar(message: MessageType, viewModel: ViewModelType) -> Void {
        if let fakeImplementation = self.onUserDidTapOnAvatar {
            fakeImplementation(message, viewModel)
        } else {
            if !self.isNiceMock { fatalError("\(String(describing: self)) \(#function) is not implemented. Add your implementation or use .niceMock()") }
            self._userDidTapOnAvatar.history.append((message, viewModel))
        }
    }

    var onUserDidTapOnBubble: ((MessageType, ViewModelType) -> Void)? = nil
    public func userDidTapOnBubble(message: MessageType, viewModel: ViewModelType) -> Void {
        if let fakeImplementation = self.onUserDidTapOnBubble {
            fakeImplementation(message, viewModel)
        } else {
            if !self.isNiceMock { fatalError("\(String(describing: self)) \(#function) is not implemented. Add your implementation or use .niceMock()") }
            self._userDidTapOnBubble.history.append((message, viewModel))
        }
    }

    var onUserDidBeginLongPressOnBubble: ((MessageType, ViewModelType) -> Void)? = nil
    public func userDidBeginLongPressOnBubble(message: MessageType, viewModel: ViewModelType) -> Void {
        if let fakeImplementation = self.onUserDidBeginLongPressOnBubble {
            fakeImplementation(message, viewModel)
        } else {
            if !self.isNiceMock { fatalError("\(String(describing: self)) \(#function) is not implemented. Add your implementation or use .niceMock()") }
            self._userDidBeginLongPressOnBubble.history.append((message, viewModel))
        }
    }

    var onUserDidEndLongPressOnBubble: ((MessageType, ViewModelType) -> Void)? = nil
    public func userDidEndLongPressOnBubble(message: MessageType, viewModel: ViewModelType) -> Void {
        if let fakeImplementation = self.onUserDidEndLongPressOnBubble {
            fakeImplementation(message, viewModel)
        } else {
            if !self.isNiceMock { fatalError("\(String(describing: self)) \(#function) is not implemented. Add your implementation or use .niceMock()") }
            self._userDidEndLongPressOnBubble.history.append((message, viewModel))
        }
    }

    var onUserDidSelectMessage: ((MessageType, ViewModelType) -> Void)? = nil
    public func userDidSelectMessage(message: MessageType, viewModel: ViewModelType) -> Void {
        if let fakeImplementation = self.onUserDidSelectMessage {
            fakeImplementation(message, viewModel)
        } else {
            if !self.isNiceMock { fatalError("\(String(describing: self)) \(#function) is not implemented. Add your implementation or use .niceMock()") }
            self._userDidSelectMessage.history.append((message, viewModel))
        }
    }

    var onUserDidDeselectMessage: ((MessageType, ViewModelType) -> Void)? = nil
    public func userDidDeselectMessage(message: MessageType, viewModel: ViewModelType) -> Void {
        if let fakeImplementation = self.onUserDidDeselectMessage {
            fakeImplementation(message, viewModel)
        } else {
            if !self.isNiceMock { fatalError("\(String(describing: self)) \(#function) is not implemented. Add your implementation or use .niceMock()") }
            self._userDidDeselectMessage.history.append((message, viewModel))
        }
    }
}

public extension FakeMessageInteractionHandler {

    struct _UserDidTapOnFailIcon {
        var history: [(message: MessageType, viewModel: ViewModelType, failIconView: UIView)] = []
        var lastArgs: (message: MessageType, viewModel: ViewModelType, failIconView: UIView)! { return self.history.last }
        var callsCount: Int { return self.history.count }
        var wasCalled: Bool { return self.callsCount > 0 }
    }

    struct _UserDidTapOnAvatar {
        var history: [(message: MessageType, viewModel: ViewModelType)] = []
        var lastArgs: (message: MessageType, viewModel: ViewModelType)! { return self.history.last }
        var callsCount: Int { return self.history.count }
        var wasCalled: Bool { return self.callsCount > 0 }
    }

    struct _UserDidTapOnBubble {
        var history: [(message: MessageType, viewModel: ViewModelType)] = []
        var lastArgs: (message: MessageType, viewModel: ViewModelType)! { return self.history.last }
        var callsCount: Int { return self.history.count }
        var wasCalled: Bool { return self.callsCount > 0 }
    }

    struct _UserDidBeginLongPressOnBubble {
        var history: [(message: MessageType, viewModel: ViewModelType)] = []
        var lastArgs: (message: MessageType, viewModel: ViewModelType)! { return self.history.last }
        var callsCount: Int { return self.history.count }
        var wasCalled: Bool { return self.callsCount > 0 }
    }

    struct _UserDidEndLongPressOnBubble {
        var history: [(message: MessageType, viewModel: ViewModelType)] = []
        var lastArgs: (message: MessageType, viewModel: ViewModelType)! { return self.history.last }
        var callsCount: Int { return self.history.count }
        var wasCalled: Bool { return self.callsCount > 0 }
    }

    struct _UserDidSelectMessage {
        var history: [(message: MessageType, viewModel: ViewModelType)] = []
        var lastArgs: (message: MessageType, viewModel: ViewModelType)! { return self.history.last }
        var callsCount: Int { return self.history.count }
        var wasCalled: Bool { return self.callsCount > 0 }
    }

    struct _UserDidDeselectMessage {
        var history: [(message: MessageType, viewModel: ViewModelType)] = []
        var lastArgs: (message: MessageType, viewModel: ViewModelType)! { return self.history.last }
        var callsCount: Int { return self.history.count }
        var wasCalled: Bool { return self.callsCount > 0 }
    }
}

// swiftlint:enable all
