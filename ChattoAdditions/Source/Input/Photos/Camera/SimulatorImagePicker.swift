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

class SimulatorImagePicker : ImagePicker {
    let controller: UIViewController

    init(_ delegate: ImagePickerDelegate) {
        let controller = SimulatorImagePickerController()
        weak var delegate = delegate
        self.controller = controller
        controller.didTakePhotoCallback = {
            delegate?.imagePickerDidFinishPickingImage(UIImage.bma_imageWithColor(.green, size: CGSize(width: 1024, height: 1024)))
        }
        controller.didCancelCallback = {
            delegate?.imagePickerDidCancel()
        }
    }
}

class SimulatorImagePickerController : UIViewController {
    private let buttonTakePhoto = UIButton(type: .system)
    private let buttonCancel = UIButton(type: .system)

    var didTakePhotoCallback: (() -> Void)?
    var didCancelCallback: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white

        self.view.addSubview(self.buttonTakePhoto)
        self.buttonTakePhoto.setTitle("Take Photo", for: .normal)
        self.buttonTakePhoto.addTarget(self, action: #selector(onButtonTakePhoto), for: .touchUpInside)
        self.buttonTakePhoto.accessibilityIdentifier = "btn_camera_overlay_take_photo"
        self.view.addSubview(self.buttonCancel)

        self.buttonCancel.setTitle("Cancel", for: .normal)
        self.buttonCancel.addTarget(self, action: #selector(onButtonCancel), for: .touchUpInside)
        self.buttonCancel.accessibilityIdentifier = "btn camera overlay close"
    }

    @objc
    private func onButtonTakePhoto() {
        self.didTakePhotoCallback?()
    }

    @objc
    private func onButtonCancel() {
        self.didCancelCallback?()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let bounds = self.view.bounds
        let (slice,remainder) = bounds.divided(atDistance: bounds.height/2, from: .minYEdge)
        self.buttonTakePhoto.frame = slice
        self.buttonCancel.frame = remainder
    }
}

class SimulatorImagePickerFactory : ImagePickerFactory {
    func pickerController(_ delegate: ImagePickerDelegate) -> ImagePicker? {
        return SimulatorImagePicker(delegate)
    }
}
