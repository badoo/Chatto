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

import Chatto

public final class MessageContentModule {
    public typealias Presenter = Any
    public let view: UIView
    public let showBorder: Bool
    public let presenter: Presenter

    public init(view: UIView,
                presenter: Presenter,
                showBorder: Bool = false) {
        self.view = view
        self.showBorder = showBorder
        self.presenter = presenter
    }

    public var onWillBeShown: (() -> Void)?
    public var onWasHidden: (() -> Void)?

    func willBeShown() {
        self.onWillBeShown?()
    }

    func wasHidden() {
        self.onWasHidden?()
    }
}

public protocol MessageContentFactoryProtocol {
    associatedtype Model
    var identifier: String { get }
    func canCreateMessageModule(forModel model: Model) -> Bool
    func createMessageModule(forModel model: Model) -> MessageContentModule
    func createLayoutProvider(forModel model: Model) -> MessageManualLayoutProviderProtocol
    func createMenuPresenter(forModel model: Model) -> ChatItemMenuPresenterProtocol?
}

public extension MessageContentFactoryProtocol {
    var identifier: String { return "\(type(of: self as Any))" }
}

public final class AnyMessageContentFactory<Model>: MessageContentFactoryProtocol {

    private let _canCreateMessageModule: (Model) -> Bool
    private let _createMessageModule: (Model) -> MessageContentModule
    private let _createLayoutProvider: (Model) -> MessageManualLayoutProviderProtocol
    private let _createMenuPresenter: (Model) -> ChatItemMenuPresenterProtocol?

    public init<U: MessageContentFactoryProtocol>(_ base: U) where U.Model == Model {
        self.identifier = base.identifier
        self._canCreateMessageModule = base.canCreateMessageModule
        self._createMessageModule = base.createMessageModule
        self._createLayoutProvider = base.createLayoutProvider
        self._createMenuPresenter = base.createMenuPresenter
    }

    public let identifier: String

    public func canCreateMessageModule(forModel model: Model) -> Bool {
        return self._canCreateMessageModule(model)
    }

    public func createMessageModule(forModel model: Model) -> MessageContentModule {
        return self._createMessageModule(model)
    }

    public func createLayoutProvider(forModel model: Model) -> MessageManualLayoutProviderProtocol {
        return self._createLayoutProvider(model)
    }

    public func createMenuPresenter(forModel model: Model) -> ChatItemMenuPresenterProtocol? {
        return self._createMenuPresenter(model)
    }
}
