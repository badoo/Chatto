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

final class StubMessageCollectionViewCellStyle: BaseMessageCollectionViewCellStyleProtocol {
    var stubbedFailedIcon: UIImage!
    var failedIcon: UIImage {
        return stubbedFailedIcon
    }
    var stubbedFailedIconHighlighted: UIImage!
    var failedIconHighlighted: UIImage {
        return stubbedFailedIconHighlighted
    }
    var stubbedSelectionIndicatorMargins: UIEdgeInsets!
    var selectionIndicatorMargins: UIEdgeInsets {
        return stubbedSelectionIndicatorMargins
    }
    var stubbedAvatarSizeResult: CGSize!
    func avatarSize(viewModel: MessageViewModelProtocol) -> CGSize {
        return stubbedAvatarSizeResult
    }
    var stubbedAvatarVerticalAlignmentResult: VerticalAlignment!
    func avatarVerticalAlignment(viewModel: MessageViewModelProtocol) -> VerticalAlignment {
        return stubbedAvatarVerticalAlignmentResult
    }
    var stubbedSelectionIndicatorIconResult: UIImage!
    func selectionIndicatorIcon(for viewModel: MessageViewModelProtocol) -> UIImage {
        return stubbedSelectionIndicatorIconResult
    }
    var stubbedAttributedStringForDateResult: NSAttributedString!
    func attributedStringForDate(_ date: String) -> NSAttributedString {
        return stubbedAttributedStringForDateResult
    }
    var stubbedLayoutConstantsResult: BaseMessageCollectionViewCellLayoutConstants!
    func layoutConstants(viewModel: MessageViewModelProtocol) -> BaseMessageCollectionViewCellLayoutConstants {
        return stubbedLayoutConstantsResult
    }
}
