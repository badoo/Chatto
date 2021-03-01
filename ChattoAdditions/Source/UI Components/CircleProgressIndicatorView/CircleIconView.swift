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

public enum CircleIconType {
    case undefined
    case infinity
    case exclamation
    case check
    case arrowDown
    case arrowUp
    case stop
    case text
}

final class CircleIconView: UIView {

    // MARK: - Declarations

    private struct ProgressIconPoints {
        let center: CGPoint
        let top: CGPoint
        let bottom: CGPoint
        let left: CGPoint
        let right: CGPoint

        init(center: CGPoint = .zero,
             top: CGPoint = .zero,
             bottom: CGPoint = .zero,
             left: CGPoint = .zero,
             right: CGPoint = .zero) {
            self.center = center
            self.top = top
            self.bottom = bottom
            self.left = left
            self.right = right
        }
    }

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
        self.iconLayer.frame = self.bounds
    }

    func setType(_ type: CircleIconType) {
        self.type = type
        self.setupVisibility(with: self.type)
        self.setupIconLayer(with: self.type)
        self.setupIconView(with: self.type)
    }

    func setTitle(_ title: NSAttributedString?) {
        self.setType(.text)
        self.titleLabel.attributedText = title
    }

    func setLineColor(_ color: UIColor) {
        self.lineColor = color
        self.iconLayer.strokeColor = self.lineColor?.cgColor
        self.titleLabel.textColor = self.lineColor
    }

    func setLineWidth(_ width: CGFloat) {
        self.lineWidth = width
        self.iconLayer.lineWidth = self.lineWidth
    }

    // MARK: - Private

    private var type: CircleIconType = .undefined

    private var lineColor: UIColor?
    private var lineWidth: CGFloat = 0

    private var iconLayer: CAShapeLayer!
    private var iconView: UIImageView!
    private var titleLabel: UILabel!

    private var iconPoints = ProgressIconPoints()

    private func commonInit() {
        self.initIconLayer()
        self.initIconView()
        self.initTitleLabel()
    }

    private func initIconLayer() {
        let iconLayer = CAShapeLayer()
        iconLayer.strokeColor = self.lineColor?.cgColor
        iconLayer.fillColor = nil
        iconLayer.lineCap = .round
        iconLayer.lineWidth = self.lineWidth
        iconLayer.fillRule = .nonZero
        self.layer.addSublayer(iconLayer)
        self.iconLayer = iconLayer
    }

    private func initIconView() {
        let iconView = UIImageView(frame: self.bounds)
        iconView.contentMode = .center
        self.addSubview(iconView)
        self.iconView = iconView
    }

    private func initTitleLabel() {
        let titleLabel = UILabel(frame: self.bounds)
        titleLabel.textAlignment = .center
        self.addSubview(titleLabel)
        self.titleLabel = titleLabel
    }

    private func setupVisibility(with type: CircleIconType) {
        self.titleLabel.isHidden = true
        self.iconLayer.isHidden = true
        self.iconView.isHidden = true

        switch type {
        case .infinity, .exclamation, .check:
            self.iconView.isHidden = false

        case .arrowDown, .arrowUp, .stop:
            self.iconLayer.isHidden = false

        case .text:
            self.titleLabel.isHidden = false

        default:
            break
        }
    }

    private func setupIconLayer(with type: CircleIconType) {
        self.setupIconPoints(with: type)

        switch type {
        case .arrowUp:
            self.drawArrow(pointingTo: self.iconPoints.top)

        case .arrowDown:
            self.drawArrow(pointingTo: self.iconPoints.bottom)

        case .stop:
            self.drawStop()

        default:
            self.iconLayer.path = nil
            self.iconLayer.fillColor = nil
        }
    }

    private func setupIconView(with type: CircleIconType) {
        guard let imageName: String = {
            switch type {

            case .infinity:
                return "infinity_icon_norm"

            case .exclamation:
                return "warning_icon_norm"

            case .check:
                return "tick_viewed_icon_norm"

            default:
                return nil
            }
            }() else { return }
        self.iconView.image = UIImage(named: imageName, in: Bundle(for: CircleIconView.self), compatibleWith: nil)
    }

    private func setupIconPoints(with type: CircleIconType) {
        let center = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
        let outterCircleRadius = self.bounds.width - 2 * self.lineWidth

        let yOffset = outterCircleRadius - self.verticalMargin
        let xOffset = outterCircleRadius - self.horizontalMargin

        let leftPoint: CGPoint
        let rightPoint: CGPoint
        switch type {

        case .arrowDown, .arrowUp:
            leftPoint = CGPoint(x: center.x - xOffset, y: center.y)
            rightPoint = CGPoint(x: center.x + xOffset, y: center.y)

        default:
            leftPoint = .zero
            rightPoint = .zero
        }

        self.iconPoints = ProgressIconPoints(
            center: center,
            top: CGPoint(x: center.x, y: center.y - yOffset),
            bottom: CGPoint(x: center.x, y: center.y + yOffset),
            left: leftPoint,
            right: rightPoint
        )
    }

    private func drawArrow(pointingTo point: CGPoint) {
        let path = UIBezierPath()
        path.move(to: self.iconPoints.left)
        path.addLine(to: point)
        path.close()

        path.move(to: point)
        path.addLine(to: self.iconPoints.right)
        path.close()

        path.move(to: self.iconPoints.top)
        path.addLine(to: self.iconPoints.center)
        path.addLine(to: self.iconPoints.bottom)
        path.close()

        self.iconLayer.lineWidth = self.lineWidth
        self.iconLayer.lineCap = .round
        self.iconLayer.path = path.cgPath
        self.iconLayer.strokeColor = self.lineColor?.cgColor
        self.iconLayer.fillColor = nil
    }

    private func drawStop() {
        let radius = self.bounds.midX
        let translation = radius * (1 - self.horizontalMarginCoef)
        let horizontalMargin = self.horizontalMargin

        let stopPath = UIBezierPath()
        stopPath.move(to: .zero)
        stopPath.addLine(to: CGPoint(x: horizontalMargin, y: 0))
        stopPath.addLine(to: CGPoint(x: horizontalMargin, y: horizontalMargin))
        stopPath.addLine(to: CGPoint(x: 0, y: horizontalMargin))
        stopPath.close()
        stopPath.apply(CGAffineTransform(translationX: translation, y: translation))

        self.iconLayer.path = stopPath.cgPath
        self.iconLayer.strokeColor = self.lineColor?.cgColor
        self.iconLayer.fillColor = self.lineColor?.cgColor
    }

    // MARK: - Default Settings

    private var horizontalMargin: CGFloat {
        return self.bounds.width * 0.29
    }

    private var verticalMargin: CGFloat {
        return self.bounds.width * 0.28
    }

    private let horizontalMarginCoef: CGFloat = 0.28
}
