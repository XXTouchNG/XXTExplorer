//
//  XXTEScanViewController.m
//  XXTExplorer
//
//  Created by Zheng on 09/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <objc/runtime.h>
#import <objc/message.h>
#import "XXTEScanViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "XXTEScanLineAnimation.h"
#import "XXTEDispatchDefines.h"
#import <PromiseKit/PromiseKit.h>
#import "UIView+XXTEToast.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "XXTEUserInterfaceDefines.h"
#import <LGAlertView/LGAlertView.h>
#import "XXTEImagePickerController.h"
#import "XXTENotificationCenterDefines.h"
#import "XXTEAppDefines.h"

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
//@property(nonatomic, strong) UIVisualEffectView *visualEffectView;

@property(nonatomic, assign) BOOL layerLoaded;

@end

@implementation XXTEScanViewController {
    BOOL firstTimeLoaded;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context)
     {
         [self reloadCaptureSceneWithSize:size];
//         self.visualEffectView.alpha = 1.f;
     } completion:^(id<UIViewControllerTransitionCoordinatorContext> context)
     {
//         self.visualEffectView.alpha = 0.f;
     }];
    
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}

#pragma mark - Styles

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.layerLoaded = NO;

    self.title = NSLocalizedString(@"Scan", nil);
    self.view.backgroundColor = [UIColor blackColor];
    self.edgesForExtendedLayout = UIRectEdgeAll;
    self.extendedLayoutIncludesOpaqueBars = YES;

    [self.view addSubview:self.maskView];
    
    [self.navigationController.navigationBar setBackgroundImage:[[UIImage alloc] init] forBarMetrics:UIBarMetricsDefault];
    [self.navigationController.navigationBar setShadowImage:[[UIImage alloc] init]];
    [self.navigationController.navigationBar setBarStyle:UIBarStyleBlackTranslucent];
    self.navigationItem.leftBarButtonItem = self.dismissItem;
    self.navigationItem.rightBarButtonItem = self.albumItem;

    [self fetchVideoPermission];
    [self reloadCaptureSceneWithSize:self.view.bounds.size];
}

- (void)reloadCaptureSceneWithSize:(CGSize)toSize {

    CGFloat scale = [[UIScreen mainScreen] scale];

    CGSize oldSize = toSize;
    CGFloat maxLength = MAX(oldSize.width, oldSize.height);
    CGFloat minLength = MIN(oldSize.width, oldSize.height);
    CGSize size = CGSizeMake(maxLength, maxLength);
    CGFloat rectWidth = minLength / 3 * 2;

    CGPoint pA = CGPointMake(size.width / 2 - rectWidth / 2, size.height / 2 - rectWidth / 2);
    CGPoint pD = CGPointMake(size.width / 2 + rectWidth / 2, size.height / 2 + rectWidth / 2);

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
    CGContextSetStrokeColorWithColor(ctx, [XXTE_COLOR colorWithAlphaComponent:.75f].CGColor);

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

    AVCaptureConnection *previewLayerConnection = self.scanLayer.connection;
    if ([previewLayerConnection isVideoOrientationSupported])
        [previewLayerConnection setVideoOrientation:(AVCaptureVideoOrientation)[[UIApplication sharedApplication] statusBarOrientation]];
    self.scanLineAnimation.animationRect = self.cropRect;

    self.scanLayer.frame = self.view.layer.bounds;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    {
        [self performSelector:@selector(startAnimation) withObject:nil afterDelay:0.2f];
    }
    if (!firstTimeLoaded) {
        firstTimeLoaded = YES;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    {
        self.maskView.image = nil;
        [self stopAnimation];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (firstTimeLoaded) {
        [self reloadCaptureSceneWithSize:self.view.bounds.size];
    }
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
    if (self.scanSession && ![self.scanSession isRunning]) {
        [self.scanSession startRunning];
    }
}

- (void)pauseScan {
    [self stopAnimation];
    if (self.scanSession && [self.scanSession isRunning]) {
        [self.scanSession stopRunning];
    }
}

- (BOOL)loadLayerFrame {
    if (!self.layerLoaded) {
        if (!self.scanLayer) {
            return NO;
        }
        self.layerLoaded = YES;
        self.scanLayer.frame = self.view.layer.bounds;
        [self.view.layer insertSublayer:self.scanLayer atIndex:0];
        [self.scanSession startRunning];
    }
    return YES;
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
        } else {
            return nil;
        }
        if ([scanSession canAddOutput:self.scanOutput]) {
            [scanSession addOutput:self.scanOutput];
        } else {
            return nil;
        }
        if ([self.scanOutput.availableMetadataObjectTypes containsObject:AVMetadataObjectTypeQRCode]) {
            self.scanOutput.metadataObjectTypes = @[AVMetadataObjectTypeQRCode];
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
        if (!self.scanSession) {
            return nil;
        }
        AVCaptureVideoPreviewLayer *scanLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.scanSession];
        scanLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        _scanLayer = scanLayer;
    }
    return _scanLayer;
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

//- (UIVisualEffectView *)visualEffectView {
//    if (!_visualEffectView) {
//        UIBlurEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
//        UIVisualEffectView *effectView = [[UIVisualEffectView alloc] initWithEffect:effect];
//        effectView.alpha = 0.f;
//        _visualEffectView = effectView;
//    }
//    return _visualEffectView;
//}

#pragma mark - UIControl Actions

- (void)dismissScanViewController:(UIBarButtonItem *)sender {
    if (self.scanSession) {
        [self.scanSession stopRunning];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)albumItemTapped:(UIBarButtonItem *)sender {
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
    imagePicker.navigationBar.barTintColor = XXTE_COLOR;
    imagePicker.navigationBar.tintColor = [UIColor whiteColor];
    imagePicker.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor]};
    imagePicker.modalPresentationStyle = UIModalPresentationCurrentContext;
    imagePicker.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self.navigationController presentViewController:imagePicker animated:YES completion:nil];
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
            BOOL loadResult = [self loadLayerFrame];
            if (!loadResult) {
                @throw NSLocalizedString(@"Cannot connect to video device.", nil);
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
        AVMetadataMachineReadableCodeObject *metadataObject = metadataObjects[0];
        NSString *stringValue = metadataObject.stringValue;
        if (stringValue.length > 0) {
            [self pauseScan];
            [self handleOutput:stringValue];
        }
    }
}

#pragma mark - Scan & Recognize

- (NSString *)scanImage:(UIImage *)image {
    NSString *scannedResult = nil;
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:@{CIDetectorAccuracy: CIDetectorAccuracyHigh}];
    NSArray *features = [detector featuresInImage:[CIImage imageWithCGImage:image.CGImage]];
    for (NSUInteger index = 0; index < features.count; index++) {
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

    // URL? (v2)
    NSURL *url = [NSURL URLWithString:output];
    if (url && [[UIApplication sharedApplication] canOpenURL:url]) {
        if ([[url scheme] isEqualToString:@"xxt"]) {
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
    [picker dismissViewControllerAnimated:YES completion:^{
        [self performSelector:@selector(continueScan) withObject:nil afterDelay:.6f];
    }];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *, id> *)mediaInfo {
    [picker dismissViewControllerAnimated:YES completion:nil];
    if ([[mediaInfo objectForKey:UIImagePickerControllerMediaType] isEqualToString:(NSString *) kUTTypeImage]) {
        UIImage *originalImage = [mediaInfo objectForKey:UIImagePickerControllerOriginalImage];
        blockUserInteractions(self, YES);
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
            blockUserInteractions(self, NO);
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

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [XXTEScanViewController dealloc]");
#endif
}

@end
