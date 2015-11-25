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
import CoreGraphics

private let scale = UIScreen.mainScreen().scale

public enum HorizontalAlignment {
    case Left
    case Center
    case Right
}

public enum VerticalAlignment {
    case Top
    case Center
    case Bottom
}

public extension CGSize {
    func bma_insetBy(dx dx: CGFloat, dy: CGFloat) -> CGSize {
        return CGSize(width: self.width - dx, height: self.height - dy)
    }

    func bma_outsetBy(dx dx: CGFloat, dy: CGFloat) -> CGSize {
        return self.bma_insetBy(dx: -dx, dy: -dy)
    }
}

public extension CGSize {
    func bma_round() -> CGSize {
        return CGSize(width: ceil(self.width * scale) * (1.0 / scale), height: ceil(self.height * scale) * (1.0 / scale) )
    }

    func bma_rect(inContainer containerRect: CGRect, xAlignament: HorizontalAlignment, yAlignment: VerticalAlignment, dx: CGFloat, dy: CGFloat) -> CGRect {
        var originX, originY: CGFloat

        // Horizontal alignment
        switch xAlignament {
        case .Left:
            originX = 0
        case .Center:
            originX = containerRect.midX - self.width / 2.0
        case .Right:
            originX = containerRect.maxY - self.width
        }

        // Vertical alignment
        switch yAlignment {
        case .Top:
            originY = 0
        case .Center:
            originY = containerRect.midY - self.height / 2.0
        case .Bottom:
            originY = containerRect.maxY - self.height
        }

        return CGRect(origin: CGPoint(x: originX, y: originY).bma_offsetBy(dx: dx, dy: dy), size: self)
    }
}

public extension CGRect {
    var bma_bounds: CGRect {
        return CGRect(origin: CGPointZero, size: self.size)
    }

    var bma_center: CGPoint {
        return CGPoint(x: self.midX, y: self.midY)
    }

    var bma_maxY: CGFloat {
        get {
            return self.maxY
        } set {
            let delta = newValue - self.maxY
            self.origin = self.origin.bma_offsetBy(dx: 0, dy: delta)
        }
    }

    func bma_round() -> CGRect {
        let origin = CGPoint(x: ceil(self.origin.x * scale) * (1.0 / scale), y: ceil(self.origin.y * scale) * (1.0 / scale))
        return CGRect(origin: origin, size: self.size.bma_round())
    }
}


public extension CGPoint {
    func bma_offsetBy(dx dx: CGFloat, dy: CGFloat) -> CGPoint {
        return CGPoint(x: self.x + dx, y: self.y + dy)
    }
}

public extension UIView {
    var bma_rect: CGRect {
        get {
            return CGRect(origin: CGPoint(x: self.center.x - self.bounds.width / 2, y: self.center.y - self.bounds.height), size: self.bounds.size)
        }
        set {
            let roundedRect = newValue.bma_round()
            self.bounds = roundedRect.bma_bounds
            self.center = roundedRect.bma_center
        }
    }
}

public extension UIEdgeInsets {

    public var bma_horziontalInset: CGFloat {
        return self.left + self.right
    }

    public var bma_verticalInset: CGFloat {
        return self.top + self.bottom
    }

    public var bma_hashValue: Int {
        return self.top.hashValue ^ self.left.hashValue ^ self.bottom.hashValue ^ self.right.hashValue
    }

}


public extension UIImage {

    public func bma_tintWithColor(color: UIColor) -> UIImage {
        let rect = CGRect(origin: CGPointZero, size: self.size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, self.scale)
        let context = UIGraphicsGetCurrentContext()
        color.setFill()
        CGContextFillRect(context, rect)
        self.drawInRect(rect, blendMode: .DestinationIn, alpha: 1)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image.resizableImageWithCapInsets(self.capInsets)
    }

    public func bma_blendWithColor(color: UIColor) -> UIImage {
        let rect = CGRect(origin: CGPointZero, size: self.size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, UIScreen.mainScreen().scale)
        let context = UIGraphicsGetCurrentContext()
        CGContextTranslateCTM(context, 0, rect.height)
        CGContextScaleCTM(context, 1.0, -1.0)
        CGContextSetBlendMode(context, .Normal)
        CGContextDrawImage(context, rect, self.CGImage)
        CGContextClipToMask(context, rect, self.CGImage)
        color.setFill()
        CGContextAddRect(context, rect);
        CGContextDrawPath(context, .Fill);
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image.resizableImageWithCapInsets(self.capInsets)
    }

    public static func bma_imageWithColor(color: UIColor, size: CGSize) -> UIImage {
        let rect = CGRectMake(0, 0, size.width, size.height)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        color.setFill()
        UIRectFill(rect)
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

public extension UIColor {
    static func bma_color(rgb rgb: Int) -> UIColor {
        return UIColor(red: CGFloat((rgb & 0xFF0000) >> 16) / 255.0, green: CGFloat((rgb & 0xFF00) >> 8) / 255.0, blue: CGFloat((rgb & 0xFF)) / 255.0, alpha: 1.0)
    }

    public func bma_blendWithColor(color: UIColor) -> UIColor {
        var r1: CGFloat = 0, r2: CGFloat = 0
        var g1: CGFloat = 0, g2: CGFloat = 0
        var b1: CGFloat = 0, b2: CGFloat = 0
        var a1: CGFloat = 0, a2: CGFloat = 0
        self.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        color.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        let alpha = a2, beta = 1 - alpha
        let r = r1 * beta + r2 * alpha
        let g = g1 * beta + g2 * alpha
        let b = b1 * beta + b2 * alpha
        return UIColor(red: r, green: g, blue: b, alpha: 1)
    }
}
