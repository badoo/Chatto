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

@available(iOS 11, *)
final class TestableCompoundMessagePresenter: CompoundMessagePresenter<FakeViewModelBuilder, FakeMessageInteractionHandler> {

    init(messageModel: MessageModel, viewModelBuilder: FakeViewModelBuilder) {
        super.init(
            messageModel: messageModel,
            viewModelBuilder: viewModelBuilder,
            interactionHandler: nil,
            contentFactories: [],
            sizingCell: CompoundMessageCollectionViewCell(frame: .zero),
            baseCellStyle: StubMessageCollectionViewCellStyle(),
            compoundCellStyle: StubCompoundBubbleViewStyle(),
            compoundCellDimensions: CompoundBubbleLayoutProvider.Dimensions(spacing: 0, contentInsets: .zero),
            cache: Cache<CompoundBubbleLayoutProvider.Configuration, CompoundBubbleLayoutProvider>(),
            accessibilityIdentifier: nil
        )
        self.resetCounters()
    }

    var invokedUpdateContentCount = 0
    override func updateContent() {
        super.updateContent()
        self.invokedUpdateContentCount += 1
    }

    var invokedUpdateExistingContentPresentersCount: Int { return self.invokedUpdateExistingContentPresentersParametersList.count }
    var invokedUpdateExistingContentPresentersParametersList: [Any] = []

    override func updateExistingContentPresenters(with newMessage: Any) {
        super.updateExistingContentPresenters(with: newMessage)
        self.invokedUpdateExistingContentPresentersParametersList.append(newMessage)
    }

    func resetCounters() {
        self.invokedUpdateContentCount = 0
        self.invokedUpdateExistingContentPresentersParametersList = []
    }
}
