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

protocol MediaInputCameraPickerProtocol {
    typealias OnImageTakenBlock = (UIImage?) -> Void
    typealias OnVideoTakenBlock = (URL?) -> Void
    typealias OnCameraPickerDismissedBlock = () -> Void

    func presentCameraPicker(onImageTaken: @escaping OnImageTakenBlock,
                             onVideoTaken: @escaping OnVideoTakenBlock,
                             onCameraPickerDismissed: @escaping OnCameraPickerDismissedBlock)
}

final class MediaInputCameraPicker: MediaInputCameraPickerProtocol, MediaPickerDelegate {
    private let mediaPickerFactory: MediaPickerFactory
    private let presentingControllerProvider: () -> UIViewController?
    private var MediaPicker: MediaPicker?

    private var onImageTaken: OnImageTakenBlock?
    private var onVideoTaken: OnVideoTakenBlock?
    private var onCameraPickerDismissed: OnCameraPickerDismissedBlock?

    init(mediaPickerFactory: MediaPickerFactory,
         presentingControllerProvider: @escaping () -> UIViewController?) {
        self.mediaPickerFactory = mediaPickerFactory
        self.presentingControllerProvider = presentingControllerProvider
    }

    func presentCameraPicker(onImageTaken: @escaping OnImageTakenBlock,
                             onVideoTaken: @escaping OnVideoTakenBlock,
                             onCameraPickerDismissed: @escaping OnCameraPickerDismissedBlock) {
        guard let presentingController = self.presentingControllerProvider(),
            let MediaPicker = self.mediaPickerFactory.makeImagePicker(delegate: self) else {
                onImageTaken(nil)
                onCameraPickerDismissed()
                return
        }
        self.onImageTaken = onImageTaken
        self.onVideoTaken = onVideoTaken
        self.onCameraPickerDismissed = onCameraPickerDismissed
        self.MediaPicker = MediaPicker
        presentingController.present(MediaPicker.controller, animated: true, completion: nil)
    }

    // MARK: - MediaPickerDelegate

    func imagePickerDidFinish(_ picker: MediaPicker, mediaInfo: [UIImagePickerController.InfoKey: Any]) {
        let mediaType = mediaInfo[UIImagePickerController.InfoKey.mediaType] as? String
        if let image = mediaInfo[UIImagePickerController.InfoKey.originalImage] as? UIImage,
            mediaType == InputMediaType.image.UTI {
            self.finishPickingImage(image, fromPicker: picker.controller)
        } else if let videoURL = mediaInfo[UIImagePickerController.InfoKey.mediaURL] as? URL,
            mediaType == InputMediaType.video.UTI {
            self.finishPickingVideo(videoURL, fromPicker: picker.controller)
        } else {
            self.imagePickerDidCancel(picker)
        }
    }

    func imagePickerDidCancel(_ picker: MediaPicker) {
        self.finishPickingImage(nil, fromPicker: picker.controller)
    }

    // MARK: - Private API

    private func finishPickingImage(_ image: UIImage?, fromPicker picker: UIViewController) {
        picker.dismiss(animated: true, completion: self.onCameraPickerDismissed)
        self.onImageTaken?(image)
        self.MediaPicker = nil
    }

    private func finishPickingVideo(_ url: URL?, fromPicker picker: UIViewController) {
        picker.dismiss(animated: true, completion: self.onCameraPickerDismissed)
        self.onVideoTaken?(url)
        self.MediaPicker = nil
    }
}
