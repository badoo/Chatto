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

public class PhotosChatInputItem: ChatInputItemProtocol {
    typealias Class = PhotosChatInputItem

    public var photoInputHandler: ((UIImage) -> Void)?
    public var cameraPermissionHandler: (() -> Void)?
    public var photosPermissionHandler: (() -> Void)?
    public weak var presentingController: UIViewController?

    let buttonAppearance: TabInputButtonAppearance
    let inputViewAppearance: PhotosInputViewAppearance
    public init(presentingController: UIViewController?,
                tabInputButtonAppearance: TabInputButtonAppearance = Class.createDefaultButtonAppearance(),
                inputViewAppearance: PhotosInputViewAppearance = Class.createDefaultInputViewAppearance()) {
        self.presentingController = presentingController
        self.buttonAppearance = tabInputButtonAppearance
        self.inputViewAppearance = inputViewAppearance
    }

    public class func createDefaultButtonAppearance() -> TabInputButtonAppearance {
        let images: [UIControlStateWrapper: UIImage] = [
            UIControlStateWrapper(state: .Normal): UIImage(named: "camera-icon-unselected", inBundle: NSBundle(forClass: Class.self), compatibleWithTraitCollection: nil)!,
            UIControlStateWrapper(state: .Selected): UIImage(named: "camera-icon-selected", inBundle: NSBundle(forClass: Class.self), compatibleWithTraitCollection: nil)!,
            UIControlStateWrapper(state: .Highlighted): UIImage(named: "camera-icon-selected", inBundle: NSBundle(forClass: Class.self), compatibleWithTraitCollection: nil)!
        ]
        return TabInputButtonAppearance(images: images, size: nil)
    }

    public class func createDefaultInputViewAppearance() -> PhotosInputViewAppearance {
        let defaultColor = UIColor(red: 24.0/255.0, green: 101.0/255.0, blue: 245.0/255.0, alpha: 1)
        let liveCameraCellAppearence = LiveCameraCellAppearance(backgroundColor: defaultColor)
        return PhotosInputViewAppearance(liveCameraCellAppearence: liveCameraCellAppearence)
    }

    lazy private var internalTabView: UIButton = {
        return TabInputButton.makeInputButton(withAppearance: self.buttonAppearance)
    }()

    lazy var photosInputView: PhotosInputViewProtocol = {
        let photosInputView = PhotosInputView(presentingController: self.presentingController, appearance: self.inputViewAppearance)
        photosInputView.delegate = self
        return photosInputView
    }()

    public var selected = false {
        didSet {
            self.internalTabView.selected = self.selected
        }
    }

    // MARK: - ChatInputItemProtocol

    public var presentationMode: ChatInputItemPresentationMode {
        return .CustomView
    }

    public var showsSendButton: Bool {
        return false
    }

    public var inputView: UIView? {
        return self.photosInputView as? UIView
    }

    public var tabView: UIView {
        return self.internalTabView
    }

    public func handleInput(input: AnyObject) {
        if let image = input as? UIImage {
            self.photoInputHandler?(image)
        }
    }
}

// MARK: - PhotosInputViewDelegate
extension PhotosChatInputItem: PhotosInputViewDelegate {
    func inputView(inputView: PhotosInputViewProtocol, didSelectImage image: UIImage) {
        self.photoInputHandler?(image)
    }

    func inputViewDidRequestCameraPermission(inputView: PhotosInputViewProtocol) {
        self.cameraPermissionHandler?()
    }

    func inputViewDidRequestPhotoLibraryPermission(inputView: PhotosInputViewProtocol) {
        self.photosPermissionHandler?()
    }
}
