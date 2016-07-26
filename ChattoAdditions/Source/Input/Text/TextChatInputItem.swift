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

public class TextChatInputItem {
    typealias Class = TextChatInputItem
    public var textInputHandler: ((String) -> Void)?

    let buttonAppearance: ChatInputButtonAppearance
    public init(buttonAppearance: ChatInputButtonAppearance = Class.createDefaultButtonAppearance()) {
        self.buttonAppearance = buttonAppearance
    }

    public class func createDefaultButtonAppearance() -> ChatInputButtonAppearance {
        let images: [UIControlState: UIImage] = [
            .Normal: UIImage(named: "text-icon-unselected", inBundle: NSBundle(forClass: TextChatInputItem.self), compatibleWithTraitCollection: nil)!,
            .Selected: UIImage(named: "text-icon-selected", inBundle: NSBundle(forClass: TextChatInputItem.self), compatibleWithTraitCollection: nil)!,
            .Highlighted: UIImage(named: "text-icon-selected", inBundle: NSBundle(forClass: TextChatInputItem.self), compatibleWithTraitCollection: nil)!
        ]
        return ChatInputButtonAppearance(images: images, size: nil)
    }

    lazy private var internalInputButton: ChatInputButton = {
        return ChatInputButton.makeInputButton(withAppearance: self.buttonAppearance)
    }()

    // Move to protocol extension
    public var selected = false {
        didSet {
            self.internalInputButton.selected = self.selected
        }
    }
}

// MARK: - ChatInputItemProtocol
extension TextChatInputItem : ChatInputItemProtocol {
    public var presentationMode: ChatInputItemPresentationMode {
        return .Keyboard
    }

    public var showsSendButton: Bool {
        return true
    }

    public var inputView: UIView? {
        return nil
    }

    public var inputButton: ChatInputButton {
        return self.internalInputButton
    }

    public func handleInput(input: AnyObject) {
        if let text = input as? String {
            self.textInputHandler?(text)
        }
    }
}
