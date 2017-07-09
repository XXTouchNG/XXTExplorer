//
//  XXTEScanViewController.m
//  XXTExplorer
//
//  Created by Zheng on 09/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEScanViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "XXTEScanLineAnimation.h"
#import "XXTEDispatchDefines.h"
#import <PromiseKit/PromiseKit.h>
#import "UIView+XXTEToast.h"

@interface XXTEScanViewController () <AVCaptureMetadataOutputObjectsDelegate>
@property (nonatomic, strong) AVCaptureSession *scanSession;
@property (nonatomic, strong) AVCaptureDevice *scanDevice;
@property (nonatomic, strong) AVCaptureDeviceInput *scanInput;
@property (nonatomic, strong) AVCaptureMetadataOutput *scanOutput;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *scanLayer;

@property (nonatomic, strong) UIBarButtonItem *dismissItem;
@property (nonatomic, strong) UIBarButtonItem *albumItem;
@property (nonatomic, strong) UIImage *maskImage;
@property (nonatomic, strong) UIImageView *maskView;
@property (nonatomic, assign) CGRect cropRect;
@property (nonatomic, strong) XXTEScanLineAnimation *scanLineAnimation;

@property (nonatomic, assign) BOOL layerLoaded;

@end

@implementation XXTEScanViewController

#pragma mark - Styles

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (UIModalTransitionStyle)modalTransitionStyle {
    return UIModalTransitionStyleFlipHorizontal;
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.layerLoaded = NO;
    
    self.title = NSLocalizedString(@"Scan", nil);
    self.view.backgroundColor = [UIColor blackColor];
    self.edgesForExtendedLayout = UIRectEdgeAll;
    self.extendedLayoutIncludesOpaqueBars = YES;
    
    self.maskView.image = self.maskImage;
    [self.view addSubview:self.maskView];
    
    [self.navigationController.navigationBar setBackgroundImage:[[UIImage alloc] init] forBarMetrics:UIBarMetricsDefault];
    [self.navigationController.navigationBar setShadowImage:[[UIImage alloc] init]];
    [self.navigationController.navigationBar setBarStyle:UIBarStyleBlackTranslucent];
    self.navigationItem.leftBarButtonItem = self.dismissItem;
    self.navigationItem.rightBarButtonItem = self.albumItem;
    
    [self fetchVideoPermission];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self performSelector:@selector(startAnimation) withObject:nil afterDelay:0.2f];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self stopAnimation];
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
    if (self.scanSession && ![self.scanSession isRunning]) {
        [self.scanSession startRunning];
    }
}

- (void)loadLayerFrame {
    if (!self.layerLoaded) {
        self.layerLoaded = YES;
        self.scanLayer.frame = self.view.layer.bounds;
        [self.view.layer insertSublayer:self.scanLayer atIndex:0];
        [self.scanSession startRunning];
    }
}

#pragma mark - UIView Getters

- (AVCaptureSession *)scanSession {
    if (!_scanSession) {
        AVCaptureSession *scanSession = [[AVCaptureSession alloc] init];
        if ([scanSession canSetSessionPreset:AVCaptureSessionPresetHigh]) {
            [scanSession setSessionPreset:AVCaptureSessionPresetHigh];
        }
        if ([scanSession canAddInput:self.scanInput]) {
            [scanSession addInput:self.scanInput];
        }
        if ([scanSession canAddOutput:self.scanOutput]) {
            [scanSession addOutput:self.scanOutput];
        }
        if ([self.scanOutput.availableMetadataObjectTypes containsObject:AVMetadataObjectTypeQRCode]) {
            self.scanOutput.metadataObjectTypes = @[ AVMetadataObjectTypeQRCode ];
        }
        CGSize viewSize = self.view.bounds.size;
        self.scanOutput.rectOfInterest = CGRectMake(self.cropRect.origin.y / viewSize.height,
                                                    self.cropRect.origin.x / viewSize.width,
                                                    self.cropRect.size.height / viewSize.height,
                                                    self.cropRect.size.width / viewSize.width);
        _scanSession = scanSession;
    }
    return _scanSession;
}

- (AVCaptureDevice *)scanDevice {
    if (!_scanDevice) {
        AVCaptureDevice *scanDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        _scanDevice = scanDevice;
    }
    return _scanDevice;
}

- (AVCaptureDeviceInput *)scanInput {
    if (!_scanInput) {
        NSError *err = nil;
        AVCaptureDeviceInput *scanInput = [AVCaptureDeviceInput deviceInputWithDevice:self.scanDevice error:&err];
        if (!scanInput) {
            // NSLocalizedString(@"Cannot connect to video device", nil);
        }
        _scanInput = scanInput;
    }
    return _scanInput;
}

- (AVCaptureMetadataOutput *)scanOutput {
    if (!_scanOutput) {
        AVCaptureMetadataOutput *scanOutput = [[AVCaptureMetadataOutput alloc] init];
        [scanOutput setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
        _scanOutput = scanOutput;
    }
    return _scanOutput;
}

- (AVCaptureVideoPreviewLayer *)scanLayer {
    if (!_scanLayer) {
        AVCaptureVideoPreviewLayer *scanLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.scanSession];
        scanLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        _scanLayer = scanLayer;
    }
    return _scanLayer;
}

- (UIBarButtonItem *)dismissItem {
    if (!_dismissItem) {
        UIBarButtonItem *dismissItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"XXTEScanDismissItemImage"] style:UIBarButtonItemStylePlain target:self action:@selector(dismissScanViewController:)];
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

- (UIImage *)maskImage {
    if (!_maskImage) {
        
        CGSize oldSize = self.view.bounds.size;
        CGFloat maxLength = MAX(oldSize.width, oldSize.height);
        CGFloat minLength = MIN(oldSize.width, oldSize.height);
        CGSize size = CGSizeMake(maxLength, maxLength);
        CGFloat rectWidth = minLength / 3 * 2;
        
        CGPoint pA = CGPointMake(size.width / 2 - rectWidth / 2, size.height / 2 - rectWidth / 2);
        CGPoint pD = CGPointMake(size.width / 2 + rectWidth / 2, size.height / 2 + rectWidth / 2);
        
        // Begin Context
        UIGraphicsBeginImageContextWithOptions(size, NO, [[UIScreen mainScreen] scale]);
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
        CGContextSetStrokeColorWithColor(ctx, XXTE_COLOR.CGColor);
        
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
        UIImage* returnImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        _maskImage = returnImage;
    }
    return _maskImage;
}

- (CGRect)cropRect {
    CGSize oldSize = self.view.bounds.size;
    CGFloat minLength = MIN(oldSize.width, oldSize.height);
    CGFloat rectWidth = minLength / 3 * 2;
    return CGRectMake(oldSize.width / 2 - rectWidth / 2, oldSize.height / 2 - rectWidth / 2, rectWidth, rectWidth);
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

#pragma mark - UIControl Actions

- (void)dismissScanViewController:(UIBarButtonItem *)sender {
    if (self.scanSession) {
        [self.scanSession stopRunning];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)albumItemTapped:(UIBarButtonItem *)sender {
    
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
    id (^ displayPermissionBlock)(NSNumber *) = ^(NSNumber *status) {
        AVAuthorizationStatus permissionStatus = (AVAuthorizationStatus) [status integerValue];
        if (permissionStatus == AVAuthorizationStatusAuthorized) {
            [self loadLayerFrame];
        } else if (permissionStatus == AVAuthorizationStatusDenied) {
            self.title = NSLocalizedString(@"Access Denied", nil);
        } else if (permissionStatus == AVAuthorizationStatusRestricted) {
            self.title = NSLocalizedString(@"Access Restricted", nil);
        } else if (permissionStatus == AVAuthorizationStatusNotDetermined) {
            return fetchPermissionPromise;
        }
        if (permissionStatus == AVAuthorizationStatusRestricted ||
            permissionStatus == AVAuthorizationStatusDenied) {
            @throw NSLocalizedString(@"Turn to \"Settings > Privacy > Camera\" and enable XXTouch to use your camera.", nil);
        }
        return [PMKPromise promiseWithValue:status];
    };
    checkPermissionPromise.then(displayPermissionBlock).then(displayPermissionBlock)
    .catch(^(NSError *error) {
        [self.maskView setHidden:YES];
        [self.scanLineAnimation performSelector:@selector(stopAnimating) withObject:nil afterDelay:0.2f];
        [self.navigationController.view makeToast:[error localizedDescription] duration:CGFLOAT_MAX position:XXTEToastPositionCenter];
    });
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    if (metadataObjects.count > 0) {
        AVMetadataMachineReadableCodeObject * metadataObject = metadataObjects[0];
        if (self.scanSession && [self.scanSession isRunning]) {
            [self.scanSession stopRunning];
        }
        [self handleOutput:metadataObject.stringValue];
    }
}

#pragma mark - Scan & Recognize

- (NSString *)scanImage:(UIImage *)image {
    NSString *scannedResult = nil;
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:@{ CIDetectorAccuracy : CIDetectorAccuracyHigh }];
    NSArray *features = [detector featuresInImage:[CIImage imageWithCGImage:image.CGImage]];
    for (NSUInteger index = 0; index < features.count; index ++) {
        CIQRCodeFeature *feature = features[index];
        scannedResult = feature.messageString;
        if (scannedResult) {
            break;
        }
    }
    return scannedResult;
}

- (void)handleOutput:(NSString *)output {
    if (!output) return;
}

@end
