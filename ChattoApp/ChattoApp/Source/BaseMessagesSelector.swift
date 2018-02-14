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

import ChattoAdditions
import Foundation

public class BaseMessagesSelector: MessagesSelectorProtocol {

    public weak var delegate: MessagesSelectorDelegate?

    public var isActive = false {
        didSet {
            guard oldValue != self.isActive else { return }
            if self.isActive {
                self.selectedMessagesDictionary.removeAll()
            }
        }
    }

    public func canSelectMessage(_ message: MessageModelProtocol) -> Bool {
        return true
    }

    public func isMessageSelected(_ message: MessageModelProtocol) -> Bool {
        return self.selectedMessagesDictionary[message.uid] != nil
    }

    public func selectMessage(_ message: MessageModelProtocol) {
        self.selectedMessagesDictionary[message.uid] = message
        self.delegate?.messagesSelector(self, didSelectMessage: message)
    }

    public func deselectMessage(_ message: MessageModelProtocol) {
        self.selectedMessagesDictionary[message.uid] = nil
        self.delegate?.messagesSelector(self, didDeselectMessage: message)
    }

    public func selectedMessages() -> [MessageModelProtocol] {
        return Array(self.selectedMessagesDictionary.values)
    }

    // MARK: - Private

    private var selectedMessagesDictionary = [String: MessageModelProtocol]()
}
