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

open class TextChatInputItem {
    typealias Class = TextChatInputItem
    public var textInputHandler: ((String) -> Void)?

    let buttonAppearance: TabInputButtonAppearance
    public init(tabInputButtonAppearance: TabInputButtonAppearance = TextChatInputItem.createDefaultButtonAppearance()) {
        self.buttonAppearance = tabInputButtonAppearance
    }

    public static func createDefaultButtonAppearance() -> TabInputButtonAppearance {
        let images: [UIControlStateWrapper: UIImage] = [
            UIControlStateWrapper(state: .normal): UIImage(named: "text-icon-unselected", in: Bundle(for: TextChatInputItem.self), compatibleWith: nil)!,
            UIControlStateWrapper(state: .selected): UIImage(named: "text-icon-selected", in: Bundle(for: TextChatInputItem.self), compatibleWith: nil)!,
            UIControlStateWrapper(state: .highlighted): UIImage(named: "text-icon-selected", in: Bundle(for: TextChatInputItem.self), compatibleWith: nil)!
        ]
        return TabInputButtonAppearance(images: images, size: nil)
    }

    lazy fileprivate var internalTabView: TabInputButton = {
        return TabInputButton.makeInputButton(withAppearance: self.buttonAppearance, accessibilityID: "text.chat.input.view")
    }()

    open var selected = false {
        didSet {
            self.internalTabView.isSelected = self.selected
        }
    }
}

// MARK: - ChatInputItemProtocol
extension TextChatInputItem: ChatInputItemProtocol {
    public var supportsExpandableState: Bool {
        return false
    }

    public var expandedStateTopMargin: CGFloat {
        return 0.0
    }

    public var presentationMode: ChatInputItemPresentationMode {
        return .keyboard
    }

    public var showsSendButton: Bool {
        return true
    }

    public var inputView: UIView? {
        return nil
    }

    public var tabView: UIView {
        return self.internalTabView
    }

    public func handleInput(_ input: AnyObject) {
        if let text = input as? String {
            self.textInputHandler?(text)
        }
    }

    public var shouldSaveDraftMessage: Bool {
        return false
    }
}
