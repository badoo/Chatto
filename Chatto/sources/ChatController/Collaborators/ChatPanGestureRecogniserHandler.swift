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


import Foundation

public protocol ChatViewControllerDependant: AnyObject   {
    var chatViewController: BaseChatViewController? { get set }
}

public typealias ChatGestureHandlerProtocol = ChatViewControllerDependant

public final class ChatPanGestureRecogniserHandler: ChatGestureHandlerProtocol {

    private let panGestureHandlerConfig: CellPanGestureHandlerConfig
    private let replyActionHandler: ReplyActionHandler
    private let replyFeedbackGenerator: ReplyFeedbackGeneratorProtocol

    private var cellPanGestureHandler: CellPanGestureHandler?

    public weak var chatViewController: BaseChatViewController? {
        didSet {
            guard let chatViewController = self.chatViewController else { return }

            self.cellPanGestureHandler = CellPanGestureHandler(
                collectionView: chatViewController.collectionView,
                config: self.panGestureHandlerConfig
            )
            self.cellPanGestureHandler?.replyDelegate = self
        }
    }

    public init(panGestureHandlerConfig: CellPanGestureHandlerConfig,
                replyActionHandler: ReplyActionHandler,
                replyFeedbackGenerator: ReplyFeedbackGeneratorProtocol) {
        self.panGestureHandlerConfig = panGestureHandlerConfig
        self.replyActionHandler = replyActionHandler
        self.replyFeedbackGenerator = replyFeedbackGenerator
    }
}

extension ChatPanGestureRecogniserHandler: ReplyIndicatorRevealerDelegate {

    public func didPassThreshold(at: IndexPath) {
        self.replyFeedbackGenerator.generateFeedback()
    }

    public func didFinishReplyGesture(at indexPath: IndexPath) {
        guard let chatItemCompanionCollection = self.chatViewController?.chatItemCompanionCollection else {
            return
        }

        let item = chatItemCompanionCollection[indexPath.item].chatItem
        self.replyActionHandler.handleReply(for: item)
    }

    public func didCancelReplyGesture(at: IndexPath) { }
}
