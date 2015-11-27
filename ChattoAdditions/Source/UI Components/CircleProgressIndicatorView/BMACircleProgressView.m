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

#import "BMACircleProgressView.h"

@interface BMACircleProgressView ()
@property (nonatomic, assign) CGFloat lineWidth;
@property (nonatomic, strong) UIColor *lineColor;
@property (nonatomic, strong) CAShapeLayer *bgLayer;
@property (nonatomic, strong) CAShapeLayer *progressLayer;
@property (nonatomic, assign, getter=isPreparingForLoading) BOOL preparingForLoading;
@property (nonatomic, assign) CGFloat progress;
@end

@implementation BMACircleProgressView

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
    [self addSubLayers];
    [self updateBgLayer];
}

#pragma mark - layers

- (void)addSubLayers {
    [self addBgLayer];
    [self addProgressLayer];
}

- (void)addBgLayer {
    self.bgLayer = [CAShapeLayer layer];
    _bgLayer.strokeColor = _lineColor.CGColor;
    _bgLayer.fillColor = self.backgroundColor.CGColor;
    _bgLayer.lineCap = kCALineCapRound;
    _bgLayer.lineWidth = _lineWidth;
    [self.layer addSublayer:_bgLayer];
}

- (void)addProgressLayer {
    self.progressLayer = [CAShapeLayer layer];
    _progressLayer.strokeColor = _lineColor.CGColor;
    _progressLayer.fillColor = nil;
    _progressLayer.lineCap = kCALineCapSquare;
    _progressLayer.lineWidth = _lineWidth * 2.2;
    [self.layer addSublayer:_progressLayer];
}

#pragma mark - life cycle

- (void)layoutSubviews {
    [super layoutSubviews];
    _bgLayer.frame = self.bounds;
    _progressLayer.frame = self.bounds;
}

#pragma mark - actions

- (void)prepareForLoading {
    self.preparingForLoading = YES;
    [self updateBgLayer];
    CABasicAnimation *rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue = [NSNumber numberWithFloat:M_PI * 2.0];
    rotationAnimation.duration = 1;
    rotationAnimation.cumulative = YES;
    rotationAnimation.repeatCount = HUGE_VALF;
    [_bgLayer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
}

- (void)finishPrepareForLoading {
    if (self.preparingForLoading) {
        [_bgLayer removeAllAnimations];
        self.preparingForLoading = NO;
        [self updateBgLayer];
    }
}

- (void)setProgress:(CGFloat)progress {
    if (progress >= 0.0 && progress <= 1.0) {
        _progress = progress;
        _progressLayer.hidden = _progress >= 1.0;
        [self updateProgressLayer];
    }
}

#pragma mark - line style

- (void)setLineColor:(UIColor *)lineColor {
    _lineColor = lineColor;
    _bgLayer.strokeColor = lineColor.CGColor;
    _progressLayer.strokeColor = lineColor.CGColor;
    [self updateBgLayer];
}

- (void)setLineWidth:(CGFloat)lineWidth {
    _lineWidth = lineWidth;
    _bgLayer.lineWidth = lineWidth;
    _progressLayer.lineWidth = lineWidth * 2.0;
    [self updateBgLayer];
}

#pragma mark - Update Layers

- (void)updateBgLayer {
    CGFloat spinningGapInCircle = self.isPreparingForLoading ? 1.8 : 2.0;
    CGFloat radius = CGRectGetWidth(self.bounds) / 2 - self.lineWidth;
    CGPoint center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    UIBezierPath *bgCircle = [UIBezierPath bezierPathWithArcCenter:center radius:radius startAngle:-M_PI_2 endAngle:(spinningGapInCircle * M_PI - M_PI_2)clockwise:YES];
    bgCircle.lineWidth = _lineWidth;
    bgCircle.lineCapStyle = kCGLineCapRound;
    _bgLayer.path = bgCircle.CGPath;
}

- (void)updateProgressLayer {
    CGFloat radius = (self.bounds.size.width - _lineWidth * 4) / 2.0;
    CGPoint center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    UIBezierPath *progressCircle = [UIBezierPath bezierPathWithArcCenter:center radius:radius startAngle:-M_PI_2 endAngle:self.progress * 2 * M_PI - M_PI_2 clockwise:YES];
    progressCircle.lineCapStyle = kCGLineCapButt;
    progressCircle.lineWidth = _lineWidth;
    _progressLayer.path = progressCircle.CGPath;
}

@end
