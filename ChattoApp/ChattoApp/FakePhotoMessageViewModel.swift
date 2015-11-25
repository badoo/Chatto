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
import ChattoAdditions

class FakePhotoMessageViewModel: PhotoMessageViewModel {

    let fakeImage: UIImage
    override init(photoMessage: PhotoMessageModelProtocol, messageViewModel: MessageViewModelProtocol) {
        self.fakeImage = photoMessage.image
        super.init(photoMessage: photoMessage, messageViewModel: messageViewModel)
        if photoMessage.isIncoming {
            self.image.value = nil
        }
    }

    override func willBeShown() {
        self.fakeProgress()
    }

    func fakeProgress() {
        if [TransferStatus.Success, TransferStatus.Failed].contains(self.transferStatus.value) {
            return
        }
        if self.transferProgress.value >= 1.0 {
            if arc4random_uniform(100) % 2 == 0 {
                self.transferStatus.value = .Success
                self.image.value = self.fakeImage
            } else {
                self.transferStatus.value = .Failed
            }

            return
        }
        self.transferStatus.value = .Transfering
        let delaySeconds: Double = Double(arc4random_uniform(600)) / 1000.0
        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(delaySeconds * Double(NSEC_PER_SEC)))
        dispatch_after(delayTime, dispatch_get_main_queue()) {
            let deltaProgress = Double(arc4random_uniform(15)) / 100.0
            self.transferProgress.value = min(self.transferProgress.value + deltaProgress, 1)
            self.fakeProgress()
        }
    }
}

public class FakePhotoMessageViewModelBuilder: ViewModelBuilderProtocol {

    let messageViewModelBuilder = MessageViewModelDefaultBuilder()

    public func createViewModel(model: PhotoMessageModel) -> PhotoMessageViewModel {
        let messageViewModel = self.messageViewModelBuilder.createMessageViewModel(model)
        let photoMessageViewModel = FakePhotoMessageViewModel(photoMessage: model, messageViewModel: messageViewModel)
        return photoMessageViewModel
    }
}
