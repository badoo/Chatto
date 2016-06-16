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
        public var font = UIFont.systemFontOfSize(16)
        public var insets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        public var title = ""
        public var titleColors: [UIControlState: UIColor] = [
            .Disabled: UIColor.bma_color(rgb: 0x9AA3AB),
            .Normal: UIColor.bma_color(rgb: 0x007AFF),
            .Highlighted: UIColor.bma_color(rgb: 0x007AFF).bma_blendWithColor(UIColor.whiteColor().colorWithAlphaComponent(0.4))
        ]
    }

    public struct TabBarAppearance {
        public var interItemSpacing: CGFloat = 10
        public var height: CGFloat = 44
        public var contentInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
    }

    public struct TextInputAppearance {
        public var font = UIFont.systemFontOfSize(12)
        public var textColor = UIColor.blackColor()
        public var placeholderFont = UIFont.systemFontOfSize(12)
        public var placeholderColor = UIColor.grayColor()
        public var placeholderText = ""
        public var textInsets = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
    }

    public var sendButtonAppearance = SendButtonAppearance()
    public var tabBarAppearance = TabBarAppearance()
    public var textInputAppearance = TextInputAppearance()

    public init() {}
}


extension UIControlState: Hashable {
    public var hashValue: Int {
        return Int(self.rawValue)
    }
}
