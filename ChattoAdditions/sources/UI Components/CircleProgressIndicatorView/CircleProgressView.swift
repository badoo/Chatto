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

final class CircleProgressView: UIView {

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }

    // MARK: - Public

    override func layoutSubviews() {
        super.layoutSubviews()
        self.backgroundLayer.frame = self.bounds
        self.progressLayer.frame = self.bounds
    }

    func prepareForLoading() {
        self.isPreparingForLoading = true
        self.updateBackgroundLayer()
        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotationAnimation.toValue = NSNumber(value: 2*Float.pi)
        rotationAnimation.duration = 1
        rotationAnimation.isCumulative = true
        rotationAnimation.repeatCount = .greatestFiniteMagnitude
        self.backgroundLayer.add(rotationAnimation, forKey: "rotationAnimation")
    }

    func finishPrepareForLoading() {
        guard self.isPreparingForLoading else { return }
        self.backgroundLayer.removeAllAnimations()
        self.isPreparingForLoading = false
        self.updateBackgroundLayer()
    }

    func setProgress(_ progress: CGFloat) {
        guard 0 <= progress, progress <= 1 else { return }
        self.progress = progress
        self.progressLayer.isHidden = progress >= 1
        self.updateProgressLayer()
    }

    func setLineColor(_ color: UIColor) {
        self.lineColor = color
        self.backgroundLayer.strokeColor = self.lineColor?.cgColor
        self.progressLayer.strokeColor = self.lineColor?.cgColor
        self.updateBackgroundLayer()
    }

    func setLineWidth(_ width: CGFloat) {
        self.lineWidth = width
        self.backgroundLayer.lineWidth = self.lineWidth
        self.progressLayer.lineWidth = self.lineWidth * 2
        self.updateBackgroundLayer()
    }

    // MARK: - Private

    private var backgroundLayer: CAShapeLayer!
    private var progressLayer: CAShapeLayer!

    private var lineColor: UIColor?
    private var lineWidth: CGFloat = 0

    private var isPreparingForLoading: Bool = false
    private var progress: CGFloat = 0

    private func commonInit() {
        self.addBackgroundLayer()
        self.addProgressLayer()
        self.updateBackgroundLayer()
    }

    private func addBackgroundLayer() {
        let backgroundLayer = CAShapeLayer()
        backgroundLayer.strokeColor = self.lineColor?.cgColor
        backgroundLayer.fillColor = self.backgroundColor?.cgColor
        backgroundLayer.lineCap = .round
        backgroundLayer.lineWidth = self.lineWidth
        self.layer.addSublayer(backgroundLayer)
        self.backgroundLayer = backgroundLayer
    }

    private func addProgressLayer() {
        let progressLayer = CAShapeLayer()
        progressLayer.strokeColor = self.lineColor?.cgColor
        progressLayer.fillColor = nil
        progressLayer.lineCap = .square
        progressLayer.lineWidth = self.lineWidth * 2.2
        self.layer.addSublayer(progressLayer)
        self.progressLayer = progressLayer
    }

    private func updateBackgroundLayer() {
        let spinningGapInCircle: CGFloat = self.isPreparingForLoading ? 1.8: 2.0
        let radius = self.bounds.width * 0.5 - self.lineWidth
        let center = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
        let backgroundCirclePath = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: -.pi/2,
            endAngle: (spinningGapInCircle * .pi - .pi/2),
            clockwise: true
        )
        backgroundCirclePath.lineWidth = self.lineWidth
        backgroundCirclePath.lineCapStyle = .round
        self.backgroundLayer.path = backgroundCirclePath.cgPath
    }

    private func updateProgressLayer() {
        let radius = (self.bounds.width - self.lineWidth * 4) * 0.5
        let center = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
        let progressCirclePath = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: -.pi/2,
            endAngle: self.progress * 2*CGFloat.pi - .pi/2,
            clockwise: true
        )
        progressCirclePath.lineCapStyle = .butt
        progressCirclePath.lineWidth = self.lineWidth
        self.progressLayer.path = progressCirclePath.cgPath
    }
}
