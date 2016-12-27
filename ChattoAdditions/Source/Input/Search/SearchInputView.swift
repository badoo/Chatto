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

import UIKit
import Chatto

public struct SearchInputViewAppearance {
    public var liveCameraCellAppearence: LiveCameraCellAppearance
    public init(liveCameraCellAppearence: LiveCameraCellAppearance) {
        self.liveCameraCellAppearence = liveCameraCellAppearence
    }
}

protocol SearchInputViewProtocol {
    weak var delegate: SearchInputViewDelegate? { get set }
    weak var presentingController: UIViewController? { get }
}

protocol SearchInputViewDelegate: class {
    func inputView(_ inputView: SearchInputViewProtocol, didSelectImage image: URL?)
}

class SearchInputView: UIView, SearchInputViewProtocol {
    fileprivate lazy var collectionViewQueue = SerialTaskQueue()

    weak var delegate: SearchInputViewDelegate?
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }

    weak var presentingController: UIViewController?
    var appearance: SearchInputViewAppearance?
    init(presentingController: UIViewController?, appearance: SearchInputViewAppearance) {
        super.init(frame: CGRect.zero)
        self.presentingController = presentingController
        self.appearance = appearance
        self.commonInit()
    }

    private func commonInit() {
        self.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.collectionViewQueue.start()
    }

    func reload() {
        self.collectionViewQueue.addTask { [weak self] (completion) in
            DispatchQueue.main.async(execute: completion)
        }
    }
}
