/*
 The MIT License (MIT)

 Copyright (c) 2015-present Badoo Trading Limited.

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
*/

import UIKit

open class HorizontalStackScrollView: UIScrollView {

    private var arrangedViews: [UIView] = []
    private var arrangedViewContraints: [NSLayoutConstraint] = []
    var interItemSpacing: CGFloat = 0.0 {
        didSet {
            self.setNeedsUpdateConstraints()
        }
    }

    func addArrangedViews(_ views: [UIView]) {
        for view in views {
            view.translatesAutoresizingMaskIntoConstraints = false
            self.addSubview(view)
        }
        self.arrangedViews.append(contentsOf: views)
        self.setNeedsUpdateConstraints()
    }

    override open func updateConstraints() {
        super.updateConstraints()
        self.removeConstraintsForArrangedViews()
        self.addConstraintsForArrengedViews()
    }

    private func removeConstraintsForArrangedViews() {
        for constraint in self.arrangedViewContraints {
            self.removeConstraint(constraint)
        }
        self.arrangedViewContraints.removeAll()
    }

    private func addConstraintsForArrengedViews() {
        for (index, view) in arrangedViews.enumerated() {
            switch index {
            case 0:
                let constraint = NSLayoutConstraint(item: view, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 0)
                self.addConstraint(constraint)
                self.arrangedViewContraints.append(constraint)
            case arrangedViews.count-1:
                let constraint = NSLayoutConstraint(item: view, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: 0)
                self.addConstraint(constraint)
                self.arrangedViewContraints.append(constraint)
                fallthrough
            default:
                let constraint = NSLayoutConstraint(item: view, attribute: .leading, relatedBy: .equal, toItem: arrangedViews[index-1], attribute: .trailing, multiplier: 1, constant: self.interItemSpacing)
                self.addConstraint(constraint)
                self.arrangedViewContraints.append(constraint)
            }
            self.addConstraint(NSLayoutConstraint(item: view, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0))
        }
    }
}
