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

import XCTest
@testable import ChattoAdditions

class PhotosChatInputItemTests: XCTestCase {
    private var inputItem: PhotosChatInputItem!
    override func setUp() {
        super.setUp()
        self.inputItem = PhotosChatInputItem(presentingController: nil)
    }

    func testThat_PresentationModeIsCustomView() {
        XCTAssertEqual(self.inputItem.presentationMode, ChatInputItemPresentationMode.CustomView)
    }

    func testThat_SendButtonDisabledForPhotosInputItem() {
        XCTAssertFalse(self.inputItem.showsSendButton)
    }

    func testThat_GivenItemHasPhotoInputHandler_WhenInputIsImage_ItemHandlesInput() {
        var handled = false
        self.inputItem.photoInputHandler = { image in
            handled = true
        }
        self.inputItem.handleInput(UIImage())
        XCTAssertTrue(handled)
    }

    func testThat_GivenItemHasPhotoInputHandler_WhenInputIsNotImage_ItemDoesntHandleInput() {
        var handled = false
        self.inputItem.photoInputHandler = { image in
            handled = true
        }
        self.inputItem.handleInput(5)
        XCTAssertFalse(handled)
    }

    func testThat_WhenInputViewSelectsImage_ItemPassedImageIntoPhotoHandler() {
        var handledImage: UIImage? = nil
        self.inputItem.photoInputHandler = { image in
            handledImage = image
        }
        let image = UIImage()
        let inputView = MockPhotosInputView()
        self.inputItem.inputView(inputView, didSelectImage: image)

        XCTAssertEqual(handledImage!, image)
    }

    func testThat_GivenItemIsNotSelected_WhenItemIsSelected_ItReloadsInputView() {
        let mockPhotosInputView = MockPhotosInputView()
        self.inputItem.photosInputView = mockPhotosInputView

        self.inputItem.selected = true

        XCTAssertTrue(mockPhotosInputView.reloaded)
    }

    func testThat_GivenItemIsSelected_WhenItemIsSelected_ItDoesntReloadInputView() {
        self.inputItem.selected = true
        let mockPhotosInputView = MockPhotosInputView()
        self.inputItem.photosInputView = mockPhotosInputView

        self.inputItem.selected = true

        XCTAssertFalse(mockPhotosInputView.reloaded)
    }
}

class MockPhotosInputView: PhotosInputViewProtocol {
    var delegate: PhotosInputViewDelegate?
    var presentingController: UIViewController?

    var reloaded: Bool = false
    func reload() {
        self.reloaded = true
    }
}
