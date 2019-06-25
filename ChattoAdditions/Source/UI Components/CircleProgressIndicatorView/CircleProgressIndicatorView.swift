//
// The MIT License (MIT)
//
// Copyright (c) 2015-present Badoo Trading Limited.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import UIKit

public final class CircleProgressIndicatorView: UIView {

    // MARK: - Declarations

    public enum ProgressType {
        case undefined
        case icon
        case timer
        case upload
        case download
    }

    public enum ProgressStatus {
        case undefined
        case starting
        case inProgress
        case completed
        case failed
    }

    // MARK: - Initialization

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }

    // MARK: - Public

    public private(set) var progressType: ProgressType = .undefined {
        didSet { self.onProgressTypeDidChange() }
    }

    public var progressStatus: ProgressStatus = .undefined {
        didSet { self.onProgressStatusDidChange() }
    }

    public var progressLineColor: UIColor! {
        didSet {
            self.progressView.setLineColor(self.progressLineColor)
            self.onProgressStatusDidChange()
            self.onProgressTypeDidChange()
        }
    }

    public var progressLineWidth: CGFloat! {
        didSet {
            self.progressView.setLineWidth(self.progressLineWidth)
            self.onProgressStatusDidChange()
            self.onProgressTypeDidChange()
        }
    }

    public var tapHandler: (() -> Void)? {
        didSet {
            if self.tapHandler != nil {
                self.installTapGestureRecognizer()
            } else {
                self.uninstallTapGestureRecognizer()
            }
        }
    }

    public private(set) var progress: CGFloat = 0 {
        didSet {
            guard self.progress != oldValue else { return }
            self.progressView.setProgress(self.progress)
        }
    }

    public func setProgress(_ progress: CGFloat) {
        self.progress = min(progress, 1)
    }

    public func setTimerTitle(_ title: NSAttributedString?) {
        self.progressType = .timer
        self.iconView.setTitle(title)
    }

    public func setTextTitle(_ title: NSAttributedString?) {
        self.progressType = .icon
        self.iconView.setTitle(title)
    }

    public func setIconType(_ type: CircleIconType) {
        self.iconView.setType(type)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        let center = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
        self.progressView.center = center
        self.iconView.center = center
    }

    // MARK: - Private

    private var progressView: CircleProgressView!
    private var iconView: CircleIconView!
    private weak var tapGestureRecognizer: UITapGestureRecognizer?

    private func commonInit() {
        self.progressView = CircleProgressView(frame: self.bounds)
        self.iconView = CircleIconView(frame: self.bounds)

        self.progressLineColor = self.defaultLineColor
        self.progressLineWidth = self.defaultLineWidth(for: self.bounds)

        self.progressView.setLineColor(self.progressLineColor)
        self.progressView.setLineWidth(self.progressLineWidth)
        self.addSubview(self.progressView)

        self.iconView.setLineColor(self.progressLineColor)
        self.iconView.setLineWidth(self.progressLineWidth)
        self.addSubview(self.iconView)
    }

    private func onProgressTypeDidChange() {
        switch self.progressType {
        case .undefined, .icon, .timer:
            self.iconView.setType(.text)

        case .upload:
            self.iconView.setType(.arrowUp)

        case .download:
            self.iconView.setType(.arrowDown)
        }

        switch self.progressStatus {
        case .failed:
            self.iconView.setType(.exclamation)

        case .inProgress:
            if self.tapHandler != nil {
                self.iconView.setType(.stop)
            }

        case .completed:
            self.iconView.setType(.check)

        default:
            break
        }
    }

    private func onProgressStatusDidChange() {
        self.progressView.finishPrepareForLoading()
        self.progressView.setLineColor(self.progressLineColor)

        switch self.progressStatus {
        case .failed:
            self.progressView.setLineColor(.clear)

        case .starting:
            self.uninstallTapGestureRecognizer()
            self.progressView.prepareForLoading()

        case .inProgress:
            guard self.tapHandler != nil else { break }
            self.installTapGestureRecognizer()

        default:
            break
        }
    }

    // MARK: - Default Settings

    private let defaultLineColor = UIColor(red: 0, green: 0.47, blue: 1, alpha: 1)
    private func defaultLineWidth(for bounds: CGRect) -> CGFloat { return fmax(bounds.width * 0.01, 1.02) }

    // MARK: - Tap Handling

    private func installTapGestureRecognizer() {
        guard self.tapGestureRecognizer == nil else { return }
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        self.tapGestureRecognizer = tapGestureRecognizer
        self.addGestureRecognizer(tapGestureRecognizer)
    }

    private func uninstallTapGestureRecognizer() {
        guard let tapGestureRecognizer = self.tapGestureRecognizer else { return }
        self.removeGestureRecognizer(tapGestureRecognizer)
    }

    @objc
    private func handleTap() {
        self.tapHandler?()
        self.tapHandler = nil
    }
}

// MARK: - Instantiation

public extension CircleProgressIndicatorView {

    public convenience init(size: CGSize) {
        self.init(frame: CGRect(x: 0, y: 0, width: size.width, height: size.height))
    }

    public static func `default`() -> CircleProgressIndicatorView {
        return CircleProgressIndicatorView(size: CGSize(width: 28, height: 28))
    }
}
