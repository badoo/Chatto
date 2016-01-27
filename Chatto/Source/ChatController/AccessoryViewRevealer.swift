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

public protocol AccessoryViewRevealable {
    func revealAccessoryView(maximumOffset offset: CGFloat, animated: Bool)
}

class AccessoryViewRevealer: NSObject, UIGestureRecognizerDelegate {

    private let panRecognizer: UIPanGestureRecognizer = UIPanGestureRecognizer()
    private let collectionView: UICollectionView

    init(collectionView: UICollectionView) {
        self.collectionView = collectionView
        super.init()
        self.collectionView.addGestureRecognizer(self.panRecognizer)
        self.panRecognizer.addTarget(self, action: "handlePan:")
        self.panRecognizer.delegate = self
    }

    @objc
    private func handlePan(panRecognizer: UIPanGestureRecognizer) {
        switch panRecognizer.state {
        case .Began:
            break
        case .Changed:
            let translation = panRecognizer.translationInView(self.collectionView)
            self.revealAccessoryView(atOffset: -translation.x)
        case .Ended, .Cancelled, .Failed:
            self.revealAccessoryView(atOffset: 0)
        default:
            break
        }
    }

    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer != self.panRecognizer {
            return true
        }

        let translation = self.panRecognizer.translationInView(self.collectionView)
        let x = CGFloat.abs(translation.x), y = CGFloat.abs(translation.y)
        let angleRads = atan2(y, x)
        let threshold: CGFloat = 0.0872665 // ~5 degrees
        return angleRads < threshold
    }

    private func revealAccessoryView(atOffset offset: CGFloat) {
        for cell in self.collectionView.visibleCells() {
            if let cell = cell as? AccessoryViewRevealable {
                cell.revealAccessoryView(maximumOffset: offset, animated: offset == 0)
            }
        }
    }
}
