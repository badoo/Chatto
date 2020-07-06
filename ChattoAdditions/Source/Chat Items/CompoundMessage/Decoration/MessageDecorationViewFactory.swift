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

public protocol MessageDecorationViewFactoryProtocol: AnyObject {
    associatedtype Model
    func canCreateDecorationView(for model: Model) -> Bool
    func makeDecorationView(for model: Model) -> UIView
    func makeLayoutProvider(for model: Model) -> MessageDecorationViewLayoutProviderProtocol
}

public final class AnyMessageDecorationViewFactory<Model>: MessageDecorationViewFactoryProtocol {

    private let _canCreateDecorationView: (_ model: Model) -> Bool
    private let _makeDecorationView: (_ model: Model) -> UIView
    private let _makeLayoutProvider: (_ model: Model) -> MessageDecorationViewLayoutProviderProtocol

    public init<Base: MessageDecorationViewFactoryProtocol>(_ base: Base) where Base.Model == Model {
        self._canCreateDecorationView = base.canCreateDecorationView(for:)
        self._makeDecorationView = base.makeDecorationView(for:)
        self._makeLayoutProvider = base.makeLayoutProvider(for:)
    }

    public func canCreateDecorationView(for model: Model) -> Bool {
        self._canCreateDecorationView(model)
    }

    public func makeDecorationView(for model: Model) -> UIView {
        self._makeDecorationView(model)
    }

    public func makeLayoutProvider(for model: Model) -> MessageDecorationViewLayoutProviderProtocol {
        self._makeLayoutProvider(model)
    }
}
