//
//  XXTRectanglePicker.m
//  XXTouchApp
//
//  Created by Zheng on 18/10/2016.
//  Copyright © 2016 Zheng. All rights reserved.
//

#import "XXTPixelCropView.h"
#import "XXTRectanglePicker.h"
#import "XXTImagePickerController.h"
#import "XXTPixelPlaceholderView.h"
#import "XXTPickerFactory.h"
#import "UIColor+hexValue.h"
#import "UIColor+inverseColor.h"
#import "XXTPositionColorModel.h"

@interface XXTRectanglePicker () <XXTImagePickerControllerDelegate, UIGestureRecognizerDelegate, UIAlertViewDelegate, XXTPixelCropViewDelegate>
@property(nonatomic, strong) XXTPixelPlaceholderView *placeholderView;
@property(nonatomic, assign) BOOL locked;
@property(nonatomic, strong) UIButton *lockButton;
@property(nonatomic, copy) NSString *tempImagePath;
@property(nonatomic, strong) XXTPixelCropView *cropView;
@property(nonatomic, strong) UIToolbar *cropToolbar;
@end

@implementation XXTRectanglePicker {
    XXTPickerTask *_pickerTask;
    NSAttributedString *_pickerSubtitle;
    NSString *_pickerResult;
    UIImage *_selectedImage;
}

@synthesize pickerTask = _pickerTask;

#pragma mark - Status Bar

- (UIStatusBarStyle)preferredStatusBarStyle {
    if ([self isNavigationBarHidden]) {
        return UIStatusBarStyleDefault;
    }
    return UIStatusBarStyleLightContent;
}

- (BOOL)prefersStatusBarHidden {
    if ([self isNavigationBarHidden]) {
        return YES;
    }
    return [super prefersStatusBarHidden];
}

#pragma mark - Rotate

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                duration:(NSTimeInterval)duration {
    if (!self.selectedImage) {
        return;
    }
    [self setSelectedImage:self.selectedImage];
}

#pragma mark - View & Constraints

- (void)viewDidLoad {
    [super viewDidLoad];

    [self setSelectedImage:nil];
    [self loadImageFromCache];

    [self.pickerTask nextStep];
    UIBarButtonItem *rightItem = NULL;
    if ([self.pickerTask taskFinished]) {
        rightItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(taskFinished:)];
    } else {
        rightItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Next", @"XXTPickerCollection", [XXTPickerFactory bundle], nil) style:UIBarButtonItemStylePlain target:self action:@selector(taskNextStep:)];
    }
    self.navigationItem.rightBarButtonItem = rightItem;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateTipsFromSelectedStatus];
}

- (void)loadView {
    UIView *contentView = [[UIView alloc] init];
    contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    contentView.backgroundColor = [UIColor whiteColor];
    self.view = contentView;

    XXTPixelCropView *cropView = [[XXTPixelCropView alloc] initWithFrame:contentView.bounds andType:(kXXTPixelCropViewType) [[self class] cropViewType]];
    cropView.hidden = YES;
    cropView.delegate = self;
    cropView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    cropView.allowsRotate = NO;
    [contentView insertSubview:cropView atIndex:0];
    self.cropView = cropView;

    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                 action:@selector(tripleFingerTapped:)];
    tapGesture.numberOfTapsRequired = 1;
    tapGesture.numberOfTouchesRequired = 3;
    tapGesture.delegate = self;
    [self.cropView addGestureRecognizer:tapGesture];

    [self.view addSubview:self.cropToolbar];
    [self.view addSubview:self.placeholderView];
}

#pragma mark - Image Cache

- (void)loadImageFromCache {
    if ([[NSFileManager defaultManager] isReadableFileAtPath:self.tempImagePath]) {
        NSError *err = nil;
        NSData *imageData = [NSData dataWithContentsOfFile:self.tempImagePath
                                                   options:NSDataReadingMappedIfSafe
                                                     error:&err];
        if (imageData) {
            UIImage *image = [UIImage imageWithData:imageData];
            if (image) {
                [self setSelectedImage:image];
            } else {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Error", @"XXTPickerCollection", [XXTPickerFactory bundle], nil)
                                                                    message:NSLocalizedStringFromTableInBundle(@"Cannot read image data, invalid image?", @"XXTPickerCollection", [XXTPickerFactory bundle], nil)
                                                                   delegate:self
                                                          cancelButtonTitle:NSLocalizedStringFromTableInBundle(@"Cancel", @"XXTPickerCollection", [XXTPickerFactory bundle], nil)
                                                          otherButtonTitles:nil];
                [alertView show];
            }
        } else if (err) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Error", @"XXTPickerCollection", [XXTPickerFactory bundle], nil)
                                                                message:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Cannot load image from cache: %@", @"XXTPickerCollection", [XXTPickerFactory bundle], nil), [err localizedDescription]]
                                                               delegate:self
                                                      cancelButtonTitle:NSLocalizedStringFromTableInBundle(@"Cancel", @"XXTPickerCollection", [XXTPickerFactory bundle], nil)
                                                      otherButtonTitles:nil];
            [alertView show];
        }
    }
}

#pragma mark - Getter

+ (XXTPixelPickerType)cropViewType {
    return XXTPixelPickerTypeRect;
}

- (XXTPixelPlaceholderView *)placeholderView {
    if (!_placeholderView) {
        XXTPixelPlaceholderView *placeholderView = [[XXTPixelPlaceholderView alloc] initWithFrame:self.view.bounds];
        placeholderView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                     action:@selector(placeholderViewTapped:)];
        [placeholderView addGestureRecognizer:tapGesture];
        _placeholderView = placeholderView;
    }
    return _placeholderView;
}

- (NSString *)tempImagePath {
    if (!_tempImagePath) {
        NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
        NSString *tempImagePath = [cachePath stringByAppendingPathComponent:@"kXXTImagePickerCacheImage.png"];
        _tempImagePath = tempImagePath;
    }
    return _tempImagePath;
}

- (UIToolbar *)cropToolbar {
    if (!_cropToolbar) {
        UIToolbar *cropToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 44)];
        cropToolbar.hidden = YES;
        cropToolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
        cropToolbar.backgroundColor = [UIColor clearColor];
        [cropToolbar setBackgroundColor:[UIColor colorWithWhite:1.f alpha:.75f]];

        NSBundle *frameworkBundle = [XXTPickerFactory bundle];
        UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        UIBarButtonItem *graphBtn = [[UIBarButtonItem alloc] initWithImage:[[UIImage imageWithContentsOfFile:[frameworkBundle pathForResource:@"xxt-add-box" ofType:@"png"]] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] style:UIBarButtonItemStylePlain target:self action:@selector(changeImageButtonTapped:)];
        UIBarButtonItem *toLeftBtn = [[UIBarButtonItem alloc] initWithImage:[[UIImage imageWithContentsOfFile:[frameworkBundle pathForResource:@"xxt-rotate-left" ofType:@"png"]] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] style:UIBarButtonItemStylePlain target:self action:@selector(rotateToLeftButtonTapped:)];
        UIBarButtonItem *toRightBtn = [[UIBarButtonItem alloc] initWithImage:[[UIImage imageWithContentsOfFile:[frameworkBundle pathForResource:@"xxt-rotate-right" ofType:@"png"]] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] style:UIBarButtonItemStylePlain target:self action:@selector(rotateToRightButtonTapped:)];
        UIBarButtonItem *resetBtn = [[UIBarButtonItem alloc] initWithImage:[[UIImage imageWithContentsOfFile:[frameworkBundle pathForResource:@"xxt-refresh" ofType:@"png"]] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] style:UIBarButtonItemStylePlain target:self action:@selector(resetButtonTapped:)];
        UIBarButtonItem *trashBtn = [[UIBarButtonItem alloc] initWithImage:[[UIImage imageWithContentsOfFile:[frameworkBundle pathForResource:@"xxt-clear" ofType:@"png"]] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] style:UIBarButtonItemStylePlain target:self action:@selector(trashButtonTapped:)];

        UIButton *lockButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 44, 30)];
        [lockButton setImage:[UIImage imageWithContentsOfFile:[frameworkBundle pathForResource:@"xxt-lock" ofType:@"png"]] forState:UIControlStateNormal];
        [lockButton setImage:[UIImage imageWithContentsOfFile:[frameworkBundle pathForResource:@"xxt-unlock" ofType:@"png"]] forState:UIControlStateSelected];
        [lockButton addTarget:self
                       action:@selector(lockButtonTapped:)
             forControlEvents:UIControlEventTouchUpInside];
        _lockButton = lockButton;
        UIBarButtonItem *lockBtn = [[UIBarButtonItem alloc] initWithCustomView:lockButton];

        [cropToolbar setItems:@[graphBtn, flexibleSpace, trashBtn, flexibleSpace, toLeftBtn, flexibleSpace, toRightBtn, flexibleSpace, resetBtn, flexibleSpace, lockBtn]];

        _cropToolbar = cropToolbar;
    }
    return _cropToolbar;
}

#pragma mark - Setter

- (UIImage *)selectedImage {
    return _selectedImage;
}

- (void)setSelectedImage:(UIImage *)selectedImage {
    _selectedImage = selectedImage;
    if (!selectedImage) {
        self.cropToolbar.hidden = YES;
        self.cropView.hidden = YES;
        self.placeholderView.hidden = NO;
    } else {
        self.cropView.image = selectedImage;
        self.cropToolbar.hidden = NO;
        self.cropView.hidden = NO;
        self.placeholderView.hidden = YES;
    }
    [self updateTipsFromSelectedStatus];
}

- (void)updateTipsFromSelectedStatus {
    if (!self.selectedImage) {
        [self updateSubtitle:NSLocalizedStringFromTableInBundle(@"Select an image from album.", @"XXTPickerCollection", [XXTPickerFactory bundle], nil)];
    } else {
        switch ([[self class] cropViewType]) {
            case XXTPixelPickerTypeRect:
                [self updateSubtitle:NSLocalizedStringFromTableInBundle(@"Select a rectangle area by dragging its corners.", @"XXTPickerCollection", [XXTPickerFactory bundle], nil)];
                break;
            case XXTPixelPickerTypePosition:
            case XXTPixelPickerTypePositionColor:
                [self updateSubtitle:NSLocalizedStringFromTableInBundle(@"Select a position by tapping on image.", @"XXTPickerCollection", [XXTPickerFactory bundle], nil)];
                break;
            case XXTPixelPickerTypeColor:
                [self updateSubtitle:NSLocalizedStringFromTableInBundle(@"Select a color by tapping on image.", @"XXTPickerCollection", [XXTPickerFactory bundle], nil)];
                break;
            case XXTPixelPickerTypeMultiplePositionColor:
                [self updateSubtitle:NSLocalizedStringFromTableInBundle(@"Select several positions by tapping on image.", @"XXTPickerCollection", [XXTPickerFactory bundle], nil)];
                break;
        }
    }
}

#pragma mark - Tap Gestures

- (void)placeholderViewTapped:(id)sender {
    NSBundle *frameworkBundle = [XXTPickerFactory bundle];
    XXTImagePickerController *imagePickerController = [[XXTImagePickerController alloc] initWithNibName:@"XXTImagePickerController" bundle:frameworkBundle];
    imagePickerController.delegate = self;
    imagePickerController.nResultType = XXT_PICKER_RESULT_UIIMAGE;
    imagePickerController.nMaxCount = 1;
    imagePickerController.nColumnCount = 4;
    [self presentViewController:imagePickerController animated:YES completion:nil];
}

- (void)tripleFingerTapped:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        [self updateSubtitle:NSLocalizedStringFromTableInBundle(@"Triple touches to enter/exit fullscreen.", @"XXTPickerCollection", [XXTPickerFactory bundle], nil)];
        [self setNavigationBarHidden:![self isNavigationBarHidden] animated:YES];
    }
}

- (BOOL)isNavigationBarHidden {
    return [self.navigationController isNavigationBarHidden];
}

- (void)setNavigationBarHidden:(BOOL)hidden animated:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:hidden animated:animated];
}

#pragma mark - Toolbar Actions

- (void)changeImageButtonTapped:(UIBarButtonItem *)sender {
    [self placeholderViewTapped:sender];
}

- (UIImage *)processImage:(UIImage *)image byRotate:(CGFloat)radians fitSize:(BOOL)fitSize {
    size_t width = (size_t) CGImageGetWidth(image.CGImage);
    size_t height = (size_t) CGImageGetHeight(image.CGImage);
    CGRect newRect = CGRectApplyAffineTransform(CGRectMake(0.f, 0.f, width, height),
            fitSize ? CGAffineTransformMakeRotation(radians) : CGAffineTransformIdentity);

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL,
            (size_t) newRect.size.width,
            (size_t) newRect.size.height,
            8,
            (size_t) newRect.size.width * 4,
            colorSpace,
            kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst);
    CGColorSpaceRelease(colorSpace);
    if (!context) return nil;

    CGContextSetShouldAntialias(context, true);
    CGContextSetAllowsAntialiasing(context, true);
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);

    CGContextTranslateCTM(context, (CGFloat) +(newRect.size.width * 0.5), (CGFloat) +(newRect.size.height * 0.5));
    CGContextRotateCTM(context, radians);

    CGContextDrawImage(context, CGRectMake((CGFloat) -(width * 0.5), (CGFloat) -(height * 0.5), width, height), image.CGImage);
    CGImageRef imgRef = CGBitmapContextCreateImage(context);
    UIImage *img = [UIImage imageWithCGImage:imgRef scale:image.scale orientation:image.imageOrientation];
    CGImageRelease(imgRef);
    CGContextRelease(context);
    return img;
}

- (void)rotateToLeftButtonTapped:(UIBarButtonItem *)sender {
    if (!_selectedImage) return;
    [self setSelectedImage:[self processImage:self.selectedImage byRotate:(CGFloat) (90 * M_PI / 180) fitSize:YES]];
}

- (void)rotateToRightButtonTapped:(UIBarButtonItem *)sender {
    if (!_selectedImage) return;
    [self setSelectedImage:[self processImage:self.selectedImage byRotate:(CGFloat) (-90 * M_PI / 180) fitSize:YES]];
}

- (void)resetButtonTapped:(UIBarButtonItem *)sender {
    if (!_selectedImage || self.locked) return;
    if ([self.cropView userHasModifiedCropArea]) {
        [self.cropView resetCropRectAnimated:NO];
        [self updateSubtitle:NSLocalizedStringFromTableInBundle(@"Canvas reset.", @"XXTPickerCollection", [XXTPickerFactory bundle], nil)];
    }
}

- (void)lockButtonTapped:(id)sender {
    if (!_selectedImage) return;
    self.locked = self.lockButton.isSelected;
    if (self.locked) {
        self.locked = NO;
        self.cropView.allowsOperation = YES;
        self.lockButton.selected = NO;
        [self updateSubtitle:NSLocalizedStringFromTableInBundle(@"Canvas unlocked.", @"XXTPickerCollection", [XXTPickerFactory bundle], nil)];
    } else {
        self.locked = YES;
        self.cropView.allowsOperation = NO;
        self.lockButton.selected = YES;
        [self updateSubtitle:NSLocalizedStringFromTableInBundle(@"Canvas locked, it cannot be moved or zoomed.", @"XXTPickerCollection", [XXTPickerFactory bundle], nil)];
    }
}

- (void)trashButtonTapped:(id)sender {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Confirm", @"XXTPickerCollection", [XXTPickerFactory bundle], nil)
                                                        message:NSLocalizedStringFromTableInBundle(@"Discard all changes and reset the canvas?", @"XXTPickerCollection", [XXTPickerFactory bundle], nil)
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedStringFromTableInBundle(@"Cancel", @"XXTPickerCollection", [XXTPickerFactory bundle], nil)
                                              otherButtonTitles:NSLocalizedStringFromTableInBundle(@"Yes", @"XXTPickerCollection", [XXTPickerFactory bundle], nil), nil];
    [alertView show];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {

    } else if (buttonIndex == 1) {
        _pickerResult = nil;
        [self setNavigationBarHidden:NO animated:YES];
        [self cleanCanvas];
    }
}

#pragma mark - UIGestureRecognizerDelegate
#pragma mark - XXImagePickerControllerDelegate

- (void)didCancelImagePickerController:(XXTImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)didSelectPhotosFromImagePickerController:(XXTImagePickerController *)picker
                                          result:(NSArray *)aSelected {
    [picker dismissViewControllerAnimated:YES completion:nil];
    if (!aSelected || aSelected.count == 0) {
        [self cleanCanvas];
        return;
    }
    NSError *err = nil;
    NSData *imageData = UIImagePNGRepresentation(aSelected[0]);
    BOOL result = [imageData writeToFile:self.tempImagePath
                                 options:NSDataWritingAtomic
                                   error:&err];
    if (!result) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Error", @"XXTPickerCollection", [XXTPickerFactory bundle], nil)
                                                            message:[err localizedDescription]
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedStringFromTableInBundle(@"Cancel", @"XXTPickerCollection", [XXTPickerFactory bundle], nil)
                                                  otherButtonTitles:nil];
        [alertView show];
    }
    _pickerResult = nil;
    [self setSelectedImage:aSelected[0]];
}

- (void)cleanCanvas {
    [self setSelectedImage:nil];
    NSError *err = nil;
    BOOL result = [[NSFileManager defaultManager] removeItemAtPath:self.tempImagePath error:&err];
    if (!result) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Error", @"XXTPickerCollection", [XXTPickerFactory bundle], nil)
                                                            message:[err localizedDescription]
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedStringFromTableInBundle(@"Cancel", @"XXTPickerCollection", [XXTPickerFactory bundle], nil)
                                                  otherButtonTitles:nil];
        [alertView show];
    }
}

#pragma mark - XXTBasePicker

- (NSString *)title {
    switch ([[self class] cropViewType]) {
        case XXTPixelPickerTypeRect:
            return NSLocalizedStringFromTableInBundle(@"Rectangle", @"XXTPickerCollection", [XXTPickerFactory bundle], nil);
        case XXTPixelPickerTypePosition:
            return NSLocalizedStringFromTableInBundle(@"Position", @"XXTPickerCollection", [XXTPickerFactory bundle], nil);
        case XXTPixelPickerTypeColor:
            return NSLocalizedStringFromTableInBundle(@"Color", @"XXTPickerCollection", [XXTPickerFactory bundle], nil);
        case XXTPixelPickerTypePositionColor:
            return NSLocalizedStringFromTableInBundle(@"Position & Color", @"XXTPickerCollection", [XXTPickerFactory bundle], nil);
        case XXTPixelPickerTypeMultiplePositionColor:
            return NSLocalizedStringFromTableInBundle(@"Position & Color", @"XXTPickerCollection", [XXTPickerFactory bundle], nil);
    }
    return @"";
}

+ (NSString *)pickerKeyword {
    switch ([[self class] cropViewType]) {
        case XXTPixelPickerTypeRect:
            return @"@rect@";
        case XXTPixelPickerTypePosition:
            return @"@pos@";
        case XXTPixelPickerTypeColor:
            return @"@color@";
        case XXTPixelPickerTypePositionColor:
            return @"@poscolor@";
        case XXTPixelPickerTypeMultiplePositionColor:
            return @"@poscolors@";
    }
    return nil;
}

- (NSString *)pickerResult {
    if (!_pickerResult) {
        switch ([[self class] cropViewType]) {
            case XXTPixelPickerTypeRect:
                return @"0, 0, 0, 0";
            case XXTPixelPickerTypePosition:
                return @"0, 0";
            case XXTPixelPickerTypeColor:
                return @"0x000000";
            case XXTPixelPickerTypePositionColor:
                return @"0, 0, 0x000000";
            case XXTPixelPickerTypeMultiplePositionColor:
                return @"{\n\t\n}";
        }
    }
    return _pickerResult;
}

- (NSAttributedString *)pickerAttributedSubtitle {
    return _pickerSubtitle;
}

#pragma mark - Task Operations

- (void)taskFinished:(UIBarButtonItem *)sender {
    [self.pickerFactory performFinished:self];
}

- (void)taskNextStep:(UIBarButtonItem *)sender {
    [self.pickerFactory performNextStep:self];
}

- (void)updateSubtitle:(NSString *)subtitle {
    _pickerSubtitle = [[NSAttributedString alloc] initWithString:subtitle
                                                      attributes:@{
                                                              NSFontAttributeName: [UIFont fontWithName:@"CourierNewPSMT" size:12.f],
                                                              NSForegroundColorAttributeName: [UIColor blackColor],
                                                      }];
    [self.pickerFactory performUpdateStep:self];
}

- (void)updatedAttributedSubtitle:(NSAttributedString *)subtitle {
    _pickerSubtitle = subtitle;
    [self.pickerFactory performUpdateStep:self];
}

#pragma mark - XXTPixelCropViewDelegate

- (void)cropView:(XXTPixelCropView *)crop shouldEnterFullscreen:(BOOL)fullscreen {
    [self updateSubtitle:NSLocalizedStringFromTableInBundle(@"Tap blank area to enter/exit fullscreen.", @"XXTPickerCollection", [XXTPickerFactory bundle], nil)];
    [self setNavigationBarHidden:fullscreen animated:YES];
}

- (BOOL)cropViewFullscreen:(XXTPixelCropView *)crop {
    return [self isNavigationBarHidden];
}

- (void)cropView:(XXTPixelCropView *)crop selectValueUpdated:(id)selectedValue {
    XXTPixelPickerType type = [[self class] cropViewType];
    if (type == kXXTPixelCropViewTypeRect) {
        NSAssert([selectedValue isKindOfClass:[NSValue class]], @"type == kXXTPixelCropViewTypeRect");
        CGRect cropRect = [selectedValue CGRectValue];
        NSString *rectFormat = @"%d, %d, %d, %d";
        _pickerResult = [NSString stringWithFormat:rectFormat,
                                                   (int) cropRect.origin.x,
                                                   (int) cropRect.origin.y,
                                                   (int) cropRect.origin.x + (int) cropRect.size.width,
                                                   (int) cropRect.origin.y + (int) cropRect.size.height];
        NSString *previewFormat = @"(x1, y1), (x2, y2) = (%d, %d), (%d, %d)";
        NSString *previewString = [NSString stringWithFormat:previewFormat,
                                                             (int) cropRect.origin.x,
                                                             (int) cropRect.origin.y,
                                                             (int) cropRect.origin.x + (int) cropRect.size.width,
                                                             (int) cropRect.origin.y + (int) cropRect.size.height];
        [self updateSubtitle:previewString];
    } else if (type == kXXTPixelCropViewTypeColor) {
        NSAssert([selectedValue isKindOfClass:[UIColor class]], @"type == kXXTPixelCropViewTypeColor");
        UIColor *selectedColor = selectedValue;
        if (!selectedColor) {
            selectedColor = [UIColor blackColor];
        }
        NSString *colorFormat = @"0x%@";
        NSString *selectedHex = [selectedColor hexStringWithAlpha:NO];
        _pickerResult = [NSString stringWithFormat:colorFormat, selectedHex];
        NSString *previewFormat = @"(r%d, g%d, b%d) ";
        CGFloat r = 0, g = 0, b = 0, a = 0;
        [selectedColor getRed:&r green:&g blue:&b alpha:&a];
        NSString *previewString = [NSString stringWithFormat:previewFormat, (int) (r * 255.f), (int) (g * 255.f), (int) (b * 255.f)];
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:previewString
                                                                                             attributes:@{
                                                                                                     NSFontAttributeName: [UIFont fontWithName:@"CourierNewPSMT" size:12.f],
                                                                                                     NSForegroundColorAttributeName: [UIColor blackColor]
                                                                                             }];
        NSString *colorPreview = [NSString stringWithFormat:@"(■ 0x%@)", selectedHex];
        NSAttributedString *colorAttributedPreview = [[NSMutableAttributedString alloc] initWithString:colorPreview
                                                                                            attributes:@{
                                                                                                    NSFontAttributeName: [UIFont fontWithName:@"CourierNewPS-BoldMT" size:12.f],
                                                                                                    NSForegroundColorAttributeName: selectedColor,
                                                                                                    NSBackgroundColorAttributeName: [selectedColor inverseColor]
                                                                                            }];
        [attributedString appendAttributedString:colorAttributedPreview];
        [self updatedAttributedSubtitle:[attributedString copy]];
    } else if (type == kXXTPixelCropViewTypePosition) {
        NSAssert([selectedValue isKindOfClass:[NSValue class]], @"type == kXXTPixelCropViewTypePosition");
        CGPoint selectedPoint = [selectedValue CGPointValue];
        NSString *pFormat = @"%d, %d";
        _pickerResult = [NSString stringWithFormat:pFormat, (int) selectedPoint.x, (int) selectedPoint.y];
        NSString *previewFormat = @"(x%d, y%d)";
        NSString *previewString = [NSString stringWithFormat:previewFormat, (int) selectedPoint.x, (int) selectedPoint.y];
        [self updateSubtitle:previewString];
    } else if (type == kXXTPixelCropViewTypePositionColor || type == kXXTPixelCropViewTypeMultiplePositionColor) {
        if ([selectedValue isKindOfClass:[XXTPositionColorModel class]]) {
            XXTPositionColorModel *model = selectedValue;
            CGPoint selectedPoint = model.position;
            UIColor *selectedColor = model.color;
            NSString *selectedHex = [selectedColor hexStringWithAlpha:NO];
            if (type == kXXTPixelCropViewTypePositionColor) {
                NSString *format = @"%d, %d, 0x%@";
                _pickerResult = [NSString stringWithFormat:format, (int) selectedPoint.x, (int) selectedPoint.y, selectedHex];
            }
            NSString *previewFormat = @"(x%d, y%d) ";
            NSString *previewString = [NSString stringWithFormat:previewFormat, (int) selectedPoint.x, (int) selectedPoint.y];
            NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:previewString
                                                                                                 attributes:@{
                                                                                                         NSFontAttributeName: [UIFont fontWithName:@"CourierNewPSMT" size:12.f],
                                                                                                         NSForegroundColorAttributeName: [UIColor blackColor]
                                                                                                 }];
            NSString *colorPreview = [NSString stringWithFormat:@"(■ 0x%@)", selectedHex];
            NSAttributedString *colorAttributedPreview = [[NSMutableAttributedString alloc] initWithString:colorPreview
                                                                                                attributes:@{
                                                                                                        NSFontAttributeName: [UIFont fontWithName:@"CourierNewPS-BoldMT" size:12.f],
                                                                                                        NSForegroundColorAttributeName: selectedColor,
                                                                                                        NSBackgroundColorAttributeName: [selectedColor inverseColor]
                                                                                                }];
            [attributedString appendAttributedString:colorAttributedPreview];
            [self updatedAttributedSubtitle:[attributedString copy]];
        } else if ([selectedValue isKindOfClass:[NSArray class]]) {
            NSMutableString *mulString = [[NSMutableString alloc] initWithString:@"{\n"];
            NSUInteger index = 0;
            for (XXTPositionColorModel *poscolor in selectedValue) {
                index++;
                UIColor *c = [poscolor.color copy];
                if (!c) c = [UIColor blackColor];
                CGPoint p = poscolor.position;
                [mulString appendFormat:@"\t{ %d, %d, 0x%@ }, -- %lu\n",
                                        (int) p.x, (int) p.y,
                                        [c hexStringWithAlpha:NO], (unsigned long) index];
            }
            _pickerResult = [mulString stringByAppendingString:@"}"];
        } else {
            NSAssert(YES, @"type == kXXTPixelCropViewTypePositionColor || type == kXXTPixelCropViewTypeMultiplePositionColor");
        }
    }
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"[%@ dealloc]", NSStringFromClass([self class]));
#endif
}

@end
