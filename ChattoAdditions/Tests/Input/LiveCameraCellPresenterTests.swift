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
import Photos
@testable import ChattoAdditions

class LiveCameraCellPresenterTests: XCTestCase {

    var presenter: LiveCameraCellPresenter!
    var cell: LiveCameraCell!

    override func setUp() {
        super.setUp()
        self.presenter = LiveCameraCellPresenter()
        self.cell = LiveCameraCell()
    }

    override func tearDown() {
        self.presenter = nil
        self.cell = nil
        super.tearDown()
    }

    // MARK: - Capture Session
    func testThat_WhenAuthorizationStatusIsNotDetermined_CaptureDoesntStart() {
        let mockCaptureSession = MockLiveCameraCaptureSession()
        self.presenter.captureSession = mockCaptureSession
        self.presenter.cameraAuthorizationStatus = .NotDetermined

        self.presenter.cellWillBeShown(self.cell)

        XCTAssertFalse(mockCaptureSession.isCapturing)
    }

    func testThat_WhenAuthorizationStatusIsRestricted_CaptureDoesntStart() {
        let mockCaptureSession = MockLiveCameraCaptureSession()
        self.presenter.captureSession = mockCaptureSession
        self.presenter.cameraAuthorizationStatus = .Restricted

        self.presenter.cellWillBeShown(self.cell)

        XCTAssertFalse(mockCaptureSession.isCapturing)
    }

    func testThat_WhenAuthorizationStatusIsDenied_CaptureDoesntStart() {
        let mockCaptureSession = MockLiveCameraCaptureSession()
        self.presenter.captureSession = mockCaptureSession
        self.presenter.cameraAuthorizationStatus = .Denied

        self.presenter.cellWillBeShown(self.cell)

        XCTAssertFalse(mockCaptureSession.isCapturing)
    }

    func testThat_WhenAuthorizationStatusIsAuthorized_CaptureStarts() {
        let mockCaptureSession = MockLiveCameraCaptureSession()
        self.presenter.captureSession = mockCaptureSession
        self.presenter.cameraAuthorizationStatus = .Authorized

        self.presenter.cellWillBeShown(self.cell)

        XCTAssertTrue(mockCaptureSession.isCapturing)
    }

    func testThat_GivenCaptureSessionIsCapturing_WhenStopCapturingCalled_ThenCaptureSessionStopsCapturing() {
        let mockCaptureSession = MockLiveCameraCaptureSession()
        mockCaptureSession.isCapturing = true
        self.presenter.captureSession = mockCaptureSession
        self.presenter.cameraAuthorizationStatus = .Authorized

        self.presenter.cellWillBeShown(self.cell)
        self.presenter.cellWasHidden(self.cell)

        XCTAssertFalse(mockCaptureSession.isCapturing)
    }

    // MARK: - App Notifications
    func testThat_GivenCaptureSessionIsCapturingAndAppDidLostFocus_ThenCaptureIsStopped() {
        let mockCaptureSession = MockLiveCameraCaptureSession()
        mockCaptureSession.isCapturing = true
        self.presenter.captureSession = mockCaptureSession

        self.presenter.cameraAuthorizationStatus = .Authorized
        self.presenter.cellWillBeShown(self.cell)

        self.presenter.notificationCenter.postNotificationName(UIApplicationWillResignActiveNotification, object: nil)

        XCTAssertFalse(mockCaptureSession.isCapturing)
    }

    func testThat_GivenCaptureSessionIsCapturingAndAppDidLostFocus_WhenAppReceivesFocus_ThenCaptureIsRestored() {
        let mockCaptureSession = MockLiveCameraCaptureSession()
        mockCaptureSession.isCapturing = true
        self.presenter.captureSession = mockCaptureSession

        self.presenter.cameraAuthorizationStatus = .Authorized
        self.presenter.cellWillBeShown(self.cell)

        self.presenter.notificationCenter.postNotificationName(UIApplicationWillResignActiveNotification, object: nil)
        self.presenter.notificationCenter.postNotificationName(UIApplicationDidBecomeActiveNotification, object: nil)

        XCTAssertTrue(mockCaptureSession.isCapturing)
    }

    func testThat_GivenCaptureSessionIsNotCapturingAndAppDidLostFocus_WhenAppReceivesFocus_ThenCaptureIsNotRestored() {
        let mockCaptureSession = MockLiveCameraCaptureSession()
        mockCaptureSession.isCapturing = false
        self.presenter.captureSession = mockCaptureSession

        self.presenter.cameraAuthorizationStatus = .Authorized
        self.presenter.cellWillBeShown(self.cell)
        self.presenter.cellWasHidden(self.cell)

        self.presenter.notificationCenter.postNotificationName(UIApplicationWillResignActiveNotification, object: nil)
        self.presenter.notificationCenter.postNotificationName(UIApplicationDidBecomeActiveNotification, object: nil)

        XCTAssertFalse(mockCaptureSession.isCapturing)
    }

    func testThat_WhenCellIsRemovedFromWindow_ThenCaptureIsStopped() {
        let mockCaptureSession = MockLiveCameraCaptureSession()
        self.presenter.captureSession = mockCaptureSession
        self.presenter.cameraAuthorizationStatus = .Authorized

        self.presenter.cellWillBeShown(self.cell)

        self.cell.didMoveToWindow()
        XCTAssertFalse(mockCaptureSession.isCapturing)
    }

    func testThat_WhenReusedCellIsRemovedFromWindow_ThenCaptureIsNotStopped() {
        let mockCaptureSession = MockLiveCameraCaptureSession()
        self.presenter.captureSession = mockCaptureSession
        self.presenter.cameraAuthorizationStatus = .Authorized

        let firstCell = LiveCameraCell()
        self.presenter.cellWillBeShown(firstCell)
        self.presenter.cellWillBeShown(self.cell)

        firstCell.didMoveToWindow()
        XCTAssertTrue(mockCaptureSession.isCapturing)
    }

    func testThat_WhenCellIsReaddedToWindow_ThenCaputreIsRestarted() {
        let mockCaptureSession = MockLiveCameraCaptureSession()
        self.presenter.captureSession = mockCaptureSession
        self.presenter.cameraAuthorizationStatus = .Authorized

        self.presenter.cellWillBeShown(self.cell)
        self.cell.didMoveToWindow()

        let window = UIWindow()
        window.addSubview(self.cell)

        XCTAssertTrue(mockCaptureSession.isCapturing)
    }

    func testThat_WhenReusedCellIsReaddedToWindow_ThenCaptureIsNotRestarted() {
        let mockCaptureSession = MockLiveCameraCaptureSession()
        self.presenter.captureSession = mockCaptureSession
        self.presenter.cameraAuthorizationStatus = .Authorized

        let firstCell = LiveCameraCell()
        self.presenter.cellWillBeShown(firstCell)
        self.presenter.cellWillBeShown(self.cell)
        self.cell.didMoveToWindow()

        firstCell.willMoveToWindow(UIWindow())
        XCTAssertFalse(mockCaptureSession.isCapturing)
    }
}

private class MockLiveCameraCaptureSession: LiveCameraCaptureSessionProtocol {
    var captureLayer: AVCaptureVideoPreviewLayer? {
        if self.isInitialized {
            return AVCaptureVideoPreviewLayer()
        }
        return nil
    }

    var isInitialized: Bool = false
    var isCapturing: Bool = false

    func startCapturing(completion: () -> Void) {
        guard !self.isCapturing else { return }

        self.isInitialized = true
        self.isCapturing = true
        completion()
    }

    func stopCapturing(completion: () -> Void) {
        guard self.isCapturing else { return }

        self.isInitialized = true
        self.isCapturing = false
        completion()
    }
}
