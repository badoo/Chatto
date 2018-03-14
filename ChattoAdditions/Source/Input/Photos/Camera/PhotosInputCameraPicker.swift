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

final class PhotosInputCameraPicker: ImagePickerDelegate {
    private weak var presentingController: UIViewController?
    private var imagePicker: ImagePicker?
    private var completionBlocks: (onImageTaken: (UIImage?) -> Void, onCameraPickerDismissed: () -> Void)?

    init(presentingController: UIViewController?) {
        self.presentingController = presentingController
    }

    func presentCameraPicker(onImageTaken: @escaping (UIImage?) -> Void, onCameraPickerDismissed: @escaping () -> Void) {
        guard let presentingController = self.presentingController,
            let imagePicker = ImagePickerStore.factory.makeImagePicker(delegate: self) else {
                onImageTaken(nil)
                onCameraPickerDismissed()
                return
        }
        self.completionBlocks = (onImageTaken: onImageTaken, onCameraPickerDismissed: onCameraPickerDismissed)
        self.imagePicker = imagePicker
        presentingController.present(imagePicker.controller, animated: true, completion: nil)
    }

    func imagePickerDidFinish(_ picker: ImagePicker, mediaInfo: [String: Any]) {
        let image = mediaInfo[UIImagePickerControllerOriginalImage] as? UIImage
        self.finishPickingImage(image, fromPicker: picker.controller)
    }

    func imagePickerDidCancel(_ picker: ImagePicker) {
        self.finishPickingImage(nil, fromPicker: picker.controller)
    }

    private func finishPickingImage(_ image: UIImage?, fromPicker picker: UIViewController) {
        picker.dismiss(animated: true, completion: self.completionBlocks?.onCameraPickerDismissed)
        self.completionBlocks?.onImageTaken(image)
        self.completionBlocks = nil
        self.imagePicker = nil
    }
}
