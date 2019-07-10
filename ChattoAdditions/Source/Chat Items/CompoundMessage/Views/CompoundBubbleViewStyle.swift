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

public protocol CompoundBubbleViewStyleProtocol {
    typealias ViewModel = MessageViewModelProtocol
    var hideBubbleForSingleContent: Bool { get }
    func backgroundColor(forViewModel viewModel: ViewModel) -> UIColor?
    func maskingImage(forViewModel viewModel: ViewModel) -> UIImage?
    func borderImage(forViewModel viewModel: ViewModel) -> UIImage?
    func tailWidth(forViewModel viewModel: ViewModel) -> CGFloat
}

public final class DefaultCompoundBubbleViewStyle: CompoundBubbleViewStyleProtocol {
    public struct BubbleMasks {
        public let incomingTail: () -> UIImage
        public let incomingNoTail: () -> UIImage
        public let outgoingTail: () -> UIImage
        public let outgoingNoTail: () -> UIImage
        public let tailWidth: CGFloat

        public init(incomingTail: @autoclosure @escaping () -> UIImage,
                    incomingNoTail: @autoclosure @escaping () -> UIImage,
                    outgoingTail: @autoclosure @escaping () -> UIImage,
                    outgoingNoTail: @autoclosure @escaping () -> UIImage,
                    tailWidth: CGFloat) {
            self.incomingTail = incomingTail
            self.incomingNoTail = incomingNoTail
            self.outgoingTail = outgoingTail
            self.outgoingNoTail = outgoingNoTail
            self.tailWidth = tailWidth
        }
    }

    private let baseStyle: BaseMessageCollectionViewCellDefaultStyle
    private let bubbleMasks: BubbleMasks

    public init(baseStyle: BaseMessageCollectionViewCellDefaultStyle = BaseMessageCollectionViewCellDefaultStyle(),
                bubbleMasks: BubbleMasks = .default,
                hideBubbleForSingleContent: Bool = false) {
        self.baseStyle = baseStyle
        self.bubbleMasks = bubbleMasks
        self.hideBubbleForSingleContent = hideBubbleForSingleContent
    }

    // MARK: CompoundBubbleViewStyleProtocol

    public let hideBubbleForSingleContent: Bool

    public func backgroundColor(forViewModel viewModel: ViewModel) -> UIColor? {
        return viewModel.isIncoming ? self.baseStyle.baseColorIncoming : self.baseStyle.baseColorOutgoing
    }

    public func maskingImage(forViewModel viewModel: ViewModel) -> UIImage? {
        return self.bubbleMasks.image(incoming: viewModel.isIncoming,
                                      showTail: viewModel.decorationAttributes.isShowingTail)
    }

    public func borderImage(forViewModel viewModel: ViewModel) -> UIImage? {
        return self.baseStyle.borderImage(viewModel: viewModel)
    }

    public func tailWidth(forViewModel _: ViewModel) -> CGFloat {
        return self.bubbleMasks.tailWidth
    }
}

extension DefaultCompoundBubbleViewStyle.BubbleMasks {
    fileprivate func image(incoming: Bool, showTail: Bool) -> UIImage {
        switch (incoming, showTail) {
        case (true, true):
            return self.incomingTail()
        case (true, false):
            return self.incomingNoTail()
        case (false, true):
            return self.outgoingTail()
        case (false, false):
            return self.outgoingNoTail()
        }
    }

    public static var `default`: DefaultCompoundBubbleViewStyle.BubbleMasks {
        let bundle = Bundle(for: DefaultCompoundBubbleViewStyle.self)
        return DefaultCompoundBubbleViewStyle.BubbleMasks(
            incomingTail: UIImage(named: "bubble-incoming-tail", in: bundle, compatibleWith: nil)!,
            incomingNoTail: UIImage(named: "bubble-incoming", in: bundle, compatibleWith: nil)!,
            outgoingTail: UIImage(named: "bubble-outgoing-tail", in: bundle, compatibleWith: nil)!,
            outgoingNoTail: UIImage(named: "bubble-outgoing", in: bundle, compatibleWith: nil)!,
            tailWidth: 6
        )
    }
}
