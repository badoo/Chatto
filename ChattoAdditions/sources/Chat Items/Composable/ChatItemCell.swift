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

public final class ChatItemCell: UICollectionViewCell {

    public var indexed: AnyIndexedSubviews? {
        didSet {
            guard oldValue == nil else { return }
            guard let subviews = self.indexed else { fatalError() }
            self.setup(subviews: subviews)
        }
    }

    private func setup(subviews: AnyIndexedSubviews) {
        let subview = subviews.root
        subview.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(subview)
        NSLayoutConstraint.activate([
            subview.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor),
            subview.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor),
            subview.topAnchor.constraint(equalTo: self.contentView.topAnchor),
            subview.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor)
        ])
    }
}
