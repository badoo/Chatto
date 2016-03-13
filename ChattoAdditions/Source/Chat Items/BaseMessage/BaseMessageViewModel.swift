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

public enum MessageViewModelStatus {
    case Success
    case Sending
    case Failed
}

public extension MessageStatus {
    public func viewModelStatus() -> MessageViewModelStatus {
        switch self {
        case .Success:
            return MessageViewModelStatus.Success
        case .Failed:
            return MessageViewModelStatus.Failed
        case .Sending:
            return MessageViewModelStatus.Sending
        }
    }
}

public protocol MessageViewModelProtocol: class { // why class? https://gist.github.com/diegosanchezr/29979d22c995b4180830
    var isIncoming: Bool { get }
    var showsTail: Bool { get set }
    var showsFailedIcon: Bool { get }
    var date: String { get }
    var status: MessageViewModelStatus { get }
    var avatarImage: Observable<UIImage?> { set get }
}

public protocol DecoratedMessageViewModelProtocol: MessageViewModelProtocol {
    var messageViewModel: MessageViewModelProtocol { get }
}

extension DecoratedMessageViewModelProtocol {
    public var isIncoming: Bool {
        return self.messageViewModel.isIncoming
    }
    public var showsTail: Bool {
        get {
            return self.messageViewModel.showsTail
        }
        set {
            self.messageViewModel.showsTail = newValue
        }
    }
    public var date: String {
        return self.messageViewModel.date
    }

    public var status: MessageViewModelStatus {
        return self.messageViewModel.status
    }

    public var showsFailedIcon: Bool {
        return self.messageViewModel.showsFailedIcon
    }

    public var avatarImage: Observable<UIImage?> {
        get {
            return self.messageViewModel.avatarImage
        }
        set {
            self.messageViewModel.avatarImage = newValue
        }
    }
}

public class MessageViewModel: MessageViewModelProtocol {
    public var isIncoming: Bool {
        return self.messageModel.isIncoming
    }

    public var status: MessageViewModelStatus {
        return self.messageModel.status.viewModelStatus()
    }

    public var showsTail: Bool
    public lazy var date: String = {
        return self.dateFormatter.stringFromDate(self.messageModel.date)
    }()

    public let dateFormatter: NSDateFormatter
    public private(set) var messageModel: MessageModelProtocol

    public init(dateFormatter: NSDateFormatter, showsTail: Bool, messageModel: MessageModelProtocol, avatarImage: UIImage?) {
        self.dateFormatter = dateFormatter
        self.showsTail = showsTail
        self.messageModel = messageModel
        self.avatarImage = Observable<UIImage?>(avatarImage)
    }

    public var showsFailedIcon: Bool {
        return self.status == .Failed
    }

    public var avatarImage: Observable<UIImage?>
}

public class MessageViewModelDefaultBuilder {

    public init() {}

    static let dateFormatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    public func createMessageViewModel(message: MessageModelProtocol) -> MessageViewModelProtocol {
        // Override to use default avatarImage
        return MessageViewModel(dateFormatter: MessageViewModelDefaultBuilder.dateFormatter, showsTail: false, messageModel: message, avatarImage: nil)
    }
}
