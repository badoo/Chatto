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

@available(iOS 11, *)
public final class CompoundMessageCollectionViewCell: BaseMessageCollectionViewCell<CompoundBubbleView> {

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }

    private func commonInit() {
        // 0 would interfere with scrolling
        self.longPressGestureRecognizer.minimumPressDuration = 0.05
    }

    public override func createBubbleView() -> CompoundBubbleView! {
        return CompoundBubbleView()
    }

    public var viewReferences: [ViewReference]?

    // MARK: - UIGestureRecognizerDelegate

    public override func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Default implementation is false. Don't allow scroll to be happened during long press gesture on temporary photos
        return false
    }

    public override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let shouldBegin = super.gestureRecognizerShouldBegin(gestureRecognizer)
        guard gestureRecognizer == self.longPressGestureRecognizer else { return shouldBegin }
        return shouldBegin && (self.onGestureRecognizerShouldBegin?(gestureRecognizer) ?? false)
    }

    public var onGestureRecognizerShouldBegin: ((_ gestureRecognizer: UIGestureRecognizer) -> Bool)?
}
