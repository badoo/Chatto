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

import ChattoAdditions
import Foundation

final class FakeViewModelBuilder: ViewModelBuilderProtocol {

    typealias ModelT = MessageModel
    typealias ViewModelT = MessageViewModel

    var invokedCanCreateViewModel = false
    var invokedCanCreateViewModelCount = 0
    var invokedCanCreateViewModelParameters: (model: Any, Void)?
    var invokedCanCreateViewModelParametersList = [(model: Any, Void)]()
    var stubbedCanCreateViewModelResult: Bool! = false
    func canCreateViewModel(fromModel model: Any) -> Bool {
        invokedCanCreateViewModel = true
        invokedCanCreateViewModelCount += 1
        invokedCanCreateViewModelParameters = (model, ())
        invokedCanCreateViewModelParametersList.append((model, ()))
        return stubbedCanCreateViewModelResult
    }
    var invokedCreateViewModel = false
    var invokedCreateViewModelCount = 0
    var invokedCreateViewModelParameters: (model: ModelT, Void)?
    var invokedCreateViewModelParametersList = [(model: ModelT, Void)]()
    var stubbedCreateViewModelResult: ViewModelT!
    func createViewModel(_ model: ModelT) -> ViewModelT {
        invokedCreateViewModel = true
        invokedCreateViewModelCount += 1
        invokedCreateViewModelParameters = (model, ())
        invokedCreateViewModelParametersList.append((model, ()))
        return stubbedCreateViewModelResult
    }
}
