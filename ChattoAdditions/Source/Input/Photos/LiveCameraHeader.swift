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

import AVFoundation
import Foundation
import UIKit

public struct LiveCameraHeaderAppearance {
    public var backgroundColor: UIColor
    public var cameraImageProvider: () -> UIImage?
    public var cameraSelectedImageProvider: () -> UIImage?
    public var cameraLockImageProvider: () -> UIImage?
    public var cameraSwitchImageProvider: () -> UIImage?
    public var cameraSwitchSelectedImageProvider: () -> UIImage?

    public init(backgroundColor: UIColor,
                cameraImage: @autoclosure @escaping () -> UIImage?,
                cameraSelectedImage: @autoclosure @escaping () -> UIImage?,
                cameraLockImage: @autoclosure @escaping () -> UIImage?,
                cameraSwitchImage: @autoclosure @escaping () -> UIImage?,
                cameraSwitchSelectedImage: @autoclosure @escaping () -> UIImage?) {
        self.backgroundColor = backgroundColor
        self.cameraImageProvider = cameraImage
        self.cameraSelectedImageProvider = cameraSelectedImage
        self.cameraLockImageProvider = cameraLockImage
        self.cameraSwitchImageProvider = cameraSwitchImage
        self.cameraSwitchSelectedImageProvider = cameraSwitchSelectedImage
    }

    public static func createDefaultAppearance() -> LiveCameraHeaderAppearance {
        return LiveCameraHeaderAppearance(
            backgroundColor: UIColor(red: 24.0/255.0, green: 101.0/255.0, blue: 245.0/255.0, alpha: 1),
            cameraImage: UIImage(named: "camera-button", in: Bundle(for: LiveCameraHeader.self), compatibleWith: nil),
            cameraSelectedImage: UIImage(named: "camera-button-pressed", in: Bundle(for: LiveCameraHeader.self), compatibleWith: nil),
            cameraLockImage: UIImage(named: "camera-button-pressed", in: Bundle(for: LiveCameraHeader.self), compatibleWith: nil),
            cameraSwitchImage: UIImage(named: "camera-switch", in: Bundle(for: LiveCameraHeader.self), compatibleWith: nil),
            cameraSwitchSelectedImage: UIImage(named: "camera-switch-pressed", in: Bundle(for: LiveCameraHeader.self), compatibleWith: nil)
        )
    }
}

protocol LiveCameraHeaderProtocol {
    weak var delegate: LiveCameraHeaderDelegate? { get set }
}

protocol LiveCameraHeaderDelegate: class {
    func liveCameraHeaderTakePhoto()
    func liveCameraHeaderChangeCamera()
}

class LiveCameraHeader: UICollectionReusableView {

    private var takePhoto: UIButton!
    private var changeCamera: UIButton!
    private var blueBGView: UIView!

    var appearance: LiveCameraHeaderAppearance = LiveCameraHeaderAppearance.createDefaultAppearance() {
        didSet {
            self.blueBGView.backgroundColor = self.appearance.backgroundColor
        }
    }
    
    weak var delegate: LiveCameraHeaderDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }

    private func commonInit() {
        self.configureIcon()
        self.blueBGView.backgroundColor = self.appearance.backgroundColor
    }

    var captureLayer: CALayer? {
        didSet {
            if oldValue !== self.captureLayer {
                oldValue?.removeFromSuperlayer()
                if let captureLayer = self.captureLayer {
                    self.blueBGView.layer.insertSublayer(captureLayer, below: self.takePhoto.layer)
                    let animation = CABasicAnimation.bma_fadeInAnimationWithDuration(0.25)
                    let animationKey = "fadeIn"
                    captureLayer.removeAnimation(forKey: animationKey)
                    captureLayer.add(animation, forKey: animationKey)
                }
                self.setNeedsLayout()
            }
        }
    }

    typealias CellCallback = (_ cell: LiveCameraHeader) -> Void

    var onWasAddedToWindow: CellCallback?
    var onWasRemovedFromWindow: CellCallback?
    override func didMoveToWindow() {
        if let _ = self.window {
            self.onWasAddedToWindow?(self)
        } else {
            self.onWasRemovedFromWindow?(self)
        }
    }

    func updateWithAuthorizationStatus(_ status: AVAuthorizationStatus) {
        self.authorizationStatus = status
        self.updateIcon()
    }

    private var authorizationStatus: AVAuthorizationStatus = .notDetermined

    private func configureIcon() {
        self.blueBGView = UIView()
        self.addSubview(self.blueBGView)

        self.takePhoto = UIButton(type: .custom)
        self.takePhoto.addTarget(self, action: #selector(LiveCameraHeader.takePhotoAction), for: .touchUpInside)
        self.blueBGView.addSubview(self.takePhoto)

        self.changeCamera = UIButton(type: .custom)
        self.changeCamera.addTarget(self, action: #selector(LiveCameraHeader.changeCameraAction), for: .touchUpInside)
        self.blueBGView.addSubview(self.changeCamera)
    }

    private func updateIcon() {
        switch self.authorizationStatus {
        case .notDetermined, .authorized:
            self.takePhoto.setImage(self.appearance.cameraImageProvider(), for: .normal)
            self.takePhoto.setImage(self.appearance.cameraSelectedImageProvider(), for: .selected)
            self.takePhoto.setImage(self.appearance.cameraSelectedImageProvider(), for: .highlighted)

            self.changeCamera.setImage(self.appearance.cameraSwitchImageProvider(), for: .normal)
            self.changeCamera.setImage(self.appearance.cameraSwitchSelectedImageProvider(), for: .selected)
            self.changeCamera.setImage(self.appearance.cameraSwitchSelectedImageProvider(), for: .highlighted)
            self.changeCamera.isHidden = false
        case .restricted, .denied:
            self.takePhoto.setImage(self.appearance.cameraLockImageProvider(), for: .disabled)
            self.changeCamera.isHidden = true
        }
        self.setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.takePhoto.sizeToFit()
        self.takePhoto.center = CGPoint(x: self.bounds.bma_center.x, y: self.bounds.size.height - self.takePhoto.frame.size.height/2.0 - 7)

        self.changeCamera.sizeToFit()
        self.changeCamera.center = CGPoint(x: self.bounds.size.width - self.changeCamera.frame.size.width/2.0 - 7,
                                           y: self.changeCamera.frame.size.height/2.0 + 7)

        self.blueBGView.frame = CGRect(x: 0, y: 0, width: self.frame.size.width - 1, height: self.frame.size.height)
        self.captureLayer?.frame = self.blueBGView.bounds
    }
    
    @objc private func takePhotoAction() {
        self.delegate?.liveCameraHeaderTakePhoto()
    }

    @objc private func changeCameraAction() {
        self.delegate?.liveCameraHeaderChangeCamera()
    }
}
