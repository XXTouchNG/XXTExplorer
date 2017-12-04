//
//  XXTPixelCropView.m
//  XXTouchApp
//

#import "XXTPixelCropView.h"
#import "XXTPixelCropRectView.h"
#import "UIImage+XXTCrop.h"
#import "XXTPixelPreview.h"
#import "XXTPixelFlagView.h"
#import "XXTPickerFactory.h"

static const CGFloat MarginTop = 81.f;
//static const CGFloat MarginBottom = 81.f;
static const CGFloat MarginLeft = 37.f;
//static const CGFloat MarginRight = MarginLeft;

@interface XXTPixelCropView ()
        <
        UIScrollViewDelegate,
        UIGestureRecognizerDelegate,
        XXTCropRectViewDelegate
        >

@property(nonatomic) UIScrollView *scrollView;
@property(nonatomic) UIView *zoomingView;
@property(nonatomic) UIView *maskFlagView;
@property(nonatomic) UIImageView *imageView;

@property(nonatomic) XXTPixelCropRectView *cropRectView;
@property(nonatomic) UIView *topOverlayView;
@property(nonatomic) UIView *leftOverlayView;
@property(nonatomic) UIView *rightOverlayView;
@property(nonatomic) UIView *bottomOverlayView;

@property(nonatomic) CGRect insetRect;
@property(nonatomic) CGRect editingRect;

@property(nonatomic, getter = isResizing) BOOL resizing;
@property(nonatomic) UIInterfaceOrientation interfaceOrientation;
@property(nonatomic, strong) UIRotationGestureRecognizer *rotationGestureRecognizer;
@property(nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;
@property(nonatomic, strong) UIPanGestureRecognizer *panGestureRecognizer;

@property(nonatomic, strong) XXTPixelPreview *imagePreview;
@property(nonatomic, assign) CGPoint lastPoint;
@property(nonatomic, strong) NSMutableArray <XXTPixelFlagView *> *flagViews;

@property(nonatomic, assign) CGFloat ratio;

@end

@implementation XXTPixelCropView {
    NSUInteger lastPreviewCorner;
}

#pragma mark - Init

- (instancetype)initWithFrame:(CGRect)frame andType:(kXXTPixelCropViewType)type {
    if (self = [super initWithFrame:frame]) {
        [self commonInitWithType:type];
    }

    return self;
}

- (void)commonInitWithType:(kXXTPixelCropViewType)type {
    self.type = type;
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"xxt-crop-pattern"]];

    self.layer.masksToBounds = YES;

    self.scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
    self.scrollView.delegate = self;
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
    self.scrollView.backgroundColor = [UIColor clearColor];
    self.scrollView.maximumZoomScale = 1000.f;
    self.scrollView.minimumZoomScale = 1.f;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.bounces = NO;
    self.scrollView.bouncesZoom = NO;
    self.scrollView.clipsToBounds = NO;
    [self addSubview:self.scrollView];

    self.rotationGestureRecognizer = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(handleRotation:)];
    self.rotationGestureRecognizer.delegate = self;
    self.rotationGestureRecognizer.enabled = self.allowsRotate;
    [self.scrollView addGestureRecognizer:self.rotationGestureRecognizer];

    if (self.type == kXXTPixelCropViewTypeRect) {
        self.cropRectView = [[XXTPixelCropRectView alloc] init];
        self.cropRectView.delegate = self;
        [self addSubview:self.cropRectView];

        self.topOverlayView = [[UIView alloc] init];
        self.topOverlayView.backgroundColor = [UIColor colorWithWhite:1.f alpha:.4f];
        [self addSubview:self.topOverlayView];

        self.leftOverlayView = [[UIView alloc] init];
        self.leftOverlayView.backgroundColor = [UIColor colorWithWhite:1.f alpha:.4f];
        [self addSubview:self.leftOverlayView];

        self.rightOverlayView = [[UIView alloc] init];
        self.rightOverlayView.backgroundColor = [UIColor colorWithWhite:1.f alpha:.4f];
        [self addSubview:self.rightOverlayView];

        self.bottomOverlayView = [[UIView alloc] init];
        self.bottomOverlayView.backgroundColor = [UIColor colorWithWhite:1.f alpha:.4f];
        [self addSubview:self.bottomOverlayView];
    } else {
        self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        self.tapGestureRecognizer.delegate = self;
        self.tapGestureRecognizer.numberOfTouchesRequired = 1;
        self.tapGestureRecognizer.numberOfTapsRequired = 1;
        [self addGestureRecognizer:self.tapGestureRecognizer];

        self.panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        self.panGestureRecognizer.delegate = self;
        self.panGestureRecognizer.enabled = NO;
        [self addGestureRecognizer:self.panGestureRecognizer];
    }
}

#pragma mark - View Layout

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if (!self.userInteractionEnabled) {
        return nil;
    }

    if (self.type == kXXTPixelCropViewTypeRect) {
        UIView *hitView = [self.cropRectView hitTest:[self convertPoint:point toView:self.cropRectView] withEvent:event];
        if (hitView) {
            return hitView;
        }
    }

    CGPoint locationInImageView = [self convertPoint:point toView:self.zoomingView];
    CGPoint zoomedPoint = CGPointMake(locationInImageView.x * self.scrollView.zoomScale, locationInImageView.y * self.scrollView.zoomScale);

    if (CGRectContainsPoint(self.zoomingView.frame, zoomedPoint)) {
        return self.scrollView;
    }

    if (_delegate && [_delegate respondsToSelector:@selector(cropView:shouldEnterFullscreen:)] &&
            [_delegate respondsToSelector:@selector(cropViewFullscreen:)]
            ) {
        [_delegate cropView:self shouldEnterFullscreen:![_delegate cropViewFullscreen:self]];
    }

    return [super hitTest:point withEvent:event];
}

- (void)layoutSubviews {
    [super layoutSubviews];

    if (!self.image) {
        return;
    }

    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    self.editingRect = CGRectInset(self.bounds, MarginLeft, MarginTop);

    if (!self.imageView) {
        self.insetRect = CGRectInset(self.bounds, MarginLeft, MarginTop);

        [self setupImageView];
    }

    if (!self.isResizing) {
        if (self.type == kXXTPixelCropViewTypeRect) {
            [self layoutCropRectViewWithCropRect:self.scrollView.frame];
        }

        if (self.interfaceOrientation != interfaceOrientation) {
            [self zoomToCropRect:self.scrollView.frame];
        }
    }

    CGSize size = self.image.size;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad || UIInterfaceOrientationIsPortrait(interfaceOrientation)) {
        self.ratio = CGRectGetWidth(AVMakeRectWithAspectRatioInsideRect(size, self.insetRect)) / size.width;
    } else {
        self.ratio = CGRectGetHeight(AVMakeRectWithAspectRatioInsideRect(size, self.insetRect)) / size.height;
    }

    self.interfaceOrientation = interfaceOrientation;
}

- (void)setupImageView {
    CGRect cropRect = AVMakeRectWithAspectRatioInsideRect(self.image.size, self.insetRect);

    self.scrollView.frame = cropRect;
    self.scrollView.contentSize = cropRect.size;

    self.zoomingView = [[UIView alloc] initWithFrame:self.scrollView.bounds];
    self.zoomingView.backgroundColor = [UIColor clearColor];
    [self.scrollView addSubview:self.zoomingView];

    self.maskFlagView = [[UIView alloc] initWithFrame:self.scrollView.bounds];
    self.maskFlagView.backgroundColor = [UIColor clearColor];
    [self.scrollView addSubview:self.maskFlagView];

    self.imageView = [[UIImageView alloc] initWithFrame:self.zoomingView.bounds];
    self.imageView.backgroundColor = [UIColor clearColor];
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.imageView.image = self.image;
    self.imageView.layer.magnificationFilter = kCAFilterNearest;
    self.imageView.layer.minificationFilter = kCAFilterNearest;
    [self.zoomingView addSubview:self.imageView];
}

#pragma mark - Image Related

- (void)setAllowsRotate:(BOOL)allowsRotate {
    _allowsRotate = allowsRotate;
    self.rotationGestureRecognizer.enabled = allowsRotate;
}

- (void)setAllowsOperation:(BOOL)allowsOperation {
    _allowsOperation = allowsOperation;
    self.scrollView.scrollEnabled = allowsOperation;
    self.scrollView.pinchGestureRecognizer.enabled = allowsOperation;
    self.panGestureRecognizer.enabled = !allowsOperation;
}

- (void)setImage:(UIImage *)image {
    _image = image;
    lastPreviewCorner = 0;

    [self.imageView removeFromSuperview];
    self.imageView = nil;

    [self.zoomingView removeFromSuperview];
    self.zoomingView = nil;

    [self.maskFlagView removeFromSuperview];
    self.maskFlagView = nil;

    [self removeAllFlagViews];

    self.imagePreview.imageToMagnify = image;
    [self setNeedsLayout];
}

#pragma mark - Rotate

- (CGAffineTransform)rotation {
    return self.imageView.transform;
}

- (CGFloat)rotationAngle {
    CGAffineTransform rotation = self.imageView.transform;
    return atan2f(rotation.b, rotation.a);
}

- (void)setRotationAngle:(CGFloat)rotationAngle {
    self.imageView.transform = CGAffineTransformMakeRotation(rotationAngle);
}

- (void)setRotationAngle:(CGFloat)rotationAngle snap:(BOOL)snap {
    if (snap) {
        rotationAngle = (CGFloat) (nearbyintf((float) (rotationAngle / M_PI_2)) * M_PI_2);
    }
    self.rotationAngle = rotationAngle;
}

- (void)rotateLeft {
    self.imageView.transform = CGAffineTransformRotate(self.imageView.transform, (CGFloat) -M_PI_2);
}

- (void)rotateRight {
    self.imageView.transform = CGAffineTransformRotate(self.imageView.transform, (CGFloat) M_PI_2);
}

#pragma mark - Crop Layout

- (void)layoutCropRectViewWithCropRect:(CGRect)cropRect {
    self.cropRectView.frame = cropRect;
    [self layoutOverlayViewsWithCropRect:cropRect];
}

- (void)layoutOverlayViewsWithCropRect:(CGRect)cropRect {
    self.topOverlayView.frame = CGRectMake(0.0f,
            0.0f,
            CGRectGetWidth(self.bounds),
            CGRectGetMinY(cropRect));
    self.leftOverlayView.frame = CGRectMake(0.0f,
            CGRectGetMinY(cropRect),
            CGRectGetMinX(cropRect),
            CGRectGetHeight(cropRect));
    self.rightOverlayView.frame = CGRectMake(CGRectGetMaxX(cropRect),
            CGRectGetMinY(cropRect),
            CGRectGetWidth(self.bounds) - CGRectGetMaxX(cropRect),
            CGRectGetHeight(cropRect));
    self.bottomOverlayView.frame = CGRectMake(0.0f,
            CGRectGetMaxY(cropRect),
            CGRectGetWidth(self.bounds),
            CGRectGetHeight(self.bounds) - CGRectGetMaxY(cropRect));
}

#pragma mark - Crop Setter / Getter

- (void)setKeepingCropAspectRatio:(BOOL)keepingCropAspectRatio {
    _keepingCropAspectRatio = keepingCropAspectRatio;
    self.cropRectView.keepingAspectRatio = self.keepingCropAspectRatio;
}

- (CGFloat)cropAspectRatio {
    CGRect cropRect = self.scrollView.frame;
    CGFloat width = CGRectGetWidth(cropRect);
    CGFloat height = CGRectGetHeight(cropRect);
    return width / height;
}

- (void)setCropAspectRatio:(CGFloat)aspectRatio {
    [self setCropAspectRatio:aspectRatio andCenter:YES];
}

- (void)setCropAspectRatio:(CGFloat)aspectRatio andCenter:(BOOL)center {
    CGRect cropRect = self.scrollView.frame;
    CGFloat width = CGRectGetWidth(cropRect);
    CGFloat height = CGRectGetHeight(cropRect);
    if (aspectRatio <= 1.0f) {
        width = height * aspectRatio;
        if (width > CGRectGetWidth(self.imageView.bounds)) {
            width = CGRectGetWidth(cropRect);
            height = width / aspectRatio;
        }
    } else {
        height = width / aspectRatio;
        if (height > CGRectGetHeight(self.imageView.bounds)) {
            height = CGRectGetHeight(cropRect);
            width = height * aspectRatio;
        }
    }
    cropRect.size = CGSizeMake(width, height);
    [self zoomToCropRect:cropRect andCenter:center];
}

- (CGRect)cropRect {
    return self.scrollView.frame;
}

- (void)setCropRect:(CGRect)cropRect {
    [self zoomToCropRect:cropRect];
}

- (void)setImageCropRect:(CGRect)imageCropRect {
    [self resetCropRect];

    CGRect scrollViewFrame = self.scrollView.frame;
    CGSize imageSize = self.image.size;

    CGFloat scale = MIN(CGRectGetWidth(scrollViewFrame) / imageSize.width,
            CGRectGetHeight(scrollViewFrame) / imageSize.height);

    CGFloat x = CGRectGetMinX(imageCropRect) * scale + CGRectGetMinX(scrollViewFrame);
    CGFloat y = CGRectGetMinY(imageCropRect) * scale + CGRectGetMinY(scrollViewFrame);
    CGFloat width = CGRectGetWidth(imageCropRect) * scale;
    CGFloat height = CGRectGetHeight(imageCropRect) * scale;

    CGRect rect = CGRectMake(x, y, width, height);
    CGRect intersection = CGRectIntersection(rect, scrollViewFrame);

    if (!CGRectIsNull(intersection)) {
        self.cropRect = intersection;
    }
}

#pragma mark - Crop Reset

- (void)resetCropRect {
    [self resetCropRectAnimated:NO];
}

- (void)resetCropRectAnimated:(BOOL)animated {
    if (animated) {
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:0.25];
        [UIView setAnimationBeginsFromCurrentState:YES];
    }

    self.imageView.transform = CGAffineTransformIdentity;

    CGSize contentSize = self.scrollView.contentSize;
    CGRect initialRect = CGRectMake(0.0f, 0.0f, contentSize.width, contentSize.height);
    [self.scrollView zoomToRect:initialRect animated:NO];

    self.scrollView.bounds = self.imageView.bounds;

    if (self.type == kXXTPixelCropViewTypeRect) {
        [self layoutCropRectViewWithCropRect:self.scrollView.bounds];
    }

    if (animated) {
        [UIView commitAnimations];
    }

    if (self.type == kXXTPixelCropViewTypeRect) {
        [self zoomedRectUpdated:CGRectMake(0, 0, self.image.size.width, self.image.size.height)];
    }
}

#pragma mark - Crop Image

- (UIImage *)croppedImage {
    return [self.image rotatedImageWithTransform:self.rotation croppedToRect:self.zoomedCropRect];
}

- (CGRect)cappedCropRectInImageRectWithCropRectView:(XXTPixelCropRectView *)cropRectView {
    CGRect cropRect = cropRectView.frame;

    CGRect rect = [self convertRect:cropRect toView:self.scrollView];
    if (CGRectGetMinX(rect) < CGRectGetMinX(self.zoomingView.frame)) {
        cropRect.origin.x = CGRectGetMinX([self.scrollView convertRect:self.zoomingView.frame toView:self]);
        CGFloat cappedWidth = CGRectGetMaxX(rect);
        cropRect.size = CGSizeMake(cappedWidth,
                !self.keepingCropAspectRatio ? cropRect.size.height : cropRect.size.height * (cappedWidth / cropRect.size.width));
    }
    if (CGRectGetMinY(rect) < CGRectGetMinY(self.zoomingView.frame)) {
        cropRect.origin.y = CGRectGetMinY([self.scrollView convertRect:self.zoomingView.frame toView:self]);
        CGFloat cappedHeight = CGRectGetMaxY(rect);
        cropRect.size = CGSizeMake(!self.keepingCropAspectRatio ? cropRect.size.width : cropRect.size.width * (cappedHeight / cropRect.size.height),
                cappedHeight);
    }
    if (CGRectGetMaxX(rect) > CGRectGetMaxX(self.zoomingView.frame)) {
        CGFloat cappedWidth = CGRectGetMaxX([self.scrollView convertRect:self.zoomingView.frame toView:self]) - CGRectGetMinX(cropRect);
        cropRect.size = CGSizeMake(cappedWidth,
                !self.keepingCropAspectRatio ? cropRect.size.height : cropRect.size.height * (cappedWidth / cropRect.size.width));
    }
    if (CGRectGetMaxY(rect) > CGRectGetMaxY(self.zoomingView.frame)) {
        CGFloat cappedHeight = CGRectGetMaxY([self.scrollView convertRect:self.zoomingView.frame toView:self]) - CGRectGetMinY(cropRect);
        cropRect.size = CGSizeMake(!self.keepingCropAspectRatio ? cropRect.size.width : cropRect.size.width * (cappedHeight / cropRect.size.height),
                cappedHeight);
    }

    return cropRect;
}

#pragma mark - Crop Zoom

- (CGRect)zoomedCropRect {
    CGRect cropRect = [self convertRect:self.scrollView.frame toView:self.zoomingView];
    return [self zoomedRect:cropRect];
}

- (CGRect)zoomedRect:(CGRect)cropRect {
    CGRect zoomedCropRect = CGRectMake(cropRect.origin.x / _ratio,
            cropRect.origin.y / _ratio,
            cropRect.size.width / _ratio,
            cropRect.size.height / _ratio);

    return zoomedCropRect;
}

- (void)automaticZoomIfEdgeTouched:(CGRect)cropRect {
    if (CGRectGetMinX(cropRect) < CGRectGetMinX(self.editingRect) - 5.0f ||
            CGRectGetMaxX(cropRect) > CGRectGetMaxX(self.editingRect) + 5.0f ||
            CGRectGetMinY(cropRect) < CGRectGetMinY(self.editingRect) - 5.0f ||
            CGRectGetMaxY(cropRect) > CGRectGetMaxY(self.editingRect) + 5.0f) {
        [UIView animateWithDuration:1.0 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            [self zoomToCropRect:self.cropRectView.frame];
        }                completion:NULL];
    }
}

- (BOOL)userHasModifiedCropArea {
    CGRect zoomedCropRect = CGRectIntegral(self.zoomedCropRect);
    return (!CGPointEqualToPoint(zoomedCropRect.origin, CGPointZero) ||
            !CGSizeEqualToSize(zoomedCropRect.size, self.image.size) ||
            !CGAffineTransformEqualToTransform(self.rotation, CGAffineTransformIdentity));
}


#pragma mark - Crop Gesture

- (void)touchesBegan:(NSSet<UITouch *> *)touches
           withEvent:(UIEvent *)event {
    if (touches.count == 1) {
        UITouch *t = [touches anyObject];
        CGPoint p = [t locationInView:self];
        _lastPoint = p;
    }
}

- (void)cropRectViewDidBeginEditing:(XXTPixelCropRectView *)cropRectView {
    self.resizing = YES;
    self.imagePreview.statusBarHidden = [[UIApplication sharedApplication] isStatusBarHidden];
    [self movePreviewByPoint:_lastPoint];
    [self.imagePreview makeKeyAndVisible];
}

- (void)cropRectViewEditingChanged:(XXTPixelCropRectView *)cropRectView {
    CGRect cropRect = [self cappedCropRectInImageRectWithCropRectView:cropRectView];
    [self layoutCropRectViewWithCropRect:cropRect];

    CGPoint currentPoint = CGPointZero;
    CGRect zoomedRect = [self zoomedRect:[self convertRect:cropRect toView:self.zoomingView]];
    if (cropRectView.resizeControlPosition == kXXTResizeControlPositionTopLeft) {
        currentPoint = CGPointMake(zoomedRect.origin.x, zoomedRect.origin.y);
    } else if (cropRectView.resizeControlPosition == kXXTResizeControlPositionTopRight) {
        currentPoint = CGPointMake(zoomedRect.origin.x + zoomedRect.size.width, zoomedRect.origin.y);
    } else if (cropRectView.resizeControlPosition == kXXTResizeControlPositionBottomLeft) {
        currentPoint = CGPointMake(zoomedRect.origin.x, zoomedRect.origin.y + zoomedRect.size.height);
    } else if (cropRectView.resizeControlPosition == kXXTResizeControlPositionBottomRight) {
        currentPoint = CGPointMake(zoomedRect.origin.x + zoomedRect.size.width, zoomedRect.origin.y + zoomedRect.size.height);
    }

    [self.imagePreview setPointToMagnify:currentPoint];
    [self zoomedRectUpdated:zoomedRect];
}

- (void)cropRectViewDidEndEditing:(XXTPixelCropRectView *)cropRectView {
    if (self.scrollView.pinchGestureRecognizer.enabled) {
        [self zoomToCropRect:self.cropRectView.frame];
    }
    [self.imagePreview setHidden:YES];
    self.resizing = NO;
}

- (void)zoomToCropRect:(CGRect)toRect {
    [self zoomToCropRect:toRect andCenter:NO];
}

- (void)zoomToCropRect:(CGRect)toRect andCenter:(BOOL)center {
    if (CGRectEqualToRect(self.scrollView.frame, toRect)) {
        return;
    }

    CGFloat width = CGRectGetWidth(toRect);
    CGFloat height = CGRectGetHeight(toRect);

    CGFloat scale = MIN(CGRectGetWidth(self.editingRect) / width, CGRectGetHeight(self.editingRect) / height);

    CGFloat scaledWidth = width * scale;
    CGFloat scaledHeight = height * scale;
    CGRect cropRect = CGRectMake((CGRectGetWidth(self.bounds) - scaledWidth) / 2,
            (CGRectGetHeight(self.bounds) - scaledHeight) / 2,
            scaledWidth,
            scaledHeight);

    CGRect zoomRect = [self convertRect:toRect toView:self.zoomingView];
    zoomRect.size.width = CGRectGetWidth(cropRect) / (self.scrollView.zoomScale * scale);
    zoomRect.size.height = CGRectGetHeight(cropRect) / (self.scrollView.zoomScale * scale);

    if (center) {
        CGRect imageViewBounds = self.imageView.bounds;
        zoomRect.origin.y = (CGRectGetHeight(imageViewBounds) / 2) - (CGRectGetHeight(zoomRect) / 2);
        zoomRect.origin.x = (CGRectGetWidth(imageViewBounds) / 2) - (CGRectGetWidth(zoomRect) / 2);
    }

    // self.scrollView.minimumZoomScale = ??;

    [UIView animateWithDuration:0.4f delay:0.0f options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionBeginFromCurrentState animations:^{
        self.scrollView.bounds = cropRect;
        if (self.type == kXXTPixelCropViewTypeRect) {
            [self layoutCropRectViewWithCropRect:cropRect];
        }
        [self.scrollView zoomToRect:zoomRect animated:NO];
    }                completion:NULL];
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.zoomingView;
}

#pragma mark - Rotate Gesture

- (void)handleRotation:(UIRotationGestureRecognizer *)gestureRecognizer {
    CGFloat rotation = gestureRecognizer.rotation;

    CGAffineTransform transform = CGAffineTransformRotate(self.imageView.transform, rotation);
    self.imageView.transform = transform;
    gestureRecognizer.rotation = 0.0f;

    if (self.type == kXXTPixelCropViewTypeRect) {
        if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
            self.cropRectView.showsGridMinor = YES;
        } else if (gestureRecognizer.state == UIGestureRecognizerStateEnded ||
                gestureRecognizer.state == UIGestureRecognizerStateCancelled ||
                gestureRecognizer.state == UIGestureRecognizerStateFailed) {
            self.cropRectView.showsGridMinor = NO;
        }
    }
}

#pragma mark - Point Fix

- (CGPoint)zoomedPoint:(CGPoint)p {
    return CGPointMake(p.x / _ratio, p.y / _ratio);
}

- (CGPoint)restoredPoint:(CGPoint)p {
    return CGPointMake(p.x * _ratio, p.y * _ratio);
}

#pragma mark - Tap Gesture

- (void)handleTap:(UITapGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        CGPoint point = [gestureRecognizer locationInView:self];
        CGPoint locationInImageView = [self convertPoint:point toView:self.zoomingView];
        CGFloat zoomScale = self.scrollView.zoomScale;
        CGPoint scaledPoint = CGPointMake(locationInImageView.x * zoomScale, locationInImageView.y * zoomScale);
        if (CGRectContainsPoint(self.zoomingView.frame, scaledPoint)) {
            CGPoint p = [self zoomedPoint:locationInImageView];
            CGPoint fixedPoint = CGPointMake((CGFloat) (floor(p.x) + 0.5), (CGFloat) (floor(p.y) + 0.5));
            CGPoint restoredPoint = [self restoredPoint:fixedPoint];

            UIColor *c = [self.imagePreview getColorOfPoint:p];
            if (self.type == kXXTPixelCropViewTypeColor ||
                    self.type == kXXTPixelCropViewTypePosition ||
                    self.type == kXXTPixelCropViewTypePositionColor) {
                [self removeAllFlagViews];
                [self addFlagViewAtPoint:restoredPoint andReal:p];
            } else if (self.type == kXXTPixelCropViewTypeMultiplePositionColor) {
                [self addFlagViewAtPoint:restoredPoint andReal:p andColor:c];
                [self modelArrayUpdated]; // Set Array
            }

            if (self.type == kXXTPixelCropViewTypeColor) {
                [self colorUpdated:c];
            } else if (self.type == kXXTPixelCropViewTypePosition) {
                [self zoomedPointUpdated:p];
            } else if (self.type == kXXTPixelCropViewTypePositionColor) {
                [self modelUpdatedWithPosition:p andColor:c];
            } else if (self.type == kXXTPixelCropViewTypeMultiplePositionColor) {
                [self modelUpdatedWithPosition:p andColor:c];
            }
        }
    }
}

#pragma mark - Pan Gesture

- (void)handlePan:(UIPanGestureRecognizer *)gestureRecognizer {
    CGPoint point = [gestureRecognizer locationInView:self];
    CGPoint locationInImageView = [self convertPoint:point toView:self.zoomingView];
    CGFloat zoomScale = self.scrollView.zoomScale;
    CGPoint scaledPoint = CGPointMake(locationInImageView.x * zoomScale, locationInImageView.y * zoomScale);
    if (CGRectContainsPoint(self.zoomingView.frame, scaledPoint)) {
        CGPoint p = [self zoomedPoint:locationInImageView];
        [self.imagePreview setPointToMagnify:p];
        UIColor *c = self.imagePreview.colorOfLastPoint;
        if (gestureRecognizer.state == UIGestureRecognizerStateChanged) {
            [self movePreviewByPoint:point];
        } else if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
            self.imagePreview.statusBarHidden = [[UIApplication sharedApplication] isStatusBarHidden];
            [self movePreviewByPoint:point];
            [self.imagePreview makeKeyAndVisible];
        } else if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
            CGPoint fixedPoint = CGPointMake((CGFloat) (floor(p.x) + 0.5), (CGFloat) (floor(p.y) + 0.5));
            CGPoint restoredPoint = [self restoredPoint:fixedPoint];
            // Ended and mark
            if (self.type == kXXTPixelCropViewTypeColor ||
                    self.type == kXXTPixelCropViewTypePosition ||
                    self.type == kXXTPixelCropViewTypePositionColor) {
                [self removeAllFlagViews];
                [self addFlagViewAtPoint:restoredPoint andReal:p];
            } else if (self.type == kXXTPixelCropViewTypeMultiplePositionColor) {
                [self addFlagViewAtPoint:restoredPoint andReal:p andColor:c];
                [self modelArrayUpdated]; // Set Array
            }
        }
        if (self.type == kXXTPixelCropViewTypeColor) {
            [self colorUpdated:c];
        } else if (self.type == kXXTPixelCropViewTypePosition) {
            [self zoomedPointUpdated:p];
        } else if (self.type == kXXTPixelCropViewTypePositionColor) {
            [self modelUpdatedWithPosition:p andColor:c];
        } else if (self.type == kXXTPixelCropViewTypeMultiplePositionColor) {
            [self modelUpdatedWithPosition:p andColor:c];
        }
    }
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded || gestureRecognizer.state == UIGestureRecognizerStateCancelled) {
        [self.imagePreview setHidden:YES];
    }
}

#pragma mark - Flag

- (NSMutableArray <XXTPixelFlagView *> *)flagViews {
    if (!_flagViews) {
        _flagViews = [[NSMutableArray alloc] init];
    }
    return _flagViews;
}

- (void)addFlagViewAtPoint:(CGPoint)p andReal:(CGPoint)r {
    [self addFlagViewAtPoint:p andReal:r andColor:nil];
}

- (void)addFlagViewAtPoint:(CGPoint)p andReal:(CGPoint)r andColor:(UIColor *)c {
    CGFloat zoomScale = self.scrollView.zoomScale;
    XXTPixelFlagView *newFlagView = [[XXTPixelFlagView alloc] initWithFrame:CGRectMake(0, 0, 22.f, 22.f)];
    newFlagView.center = CGPointMake(p.x * zoomScale, p.y * zoomScale);
    XXTPixelFlagView *repeatedFlagView = nil;
    for (XXTPixelFlagView *v in self.flagViews) {
        if (CGRectContainsPoint(newFlagView.frame, v.center)) {
            repeatedFlagView = v;
            break;
        }
    }
    if (repeatedFlagView) {
        [self maskViewTapped:repeatedFlagView];
        return;
    }
    newFlagView.originalPoint = p;
    newFlagView.index = self.flagViews.count + 1;
    if (c) {
        newFlagView.dataModel.position = r;
        newFlagView.dataModel.color = c;
    }
    [self.maskFlagView addSubview:newFlagView];
    [self.flagViews addObject:newFlagView];
}

- (void)removeAllFlagViews {
    for (XXTPixelFlagView *v in self.flagViews) {
        [v removeFromSuperview];
    }
    [self.flagViews removeAllObjects];
}

- (void)adjustFlagViews {
    for (XXTPixelFlagView *v in self.flagViews) {
        CGFloat zoomScale = self.scrollView.zoomScale;
        CGPoint p = v.originalPoint;
        v.center = CGPointMake(p.x * zoomScale, p.y * zoomScale);
    }
}

- (void)resetIndexesOfFlagViews {
    NSUInteger i = 0;
    for (XXTPixelFlagView *v in self.flagViews) {
        i++;
        v.index = i;
    }
}

- (void)maskViewTapped:(XXTPixelFlagView *)view {
    [view removeFromSuperview];
    [self.flagViews removeObject:view];
    [self resetIndexesOfFlagViews];
}

#pragma mark - Gestures

- (void)notifyDelegateValueUpdated:(id)value {
    if (_delegate && [_delegate respondsToSelector:@selector(cropView:selectValueUpdated:)]) {
        [_delegate cropView:self selectValueUpdated:value];
    }
}

- (void)zoomedPointUpdated:(CGPoint)zoomedPoint {
    [self notifyDelegateValueUpdated:[NSValue valueWithCGPoint:zoomedPoint]];
}

- (void)zoomedRectUpdated:(CGRect)zoomedRect {
    [self notifyDelegateValueUpdated:[NSValue valueWithCGRect:zoomedRect]];
}

- (void)colorUpdated:(UIColor *)color {
    [self notifyDelegateValueUpdated:color];
}

- (void)modelUpdatedWithPosition:(CGPoint)p andColor:(UIColor *)c {
    XXTPositionColorModel *model = [XXTPositionColorModel new];
    model.position = p;
    model.color = c;
    [self notifyDelegateValueUpdated:model];
}

- (void)modelArrayUpdated {
    NSMutableArray <XXTPositionColorModel *> *modelArray = [NSMutableArray new];
    for (XXTPixelFlagView *v in self.flagViews) {
        [modelArray addObject:v.dataModel];
    }
    [self notifyDelegateValueUpdated:modelArray];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

#pragma mark - Area Event

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (self.type == kXXTPixelCropViewTypeRect) {
        [self zoomedRectUpdated:self.zoomedCropRect];
    }
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    if (self.type == kXXTPixelCropViewTypeRect) {
        [self zoomedRectUpdated:self.zoomedCropRect];
    } else {
        [self adjustFlagViews];
    }
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    CGPoint contentOffset = scrollView.contentOffset;
    *targetContentOffset = contentOffset;
}

#pragma mark - Preview

- (XXTPixelPreview *)imagePreview {
    if (!_imagePreview) {
        _imagePreview = [[XXTPixelPreview alloc] init];
        [_imagePreview setHidden:YES];
    }
    return _imagePreview;
}

- (void)movePreviewByPoint:(CGPoint)p {
    UIEdgeInsets insets = UIEdgeInsetsZero;
    if (@available(iOS 11.0, *)) {
        insets = self.safeAreaInsets;
    }
    CGFloat sW = [UIScreen mainScreen].bounds.size.width;
    CGFloat sH = [UIScreen mainScreen].bounds.size.height;
    CGFloat width = (int) (MIN(sW, sH) / 20.f) * 10.f;
    if (p.x < sW / 2.f) {
        if (p.y < sH / 2.f) {
            // 2
            if (lastPreviewCorner != 2) {
                lastPreviewCorner = 2;
                self.imagePreview.frame = CGRectMake(sW - width - insets.right, sH - width - insets.bottom, width, width);
            }
        } else {
            // 4
            if (lastPreviewCorner != 4) {
                lastPreviewCorner = 4;
                self.imagePreview.frame = CGRectMake(sW - width - insets.right, insets.top, width, width);
            }
        }
    } else {
        if (p.y < sH / 2.f) {
            // 1
            if (lastPreviewCorner != 1) {
                lastPreviewCorner = 1;
                self.imagePreview.frame = CGRectMake(insets.left, sH - width - insets.bottom, width, width);
            }
        } else {
            // 3
            if (lastPreviewCorner != 3) {
                lastPreviewCorner = 3;
                self.imagePreview.frame = CGRectMake(insets.left, insets.top, width, width);
            }
        }
    }
}

@end
