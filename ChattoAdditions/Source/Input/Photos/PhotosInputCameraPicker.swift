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
import MobileCoreServices

class PhotosInputCameraPicker: NSObject {
    weak var presentingController: UIViewController?
    init(presentingController: UIViewController?) {
        self.presentingController = presentingController
    }

    private var completionBlocks: (onImageTaken: ((URL?) -> Void)?, onCameraPickerDismissed: (() -> Void)?)?

    func presentCameraPicker(onImageTaken: @escaping (URL?) -> Void, onCameraPickerDismissed: @escaping () -> Void) {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            onImageTaken(nil)
            onCameraPickerDismissed()
            return
        }

        guard let presentingController = self.presentingController else {
            onImageTaken(nil)
            onCameraPickerDismissed()

            return
        }

        self.completionBlocks = (onImageTaken: onImageTaken, onCameraPickerDismissed: onCameraPickerDismissed)
        let controller = UIImagePickerController()
        controller.delegate = self
        controller.sourceType = .camera
        if let mediaTypes = UIImagePickerController.availableMediaTypes(for: .camera) {
            controller.mediaTypes = mediaTypes
        }
        presentingController.present(controller, animated: true, completion:nil)
    }

    fileprivate func finishPickingImage(_ image: URL?, fromPicker picker: UIImagePickerController) {
        let (onImageTaken, onCameraPickerDismissed) = self.completionBlocks ?? (nil, nil)
        picker.dismiss(animated: true, completion: onCameraPickerDismissed)
        onImageTaken?(image)
    }
}

extension PhotosInputCameraPicker: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .allDomainsMask, true)[0]
        //guard let info = info else { return }
        if info[UIImagePickerControllerMediaType] as! String == kUTTypeImage as String {
            if let image = info[UIImagePickerControllerOriginalImage] as? UIImage, let data = UIImageJPEGRepresentation(image, 1.0) {
                let outputURL = URL(fileURLWithPath: documentsPath).appendingPathComponent("image\(arc4random()%1000)d").appendingPathExtension("jpg")
                if FileManager.default.fileExists(atPath: outputURL.absoluteString) {
                    try! FileManager.default.removeItem(atPath: outputURL.absoluteString)
                }
                if (try? data.write(to: outputURL, options: .atomic)) != nil {
                    self.finishPickingImage(outputURL, fromPicker: picker)
                } else {
                    self.finishPickingImage(nil, fromPicker: picker)

                }
            }
        } else if info[UIImagePickerControllerMediaType] as! String == kUTTypeMovie as String{
            if let outputURL = info[UIImagePickerControllerMediaURL] as? URL {
                self.finishPickingImage(outputURL, fromPicker: picker)
            }
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.finishPickingImage(nil, fromPicker: picker)
    }
}
