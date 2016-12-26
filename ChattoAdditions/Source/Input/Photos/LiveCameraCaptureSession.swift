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
import Photos

protocol LiveCameraCaptureSessionProtocol {
    weak var delegate: LiveCameraCaptureSessionDelegate? { get set }
    var captureLayer: AVCaptureVideoPreviewLayer? { get }
    var isInitialized: Bool { get }
    var isCapturing: Bool { get }
    func startCapturing(_ completion: @escaping () -> Void)
    func stopCapturing(_ completion: @escaping () -> Void)
    func takePhoto()
    func changeCamera()
}

protocol LiveCameraCaptureSessionDelegate: class {
    func liveCameraCaptureSessionPhotoToken(_ image: Data)
}

class LiveCameraCaptureSession: LiveCameraCaptureSessionProtocol {

    var isInitialized: Bool = false
    let stillImageOutput = AVCaptureStillImageOutput()

    var isCapturing: Bool {
        return self.isInitialized && self.captureSession?.isRunning ?? false
    }

    weak var delegate: LiveCameraCaptureSessionDelegate?

    deinit {
        var layer = self.captureLayer
        layer?.removeFromSuperlayer()
        var session: AVCaptureSession? = self.isInitialized ? self.captureSession : nil
//        session.
        DispatchQueue.global(qos: .default).async {
            // Analogously to AVCaptureSession creation, dealloc can take very long, so let's do it out of the main thread
            if layer != nil { layer = nil }
            if session != nil { session = nil }
        }
    }

    func startCapturing(_ completion: @escaping () -> Void) {
        let operation = BlockOperation()
        operation.addExecutionBlock { [weak operation, weak self] in
            guard let sSelf = self, let strongOperation = operation, !strongOperation.isCancelled else { return }
            sSelf.addInputDevicesIfNeeded()
            sSelf.captureSession?.startRunning()
            DispatchQueue.main.async(execute: completion)
        }
        self.queue.cancelAllOperations()
        self.queue.addOperation(operation)
    }

    func stopCapturing(_ completion: @escaping () -> Void) {
        let operation = BlockOperation()
        operation.addExecutionBlock { [weak operation, weak self] in
            guard let sSelf = self, let strongOperation = operation, !strongOperation.isCancelled else { return }
            sSelf.captureSession?.stopRunning()
            sSelf.removeInputDevices()
            DispatchQueue.main.async(execute: completion)
        }
        self.queue.cancelAllOperations()
        self.queue.addOperation(operation)
    }

    private (set) var captureLayer: AVCaptureVideoPreviewLayer?

    private lazy var queue: OperationQueue = {
        let queue = OperationQueue()
        queue.qualityOfService = .userInitiated
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    private lazy var captureSession: AVCaptureSession? = {
        assert(!Thread.isMainThread, "This can be very slow, make sure it happens in a background thread")
        self.isInitialized = true

        #if !(arch(i386) || arch(x86_64))
            let session = AVCaptureSession()
            self.captureLayer = AVCaptureVideoPreviewLayer(session: session)
            self.captureLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill

            self.stillImageOutput.outputSettings = [AVVideoCodecKey:AVVideoCodecJPEG]
            if session.canAddOutput(self.stillImageOutput) {
                session.addOutput(self.stillImageOutput)
            }
            
            return session
        #else
            return nil
        #endif
    }()

    private func addInputDevicesIfNeeded() {
        assert(!Thread.isMainThread, "This can be very slow, make sure it happens in a background thread")
        if self.captureSession?.inputs?.count == 0 {
            let device = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
            do {
                let input = try AVCaptureDeviceInput(device: device)
                self.captureSession?.addInput(input)
            } catch {

            }
        }
    }

    private func removeInputDevices() {
        assert(!Thread.isMainThread, "This can be very slow, make sure it happens in a background thread")
        self.captureSession?.inputs?.forEach { (input) in
            self.captureSession?.removeInput(input as! AVCaptureInput)
        }
    }
    
    func takePhoto() {
        if let videoConnection = self.stillImageOutput.connection(withMediaType: AVMediaTypeVideo) {
            self.stillImageOutput.captureStillImageAsynchronously(from: videoConnection) {
                (imageDataSampleBuffer, error) -> Void in
                let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer)
                self.delegate?.liveCameraCaptureSessionPhotoToken(imageData!)
            }
        }
    }
    
    func changeCamera() {
//        if self.captureSession?.inputs?.count != 0 {
//            let device:AVCaptureDevice = self.captureSession?.inputs?.first as! AVCaptureDevice
//            
//            if device.position == .back {
//                self.captureSession?.removeInput(device)
////                device = AVCaptureDevice.ini
//            } else {
//                
//            }
//        }
//        
        
        
        self.captureSession?.beginConfiguration()
        let currentCameraInput:AVCaptureInput = self.captureSession?.inputs.first as! AVCaptureInput
        self.captureSession?.removeInput(currentCameraInput)
        
        //Get new input
        var newCamera:AVCaptureDevice? = nil
        
        if (currentCameraInput as! AVCaptureDeviceInput).device.position == .back {
            newCamera = self.cameraWithPosition(.front)
        } else {
            newCamera = self.cameraWithPosition(.back)
        }
        
        //Add input to session
        let newVideoInput:AVCaptureDeviceInput? = try! AVCaptureDeviceInput(device: newCamera)
        
        if newVideoInput != nil {
            self.captureSession?.addInput(newVideoInput)
        }
        
        //Commit all the configuration changes at once
        self.captureSession?.commitConfiguration()
    }
    
    func cameraWithPosition(_ position: AVCaptureDevicePosition) -> AVCaptureDevice? {
        let devices:Array = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo)
        
        for device in devices {
            if (device as! AVCaptureDevice).position == position {
                return device as! AVCaptureDevice
            }
        }
        
        return nil
        
        
//        guard let device = AVCaptureDevice.devices().filter({ ($0 as AnyObject).position == .front })
//            .first as? AVCaptureDevice else {
//                fatalError("No front facing camera found")
//        }
    }
}
