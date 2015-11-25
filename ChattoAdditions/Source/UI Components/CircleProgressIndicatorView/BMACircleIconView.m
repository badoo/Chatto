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

#import "BMACircleIconView.h"

struct BMACircleProgressIconPoints {
    CGPoint bma_top;
    CGPoint bma_centre;
    CGPoint bma_bottom;
    CGPoint bma_left;
    CGPoint bma_right;
};

@interface BMACircleIconView ()
@property (nonatomic) BMACircleIconType type;

@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *titleView;

@property (nonatomic, strong) CAShapeLayer *iconLayer;
@property (nonatomic, assign) struct BMACircleProgressIconPoints iconPoints;

@property (nonatomic, assign) CGFloat lineWidth;
@property (nonatomic, strong) UIColor *lineColor;
@end

@implementation BMACircleIconView

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    [self initIconLayer];
    [self initIconView];
    [self initTitleView];
}

- (void)initIconLayer {
    self.iconLayer = [CAShapeLayer layer];
    _iconLayer.strokeColor = _lineColor.CGColor;
    _iconLayer.fillColor = nil;
    _iconLayer.lineCap = kCALineCapRound;
    _iconLayer.lineWidth = _lineWidth;
    _iconLayer.fillRule = kCAFillRuleNonZero;
    [self.layer addSublayer:_iconLayer];
}

- (void)initIconView {
    self.iconView = [[UIImageView alloc] initWithFrame:self.bounds];
    self.iconView.contentMode = UIViewContentModeCenter;
    [self addSubview:self.iconView];
}

- (void)initTitleView {
    self.titleView = [[UILabel alloc] initWithFrame:self.bounds];
    self.titleView.textAlignment = NSTextAlignmentCenter;
    // FIXME
//    self.titleView.font = [BMANewConnectionsUIDevFeature isAvailable] ? [BMAStyleSheet fontForTypeStyle:BMATypeStyleBodySmallNormal] : [UIFont systemFontOfSize:12];
    [self addSubview:self.titleView];
}

#pragma mark - iconLayer

- (void)setupIconLayerWithType:(BMACircleIconType)type {
    [self setupIconPointsWithType:type];
    switch (type) {
        case BMACircleIconTypeArrowUp:
            [self drawArrowPointingTo:self.iconPoints.bma_top];
            break;
        case BMACircleIconTypeArrowDown:
            [self drawArrowPointingTo:self.iconPoints.bma_bottom];
            break;
        case BMACircleIconTypeStop:
            [self drawStop];
            break;
        default:
            _iconLayer.path = nil;
            _iconLayer.fillColor = nil;
            break;
    }
}

- (void)setupIconPointsWithType:(BMACircleIconType)type {
    struct BMACircleProgressIconPoints points = {};
    points.bma_centre = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
    points.bma_bottom = CGPointMake(points.bma_centre.x, points.bma_centre.y + (self.outterCircleRadius - self.verticalMargin));
    points.bma_top = CGPointMake(points.bma_centre.x, points.bma_centre.y - (self.outterCircleRadius - self.verticalMargin));

    switch (type) {
        case BMACircleIconTypeArrowDown:
            points.bma_left = CGPointMake(points.bma_centre.x - (self.outterCircleRadius - self.horizontalMargin), points.bma_centre.y);
            points.bma_right = CGPointMake(points.bma_centre.x + (self.outterCircleRadius - self.horizontalMargin), points.bma_centre.y);
            break;
        case BMACircleIconTypeArrowUp:
            points.bma_left = CGPointMake(points.bma_centre.x - (self.outterCircleRadius - self.horizontalMargin), points.bma_centre.y);
            points.bma_right = CGPointMake(points.bma_centre.x + (self.outterCircleRadius - self.horizontalMargin), points.bma_centre.y);
            break;
    }

    self.iconPoints = points;
}

- (void)drawArrowPointingTo:(CGPoint)point {
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:self.iconPoints.bma_left];
    [path addLineToPoint:point];
    [path closePath];

    [path moveToPoint:point];
    [path addLineToPoint:self.iconPoints.bma_right];
    [path closePath];

    [path moveToPoint:self.iconPoints.bma_top];
    [path addLineToPoint:self.iconPoints.bma_centre];
    [path addLineToPoint:self.iconPoints.bma_bottom];
    [path closePath];

    _iconLayer.lineWidth = _lineWidth;
    _iconLayer.lineCap = kCALineCapRound;
    [_iconLayer setPath:path.CGPath];
    [_iconLayer setStrokeColor:self.lineColor.CGColor];
    [_iconLayer setFillColor:nil];
}

- (void)drawStop {
    CGFloat radius = (self.bounds.size.width) / 2;
    UIBezierPath *stopPath = [UIBezierPath bezierPath];
    [stopPath moveToPoint:CGPointMake(0, 0)];
    [stopPath addLineToPoint:CGPointMake(self.horizontalMargin, 0.0)];
    [stopPath addLineToPoint:CGPointMake(self.horizontalMargin, self.horizontalMargin)];
    [stopPath addLineToPoint:CGPointMake(0.0, self.horizontalMargin)];
    [stopPath closePath];
    [stopPath applyTransform:CGAffineTransformMakeTranslation(radius * (1 - self.horizontalMarginCoef), radius * (1 - self.horizontalMarginCoef))];

    [_iconLayer setPath:stopPath.CGPath];
    [_iconLayer setStrokeColor:self.lineColor.CGColor];
    [_iconLayer setFillColor:self.lineColor.CGColor];
}

#pragma mark - icon view

- (void)setupIconViewWithType:(BMACircleIconType)type {
    NSString *imageName = nil;
    switch (type) {
        case BMACircleIconTypeInfinity:
            imageName = @"infinity_icon_norm";
            break;
        case BMACircleIconTypeExclamation:
            imageName = @"warning_icon_norm";
            break;
        case BMACircleIconTypeCheck:
            imageName = @"tick_viewed_icon_norm";
            break;
        default:
            break;
    }

    if (imageName) {
        self.iconView.image = [UIImage imageNamed:imageName inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
    }
}

#pragma mark - icon view

- (void)setupVisibilityWithType:(BMACircleIconType)type {
    self.titleView.hidden = YES;
    self.iconLayer.hidden = YES;
    self.iconView.hidden = YES;

    switch (type) {
        case BMACircleIconTypeInfinity:
        case BMACircleIconTypeExclamation:
        case BMACircleIconTypeCheck:
            self.iconView.hidden = NO;
            break;
        case BMACircleIconTypeArrowDown:
        case BMACircleIconTypeArrowUp:
        case BMACircleIconTypeStop:
            self.iconLayer.hidden = NO;
            break;
        case BMACircleIconTypeText:
            self.titleView.hidden = NO;
            break;
        default:
            break;
    }
}

#pragma mark - life cycle

- (void)layoutSubviews {
    [super layoutSubviews];
    _iconLayer.frame = self.bounds;
}

#pragma mark - actions

- (void)setType:(BMACircleIconType)type {
    _type = type;
    [self setupVisibilityWithType:_type];

    [self setupIconLayerWithType:_type];
    [self setupIconViewWithType:_type];
}

- (void)setTitle:(NSAttributedString *)title {
    [self setType:BMACircleIconTypeText];
    self.titleView.attributedText = title;
}

- (void)setLineColor:(UIColor *)lineColor {
    _lineColor = lineColor;
    _iconLayer.strokeColor = lineColor.CGColor;
    _titleView.textColor = lineColor;
}

- (void)setLineWidth:(CGFloat)lineWidth {
    _lineWidth = lineWidth;
    _iconLayer.lineWidth = lineWidth;
}

#pragma mark - defaults

- (CGFloat)verticalMargin {
    return self.bounds.size.width * 0.28;
}

- (CGFloat)horizontalMargin {
    return self.bounds.size.width * 0.29;
}

- (CGFloat)outterCircleRadius {
    return (self.bounds.size.width - 2 * _lineWidth) / 2;
}

- (CGFloat)horizontalMarginCoef {
    return 0.28;
}

@end
