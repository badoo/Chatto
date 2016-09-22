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

public struct ChatInputBarAppearance {
    public struct SendButtonAppearance {
        public var font = UIFont.systemFont(ofSize: 16)
        public var insets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        public var title = ""
        public var titleColors: [UIControlStateWrapper: UIColor] = [
            UIControlStateWrapper(state: .disabled): UIColor.bma_color(rgb: 0x9AA3AB),
            UIControlStateWrapper(state: .normal): UIColor.bma_color(rgb: 0x007AFF),
            UIControlStateWrapper(state: .highlighted): UIColor.bma_color(rgb: 0x007AFF).bma_blendWithColor(UIColor.white.withAlphaComponent(0.4))
        ]
    }

    public struct TabBarAppearance {
        public var interItemSpacing: CGFloat = 10
        public var height: CGFloat = 44
        public var contentInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
    }

    public struct TextInputAppearance {
        public var font = UIFont.systemFont(ofSize: 12)
        public var textColor = UIColor.black
        public var placeholderFont = UIFont.systemFont(ofSize: 12)
        public var placeholderColor = UIColor.gray
        public var placeholderText = ""
        public var textInsets = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
    }

    public var sendButtonAppearance = SendButtonAppearance()
    public var tabBarAppearance = TabBarAppearance()
    public var textInputAppearance = TextInputAppearance()

    public init() {}
}


// Workaround for SR-2223
public struct UIControlStateWrapper: Hashable {

    public let controlState: UIControlState

    public init(state: UIControlState) {
        self.controlState = state
    }

    public var hashValue: Int {
        return Int(self.controlState.rawValue)
    }
}

public func == (lhs: UIControlStateWrapper, rhs: UIControlStateWrapper) -> Bool {
    return lhs.controlState == rhs.controlState
}
