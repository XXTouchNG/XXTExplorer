//
//  XXTEScanViewController.m
//  XXTExplorer
//
//  Created by Zheng on 09/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEScanViewController.h"

#import <objc/runtime.h>
#import <objc/message.h>

#import <AVFoundation/AVFoundation.h>

#import <PromiseKit/PromiseKit.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <LGAlertView/LGAlertView.h>

#import "XXTEScanLineAnimation.h"
#import "XXTEImagePickerController.h"
#import "UIImage+ColoredImage.h"


static CGFloat XXTEScanVOffset = -22.0;

@interface XXTEScanViewController () <AVCaptureMetadataOutputObjectsDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, LGAlertViewDelegate>

@property(nonatomic, strong) AVCaptureSession *scanSession;
@property(nonatomic, strong) AVCaptureDevice *scanDevice;
@property(nonatomic, strong) AVCaptureDeviceInput *scanInput;
@property(nonatomic, strong) AVCaptureMetadataOutput *scanOutput;
@property(nonatomic, strong) AVCaptureVideoPreviewLayer *scanLayer;

@property(nonatomic, strong) UIBarButtonItem *dismissItem;
@property(nonatomic, strong) UIBarButtonItem *albumItem;
@property(nonatomic, strong) UIImageView *maskView;
@property(nonatomic, assign) CGRect cropRect;
@property(nonatomic, strong) XXTEScanLineAnimation *scanLineAnimation;

@property(nonatomic, strong) UIButton *lightButton;
@property(nonatomic, strong) UIButton *flipButton;

@end

@implementation XXTEScanViewController {
    
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        
    }
    return self;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context)
     {
         [self reloadCaptureSceneWithSize:size];
     } completion:^(id<UIViewControllerTransitionCoordinatorContext> context)
     {
         
     }];
    
    XXTE_START_IGNORE_PARTIAL
    if (@available(iOS 8.0, *)) {
        [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    }
    XXTE_END_IGNORE_PARTIAL
}

#pragma mark - Styles

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Scan", nil);
    self.view.backgroundColor = [UIColor blackColor];
    self.edgesForExtendedLayout = UIRectEdgeAll;
    self.extendedLayoutIncludesOpaqueBars = YES;

    [self.view addSubview:self.maskView];
    [self.view addSubview:self.lightButton];
    [self.view addSubview:self.flipButton];
    
    [self.view addConstraints:@[
      [NSLayoutConstraint constraintWithItem:self.lightButton attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeadingMargin multiplier:1.0 constant:16.0],
      [NSLayoutConstraint constraintWithItem:self.lightButton attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottomMargin multiplier:1.0 constant:-32.0],
      [NSLayoutConstraint constraintWithItem:self.lightButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeWidth multiplier:1.0 constant:64.0],
      [NSLayoutConstraint constraintWithItem:self.lightButton attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1.0 constant:64.0],
      ]];
    [self.view addConstraints:@[
      [NSLayoutConstraint constraintWithItem:self.flipButton attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTrailingMargin multiplier:1.0 constant:-16.0],
      [NSLayoutConstraint constraintWithItem:self.flipButton attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottomMargin multiplier:1.0 constant:-32.0],
      [NSLayoutConstraint constraintWithItem:self.flipButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeWidth multiplier:1.0 constant:64.0],
      [NSLayoutConstraint constraintWithItem:self.flipButton attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1.0 constant:64.0],
      ]];
    
    [self.navigationController.navigationBar setBackgroundImage:[[UIImage alloc] init] forBarMetrics:UIBarMetricsDefault];
    [self.navigationController.navigationBar setShadowImage:[[UIImage alloc] init]];
    [self.navigationController.navigationBar setBarStyle:UIBarStyleBlackTranslucent];
    
    if ([self.navigationController.viewControllers firstObject] == self) {
        self.navigationItem.leftBarButtonItem = self.dismissItem;
    }
    self.navigationItem.rightBarButtonItem = self.albumItem;
    XXTE_START_IGNORE_PARTIAL
    if (isOS11Above()) {
        if (isAppStore()) {
            self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;
        } else {
            self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
        }
    }
    XXTE_END_IGNORE_PARTIAL
    
    [self fetchVideoPermission];
}

- (void)reloadCaptureSceneWithSize:(CGSize)toSize {

    CGFloat scale = [[UIScreen mainScreen] scale];

    CGSize oldSize = toSize;
    CGFloat maxLength = MAX(oldSize.width, oldSize.height);
    CGFloat minLength = MIN(oldSize.width, oldSize.height);
    CGSize size = CGSizeMake(maxLength, maxLength);
    CGFloat rectWidth = minLength / 3 * 2;
    
    CGPoint pA = CGPointMake(size.width / 2 - rectWidth / 2, (size.height / 2 - rectWidth / 2) + XXTEScanVOffset);
    CGPoint pD = CGPointMake(size.width / 2 + rectWidth / 2, (size.height / 2 + rectWidth / 2) + XXTEScanVOffset);

    // Begin Context
    UIGraphicsBeginImageContextWithOptions(size, NO, scale);
    CGContextRef ctx = UIGraphicsGetCurrentContext();

    // Fill Background
    CGContextSetRGBFillColor(ctx, 0, 0, 0, 0.3f);
    CGRect drawRect = CGRectMake(0, 0, size.width, size.height);
    CGContextFillRect(ctx, drawRect);

    // Clear Rect
    CGRect cropRect = CGRectMake(pA.x, pA.y, rectWidth, rectWidth);
    CGContextClearRect(ctx, cropRect);

    // Draw Rect Lines
    CGContextSetLineWidth(ctx, 1.6f);
    CGContextSetRGBStrokeColor(ctx, 1, 1, 1, 1);
    CGContextAddRect(ctx, cropRect);
    CGContextStrokePath(ctx);

    // Draw Rect Angles
    CGFloat lineWidthAngle = 8.f;
    CGFloat diffAngle = lineWidthAngle / 3;
    CGFloat wAngle = 24.f;
    CGFloat hAngle = 24.f;
    CGFloat leftX = pA.x - diffAngle;
    CGFloat topY = pA.y - diffAngle;
    CGFloat rightX = pD.x + diffAngle;
    CGFloat bottomY = pD.y + diffAngle;

    CGContextSetLineWidth(ctx, lineWidthAngle);
    CGContextSetStrokeColorWithColor(ctx, [XXTColorDefault() colorWithAlphaComponent:.75f].CGColor);

    CGContextMoveToPoint(ctx, leftX - lineWidthAngle / 2, topY);
    CGContextAddLineToPoint(ctx, leftX + wAngle, topY);
    CGContextMoveToPoint(ctx, leftX, topY - lineWidthAngle / 2);
    CGContextAddLineToPoint(ctx, leftX, topY + hAngle);
    CGContextMoveToPoint(ctx, leftX - lineWidthAngle / 2, bottomY);
    CGContextAddLineToPoint(ctx, leftX + wAngle, bottomY);
    CGContextMoveToPoint(ctx, leftX, bottomY + lineWidthAngle / 2);
    CGContextAddLineToPoint(ctx, leftX, bottomY - hAngle);
    CGContextMoveToPoint(ctx, rightX + lineWidthAngle / 2, topY);
    CGContextAddLineToPoint(ctx, rightX - wAngle, topY);
    CGContextMoveToPoint(ctx, rightX, topY - lineWidthAngle / 2);
    CGContextAddLineToPoint(ctx, rightX, topY + hAngle);
    CGContextMoveToPoint(ctx, rightX + lineWidthAngle / 2, bottomY);
    CGContextAddLineToPoint(ctx, rightX - wAngle, bottomY);
    CGContextMoveToPoint(ctx, rightX, bottomY + lineWidthAngle / 2);
    CGContextAddLineToPoint(ctx, rightX, bottomY - hAngle);
    CGContextStrokePath(ctx);

    // Generate Image
    UIImage *returnImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    self.maskView.image = returnImage;

    AVCaptureConnection *layerConnection = self.scanLayer.connection;
    if ([layerConnection isVideoOrientationSupported])
        [layerConnection setVideoOrientation:(AVCaptureVideoOrientation)[[UIApplication sharedApplication] statusBarOrientation]];
    self.scanLineAnimation.animationRect = self.cropRect;
    self.scanLayer.frame = self.view.layer.bounds;
    
    [self reloadLightButtonStatus];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadCaptureSceneWithSize:self.view.bounds.size];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleEnterForeground:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    {
        blockInteractions(self, NO);
        [self performSelector:@selector(startAnimation) withObject:nil afterDelay:.6f];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    {
        self.maskView.image = nil;
        [self stopAnimation];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    {
        blockInteractions(self, YES);
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)startAnimation {
    if (!self.scanLineAnimation.isAnimating) {
        [self.scanLineAnimation startAnimatingWithRect:self.cropRect parentView:self.maskView];
    }
}

- (void)stopAnimation {
    if (self.scanLineAnimation.isAnimating) {
        [self.scanLineAnimation stopAnimating];
    }
}

- (void)continueScan {
    [self startAnimation];
    if (self.scanSession != nil && ![self.scanSession isRunning]) {
        [self.scanSession startRunning];
    }
}

- (void)pauseScan {
    [self stopAnimation];
    if (self.scanSession != nil && [self.scanSession isRunning]) {
        [self.scanSession stopRunning];
    }
}

- (BOOL)loadLayerFrameWithSelectedState:(BOOL)state
{
    AVCaptureDevice *scanDevice = (state) ? [self frontCamera] : [self backCamera];
    if (!scanDevice)
        return NO;
    _scanDevice = scanDevice;
    AVCaptureSession *scanSession = [self reloadScanSessionWithCamera:scanDevice];
    if (!scanSession)
        return NO;
    if (_scanLayer) [_scanLayer removeFromSuperlayer];
    AVCaptureVideoPreviewLayer *scanLayer = [AVCaptureVideoPreviewLayer layerWithSession:scanSession];
    if (!scanLayer)
        return NO;
    scanLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    scanLayer.frame = self.view.layer.bounds;
    _scanLayer = scanLayer;
    [self.view.layer insertSublayer:scanLayer atIndex:0];
    [scanSession startRunning];
    return YES;
}

#pragma mark - UIView Getters

- (AVCaptureSession *)reloadScanSessionWithCamera:(AVCaptureDevice *)scanDevice {
    if (!scanDevice) {
        return nil;
    }
    AVCaptureSession *scanSession = [[AVCaptureSession alloc] init];
    if ([scanSession canSetSessionPreset:AVCaptureSessionPresetHigh]) {
        [scanSession setSessionPreset:AVCaptureSessionPresetHigh];
    }
    NSError *inputError = nil;
    AVCaptureDeviceInput *scanInput = [AVCaptureDeviceInput deviceInputWithDevice:scanDevice error:&inputError];
    if (scanInput != nil && [scanSession canAddInput:scanInput]) {
        [scanSession addInput:scanInput];
        _scanInput = scanInput;
    } else {
        return nil;
    }
    AVCaptureMetadataOutput *scanOutput = [[AVCaptureMetadataOutput alloc] init];
    [scanOutput setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    if (scanOutput != nil && [scanSession canAddOutput:scanOutput]) {
        [scanSession addOutput:scanOutput];
        _scanOutput = scanOutput;
    } else {
        return nil;
    }
    if ([scanOutput.availableMetadataObjectTypes containsObject:AVMetadataObjectTypeQRCode]) {
        scanOutput.metadataObjectTypes = @[AVMetadataObjectTypeQRCode];
    }
    CGSize viewSize = self.view.bounds.size;
    scanOutput.rectOfInterest = CGRectMake(self.cropRect.origin.y / viewSize.height,
                                           self.cropRect.origin.x / viewSize.width,
                                           self.cropRect.size.height / viewSize.height,
                                           self.cropRect.size.width / viewSize.width);
    _scanSession = scanSession;
    return scanSession;
}

- (AVCaptureDevice *)frontCamera {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == AVCaptureDevicePositionFront) {
            return device;
        }
    }
    return nil;
}

- (AVCaptureDevice *)backCamera {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == AVCaptureDevicePositionBack) {
            return device;
        }
    }
    return nil;
}

- (UIBarButtonItem *)dismissItem {
    if (!_dismissItem) {
        UIBarButtonItem *dismissItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismissScanViewController:)];
        dismissItem.tintColor = [UIColor whiteColor];
        _dismissItem = dismissItem;
    }
    return _dismissItem;
}

- (UIBarButtonItem *)albumItem {
    if (!_albumItem) {
        UIBarButtonItem *albumItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Album", nil) style:UIBarButtonItemStylePlain target:self action:@selector(albumItemTapped:)];
        albumItem.tintColor = [UIColor whiteColor];
        _albumItem = albumItem;
    }
    return _albumItem;
}

- (CGRect)cropRect {
    CGSize oldSize = self.view.bounds.size;
    CGFloat minLength = MIN(oldSize.width, oldSize.height);
    CGFloat rectWidth = minLength / 3 * 2;
    return CGRectMake(oldSize.width / 2 - rectWidth / 2, (oldSize.height / 2 - rectWidth / 2) + XXTEScanVOffset, rectWidth, rectWidth);
}

- (UIImageView *)maskView {
    if (!_maskView) {
        UIImageView *maskView = [[UIImageView alloc] initWithFrame:self.view.bounds];
        maskView.backgroundColor = [UIColor colorWithWhite:0.f alpha:0.f];
        maskView.contentMode = UIViewContentModeCenter;
        maskView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _maskView = maskView;
    }
    return _maskView;
}

- (XXTEScanLineAnimation *)scanLineAnimation {
    if (!_scanLineAnimation) {
        XXTEScanLineAnimation *scanLineAnimation = [[XXTEScanLineAnimation alloc] initWithImage:[UIImage imageNamed:@"XXTEScanAnimationLine"]];
        _scanLineAnimation = scanLineAnimation;
    }
    return _scanLineAnimation;
}

- (UIButton *)lightButton {
    if (!_lightButton) {
        _lightButton = [[UIButton alloc] init];
        [_lightButton setBackgroundImage:[UIImage imageWithUIColor:[UIColor colorWithWhite:0.0 alpha:0.40]] forState:UIControlStateNormal];
        [_lightButton setBackgroundImage:[UIImage imageWithUIColor:[UIColor colorWithWhite:1.0 alpha:0.40]] forState:UIControlStateSelected];
        [_lightButton setImage:[UIImage imageNamed:@"XXTEScanButtonLight"] forState:UIControlStateNormal];
        _lightButton.layer.cornerRadius = 32.0;
        _lightButton.layer.masksToBounds = YES;
        _lightButton.translatesAutoresizingMaskIntoConstraints = NO;
        [_lightButton addTarget:self action:@selector(lightButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _lightButton;
}

- (UIButton *)flipButton {
    if (!_flipButton) {
        _flipButton = [[UIButton alloc] init];
        [_flipButton setBackgroundImage:[UIImage imageWithUIColor:[UIColor colorWithWhite:0.0 alpha:0.40]] forState:UIControlStateNormal];
        [_flipButton setBackgroundImage:[UIImage imageWithUIColor:[UIColor colorWithWhite:1.0 alpha:0.40]] forState:UIControlStateSelected];
        [_flipButton setImage:[UIImage imageNamed:@"XXTEScanButtonFlip"] forState:UIControlStateNormal];
        _flipButton.layer.cornerRadius = 32.0;
        _flipButton.layer.masksToBounds = YES;
        _flipButton.translatesAutoresizingMaskIntoConstraints = NO;
        [_flipButton addTarget:self action:@selector(flipButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _flipButton;
}

#pragma mark - UIControl Actions

- (void)lightButtonTapped:(UIButton *)sender {
    AVCaptureDevice *captureDevice = self.scanDevice;
    if (!captureDevice) return;
    NSError *error = nil;
    if ([captureDevice hasTorch] && [captureDevice isTorchAvailable]) {
        BOOL locked = [captureDevice lockForConfiguration:&error];
        if (locked) {
            if (!sender.selected) {
                [captureDevice setTorchMode:AVCaptureTorchModeOn];
            } else {
                [captureDevice setTorchMode:AVCaptureTorchModeOff];
            }
            [captureDevice unlockForConfiguration];
            sender.selected = !sender.selected;
        }
    } else {
        toastMessage(self, NSLocalizedString(@"Torch is not available.", nil));
    }
    if (error) {
        toastError(self, error);
    }
}

- (void)flipButtonTapped:(UIButton *)sender {
    sender.enabled = NO;
    BOOL loadResult = [self loadLayerFrameWithSelectedState:(!sender.selected)];
    if (!loadResult) {
        toastMessage(self, NSLocalizedString(@"Cannot connect to video device.", nil));
        sender.enabled = YES;
        return;
    }
    sender.selected = !sender.selected;
    [self reloadLightButtonStatus];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        sender.enabled = YES;
    });
}

- (void)reloadLightButtonStatus {
    if (self.flipButton.selected) {
        self.lightButton.enabled = NO;
        [self.lightButton setSelected:NO];
    } else {
        self.lightButton.enabled = YES;
        [self.lightButton setSelected:([self.scanDevice torchMode] == AVCaptureTorchModeOn)];
    }
}

- (void)dismissScanViewController:(UIBarButtonItem *)sender {
    if (XXTE_IS_IPAD) {
        [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:XXTENotificationEvent object:self userInfo:@{XXTENotificationEventType: XXTENotificationEventTypeFormSheetDismissed}]];
    }
    [self dismissViewControllerAnimated:YES completion:^() {
        
    }];
}

- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion {
    if (self.scanSession != nil) {
        [self.scanSession stopRunning];
        self.scanSession = nil;
    }
    [super dismissViewControllerAnimated:flag completion:completion];
}

- (void)albumItemTapped:(UIBarButtonItem *)sender {
    if (@available(iOS 8.0, *)) {
        if (![XXTEImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
            return;
        }
        [self pauseScan];
        XXTEImagePickerController *imagePicker = [[XXTEImagePickerController alloc] init];
        imagePicker.delegate = self;
        imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        imagePicker.allowsEditing = NO;
        imagePicker.mediaTypes = @[(__bridge NSString *) kUTTypeImage];
        imagePicker.navigationBar.translucent = NO;
        imagePicker.navigationBar.barTintColor = XXTColorDefault();
        imagePicker.navigationBar.tintColor = [UIColor whiteColor];
        imagePicker.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor]};
        imagePicker.modalPresentationStyle = UIModalPresentationCurrentContext;
        imagePicker.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        [self.navigationController presentViewController:imagePicker animated:YES completion:nil];
    } else {
        toastMessage(self, NSLocalizedString(@"This feature requires iOS 8.0 or later.", nil));
    }
}

#pragma mark - Permission Request

- (void)fetchVideoPermission {
    PMKPromise *fetchPermissionPromise = [PMKPromise promiseWithResolver:^(PMKResolver resolve) {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
            resolve(@(status));
        }];
    }];
    PMKPromise *checkPermissionPromise = [PMKPromise promiseWithResolver:^(PMKResolver resolve) {
        AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        resolve(@(status));
    }];
    __block BOOL layerLoaded = NO;
    @weakify(self);
    id (^ displayPermissionBlock)(NSNumber *) = ^(NSNumber *status) {
        @strongify(self);
        AVAuthorizationStatus permissionStatus = (AVAuthorizationStatus) [status integerValue];
        if (permissionStatus == AVAuthorizationStatusAuthorized) {
            if (!layerLoaded) {
                BOOL loadResult = [self loadLayerFrameWithSelectedState:(self.flipButton.selected)];
                if (!loadResult) {
                    @throw NSLocalizedString(@"Cannot connect to video device.", nil);
                }
                layerLoaded = YES;
            }
        } else if (permissionStatus == AVAuthorizationStatusDenied) {
            self.title = NSLocalizedString(@"Access Denied", nil);
        } else if (permissionStatus == AVAuthorizationStatusRestricted) {
            self.title = NSLocalizedString(@"Access Restricted", nil);
        } else if (permissionStatus == AVAuthorizationStatusNotDetermined) {
            return fetchPermissionPromise;
        }
        if (permissionStatus == AVAuthorizationStatusRestricted ||
                permissionStatus == AVAuthorizationStatusDenied) {
            NSString *productName = uAppDefine(@"PRODUCT_NAME");
            @throw [NSString stringWithFormat:NSLocalizedString(@"Turn to \"Settings > Privacy > Camera\" and enable %@ to use your camera.", nil), productName];
        }
        return [PMKPromise promiseWithValue:status];
    };
    checkPermissionPromise
    .then(displayPermissionBlock)
    .then(displayPermissionBlock)
    .catch(^(NSError *error) {
        [self.maskView setHidden:YES];
        [self.scanLineAnimation performSelector:@selector(stopAnimating) withObject:nil afterDelay:0.2f];
        toastMessageWithDelay(self, [error localizedDescription], CGFLOAT_MAX);
    });
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    if (metadataObjects.count > 0) {
        AVMetadataMachineReadableCodeObject *metadataObject = metadataObjects[0];
        if (metadataObject.type == AVMetadataObjectTypeQRCode) {
            // TODO: use metadataObject.corners to draw code overlay
            NSString *stringValue = metadataObject.stringValue;
            if (stringValue.length > 0) {
                [self pauseScan];
                [self handleOutput:stringValue];
            }
        }
    }
}

#pragma mark - Scan & Recognize

- (NSString *)scanImage:(UIImage *)image {
    XXTE_START_IGNORE_PARTIAL
    if (@available(iOS 8.0, *)) {
        NSString *scannedResult = nil;
        CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:nil];
        NSArray *features = [detector featuresInImage:[CIImage imageWithCGImage:image.CGImage]];
        for (NSUInteger index = 0; index < features.count; index++) {
            CIQRCodeFeature *feature = features[index];
            scannedResult = feature.messageString;
            if (scannedResult) {
                break;
            }
        }
        return scannedResult;
    } else {
        return nil;
    }
    XXTE_END_IGNORE_PARTIAL
}

- (void)handleOutput:(NSString *)output {
    if (!output) return;
    
    if (@available(iOS 10.0, *)) {
        static UINotificationFeedbackGenerator *feedbackGenerator = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            feedbackGenerator = [[UINotificationFeedbackGenerator alloc] init];
        });
        [feedbackGenerator notificationOccurred:UINotificationFeedbackTypeSuccess];
    }

    // URL? (v2)
    NSURL *url = [NSURL URLWithString:output];
    if (url.scheme.length > 0 && [[UIApplication sharedApplication] canOpenURL:url]) {
        if (self.shouldConfirm == NO || [[url scheme] isEqualToString:@"xxt"] || [self isTrustedHost:[url host]])
        {
            [self alertView:nil openURL:url];
            return;
        }
        LGAlertView *alertView = [[LGAlertView alloc] initWithTitle:NSLocalizedString(@"Open URL", nil)
                                                            message:[NSString stringWithFormat:NSLocalizedString(@"Will open url: \n\"%@\", continue?", nil), output]
                                                              style:LGAlertViewStyleAlert
                                                       buttonTitles:nil
                                                  cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                             destructiveButtonTitle:NSLocalizedString(@"Continue", nil)
                                                           delegate:self];
        objc_setAssociatedObject(alertView, @selector(alertView:openURL:), url, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [alertView showAnimated];
        return;
    } // url finished

    // JSON? (v1)
    NSError *jsonError = nil;
    id jsonObject = [NSJSONSerialization JSONObjectWithData:[output dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&jsonError];
    if (!jsonError && jsonObject && [jsonObject isKindOfClass:[NSDictionary class]]) {
        if (_delegate && [_delegate respondsToSelector:@selector(scanViewController:jsonOperation:)]) {
            [_delegate scanViewController:self jsonOperation:jsonObject];
        }
        return;
    } // json finished

    // PLAIN TEXT
    {
        NSString *detailText = output;
        if (self.shouldConfirm == NO) {
            [self alertView:nil copyString:detailText];
            return;
        }
        LGAlertView *alertView = [[LGAlertView alloc] initWithTitle:NSLocalizedString(@"Text Content", nil)
                                                            message:detailText
                                                              style:LGAlertViewStyleAlert
                                                       buttonTitles:nil
                                                  cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                             destructiveButtonTitle:NSLocalizedString(@"Copy", nil)
                                                           delegate:self];
        objc_setAssociatedObject(alertView, @selector(alertView:copyString:), detailText, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [alertView showAnimated];
        return;
    } // plain finished
}

#pragma mark - LGAlertViewDelegate

- (void)alertViewCancelled:(LGAlertView *)alertView {
    [alertView dismissAnimated];
    [self performSelector:@selector(continueScan) withObject:nil afterDelay:.6f];
}

- (void)alertViewDestructed:(LGAlertView *)alertView {
    SEL selectors[] = {
            @selector(alertView:openURL:),
            @selector(alertView:copyString:)
    };
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    for (int i = 0; i < sizeof(selectors) / sizeof(SEL); i++) {
        SEL selector = selectors[i];
        id obj = objc_getAssociatedObject(alertView, selector);
        if (obj) {
            [self performSelector:selector withObject:alertView withObject:obj];
            break;
        }
    }
#pragma clang diagnostic pop
}

#pragma mark - Ending Actions

- (void)alertView:(LGAlertView *)alertView openURL:(NSURL *)url {
    [alertView dismissAnimated];
    if (_delegate && [_delegate respondsToSelector:@selector(scanViewController:urlOperation:)]) {
        [_delegate scanViewController:self urlOperation:url];
    }
}

- (void)alertView:(LGAlertView *)alertView copyString:(NSString *)detailText {
    [alertView dismissAnimated];
    if (_delegate && [_delegate respondsToSelector:@selector(scanViewController:textOperation:)]) {
        [_delegate scanViewController:self textOperation:detailText];
    }
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    @weakify(self);
    [picker dismissViewControllerAnimated:YES completion:^{
        @strongify(self);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self continueScan];
        });
    }];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *, id> *)mediaInfo {
    [picker dismissViewControllerAnimated:YES completion:nil];
    if ([[mediaInfo objectForKey:UIImagePickerControllerMediaType] isEqualToString:(NSString *) kUTTypeImage]) {
        UIImage *originalImage = [mediaInfo objectForKey:UIImagePickerControllerOriginalImage];
        UIViewController *blockVC = blockInteractions(self, YES);
        [PMKPromise promiseWithValue:@(YES)].then(^() {
            NSString *scannedResult = [self scanImage:originalImage];
            if (!scannedResult || scannedResult.length <= 0) {
                @throw NSLocalizedString(@"Cannot find QR Code in the image.", nil);
            }
            return scannedResult;
        }).then(^(NSString *scannedResult) {
            [self handleOutput:scannedResult];
        }).catch(^(NSError *scanError) {
            [self performSelector:@selector(showError:) withObject:scanError afterDelay:.2f];
        }).finally(^() {
            blockInteractions(blockVC, NO);
        });
    }
}

- (void)showError:(NSError *)error {
    LGAlertView *alertView = [[LGAlertView alloc] initWithTitle:NSLocalizedString(@"Scan Error", nil)
                                                        message:[error localizedDescription]
                                                          style:LGAlertViewStyleAlert
                                                   buttonTitles:nil
                                              cancelButtonTitle:NSLocalizedString(@"Retry", nil)
                                         destructiveButtonTitle:nil
                                                       delegate:self];
    [alertView showAnimated];
}

- (BOOL)isTrustedHost:(NSString *)host {
    NSArray <NSString *> *trustedHosts = uAppDefine(XXTETrustedHostsKey);
    return ([trustedHosts containsObject:host]);
}

#pragma mark - Notifications

- (void)handleEnterForeground:(NSNotification *)aNotification {
    [self reloadLightButtonStatus];
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [XXTEScanViewController dealloc]");
#endif
}

@end
