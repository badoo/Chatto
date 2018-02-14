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

class DeviceImagePickerBox : NSObject, ImagePickerBox, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    let controller: UIViewController
    private let context: ImagePickerContext

    init(_ context: ImagePickerContext) {
        let pickerController = UIImagePickerController()
        self.controller = pickerController
        self.context = context
        super.init()
        pickerController.delegate = self
        pickerController.sourceType = .camera
    }

    @objc
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String: AnyObject]?) {
        self.context.didFinishPickingImage?(image)
    }

    @objc
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.context.didCancel?()
    }
}

class DeviceImagePicker: ImagePicker {
    func pickerController(_ context: ImagePickerContext) -> ImagePickerBox? {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            return nil
        }
        return DeviceImagePickerBox(context)
    }
}
