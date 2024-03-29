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

import Foundation
import UIKit

private let scale = UIScreen.main.scale

infix operator >=~
func >=~ (lhs: CGFloat, rhs: CGFloat) -> Bool {
    return round(lhs * scale) >= round(rhs * scale)
}

extension UIScrollView {
    func chatto_setContentInsetAdjustment(enabled: Bool, in viewController: UIViewController) {
        self.contentInsetAdjustmentBehavior = enabled ? .always : .never
    }

    func chatto_setAutomaticallyAdjustsScrollIndicatorInsets(_ adjusts: Bool) {
        if #available(iOS 13.0, *) {
            self.automaticallyAdjustsScrollIndicatorInsets = adjusts
        }
    }

    func chatto_setVerticalScrollIndicatorInsets(_ insets: UIEdgeInsets) {
        self.verticalScrollIndicatorInsets = insets
    }
}

extension UICollectionView {
    func chatto_setIsPrefetchingEnabled(_ isPrefetchingEnabled: Bool) {
        self.isPrefetchingEnabled = isPrefetchingEnabled
    }
}
