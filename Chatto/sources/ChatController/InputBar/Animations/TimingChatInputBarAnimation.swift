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

public final class TimingChatInputBarAnimation: ChatInputBarAnimationProtocol {

    let duration: CFTimeInterval
    let timingFunction: CAMediaTimingFunction

    public init(duration: CFTimeInterval,
                timingFunction: CAMediaTimingFunction) {
        self.duration = duration
        self.timingFunction = timingFunction
    }

    public func animate(view: UIView, completion: (() -> Void)?) {
        CATransaction.begin()
        CATransaction.setAnimationTimingFunction(self.timingFunction)
        UIView.animate(
            withDuration: self.duration,
            animations: { view.layoutIfNeeded() },
            completion: { _ in }
        )
        CATransaction.setCompletionBlock(completion) // this callback is guaranteed to be called
        CATransaction.commit()
    }
}
