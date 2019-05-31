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
}

public protocol MessageContentFactoryProtocol {
    associatedtype Model
    func canCreateMessageModule(forModel model: Model) -> Bool
    func createMessageModule(forModel model: Model) -> MessageContentModule
    func createLayoutProvider(forModel model: Model) -> MessageManualLayoutProviderProtocol
}

public final class AnyMessageContentFactory<Model>: MessageContentFactoryProtocol {

    private let _canCreateMessageModule: (Model) -> Bool
    private let _createMessageModule: (Model) -> MessageContentModule
    private let _createLayoutProvider: (Model) -> MessageManualLayoutProviderProtocol

    public init<U: MessageContentFactoryProtocol>(_ base: U) where U.Model == Model {
        self._canCreateMessageModule = base.canCreateMessageModule
        self._createMessageModule = base.createMessageModule
        self._createLayoutProvider = base.createLayoutProvider
    }

    public func canCreateMessageModule(forModel model: Model) -> Bool {
        return self._canCreateMessageModule(model)
    }

    public func createMessageModule(forModel model: Model) -> MessageContentModule {
        return self._createMessageModule(model)
    }

    public func createLayoutProvider(forModel model: Model) -> MessageManualLayoutProviderProtocol {
        return self._createLayoutProvider(model)
    }
}
