//
//  XXTEMobileConfigViewerController.m
//  XXTExplorer
//
//  Created by Zheng on 26/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEMobileConfigViewerController.h"
#import "XXTExplorerEntryMobileConfigReader.h"

#import <LGAlertView/LGAlertView.h>
#import "XXTESingleActionView.h"

@interface XXTEMobileConfigViewerController ()

@property (nonatomic, strong) XXTESingleActionView *actionView;
@property (nonatomic, strong) UIBarButtonItem *shareButtonItem;

@end

@implementation XXTEMobileConfigViewerController {
    BOOL _isFirstLoaded;
}

@synthesize entryPath = _entryPath;
@synthesize awakeFromOutside = _awakeFromOutside;

- (instancetype)initWithPath:(NSString *)path {
    if (self = [super init]) {
        _entryPath = path;
    }
    return self;
}

+ (NSString *)viewerName {
    return NSLocalizedString(@"Mobile Configurator", nil);
}

+ (NSArray <NSString *> *)suggestedExtensions {
    return @[ @"mobileconfig",
              @"pem", @"crt", @"cer", @"key",
              @"der", @"rsa",
              @"pfx", @"p12",
              @"csr", @"key" ];
}

+ (Class)relatedReader {
    return [XXTExplorerEntryMobileConfigReader class];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if (self.title.length == 0) {
        if (self.entryPath) {
            NSString *entryName = [self.entryPath lastPathComponent];
            self.title = entryName;
        } else {
            self.title = [[self class] viewerName];
        }
    }
    
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.actionView];
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }
    self.navigationItem.rightBarButtonItem = self.shareButtonItem;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!_isFirstLoaded) {
        _isFirstLoaded = YES;
    }
}

#pragma mark - UIView Getters

- (XXTESingleActionView *)actionView {
    if (!_actionView) {
        XXTESingleActionView *actionView = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTESingleActionView class]) owner:nil options:nil] lastObject];
        actionView.frame = CGRectMake(0.0, 0.0, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds));
        actionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        actionView.iconImageView.image = [XXTExplorerEntryMobileConfigReader defaultImage];
        actionView.titleLabel.text = NSLocalizedString(@"Continue in Safari", nil);
        actionView.descriptionLabel.text = NSLocalizedString(@"Tap here to setup configuration file in Safari.", nil);
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(launchButtonTapped:)];
        [actionView addGestureRecognizer:tapGesture];
        _actionView = actionView;
    }
    return _actionView;
}

- (UIBarButtonItem *)shareButtonItem {
    if (!_shareButtonItem) {
        UIBarButtonItem *shareButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(shareButtonItemTapped:)];
        _shareButtonItem = shareButtonItem;
    }
    return _shareButtonItem;
}

#pragma mark - Actions

- (void)launchButtonTapped:(UIGestureRecognizer *)sender {
#ifndef APPSTORE
    LGAlertView *alertView = [[LGAlertView alloc] initWithTitle:NSLocalizedString(@"Redirect Confirm", nil) message:NSLocalizedString(@"You will be redirected to \"Safari\" and \"Preferences\".\nFollow the instruction to finish configuration.", nil) style:LGAlertViewStyleAlert buttonTitles:@[] cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:NSLocalizedString(@"Continue", nil) actionHandler:nil cancelHandler:^(LGAlertView * _Nonnull alertView) {
        [alertView dismissAnimated];
    } destructiveHandler:^(LGAlertView * _Nonnull alertView) {
        [alertView dismissAnimated];
        [self openInSafariImmediately];
    }];
    [alertView showAnimated];
#else
    LGAlertView *alertView = [[LGAlertView alloc] initWithTitle:NSLocalizedString(@"Instruction", nil) message:NSLocalizedString(@"Data URL will be copied to the pasteboard, paste it in Safari maually to finish installation.", nil) style:LGAlertViewStyleAlert buttonTitles:@[] cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:NSLocalizedString(@"Continue", nil) actionHandler:nil cancelHandler:^(LGAlertView * _Nonnull alertView) {
        [alertView dismissAnimated];
    } destructiveHandler:^(LGAlertView * _Nonnull alertView) {
        [alertView dismissAnimated];
        [self openInSafariImmediately];
    }];
    [alertView showAnimated];
#endif
}

- (void)openInSafariImmediately {
#ifndef APPSTORE
    NSError *directoryError = nil;
    NSString *webPath = [XXTERootPath() stringByAppendingPathComponent:@"web"];
    NSString *webTmpComponent = [@"tmp" stringByAppendingFormat:@"/%@", [[NSUUID UUID] UUIDString]];
    NSString *webTmpDirPath = [webPath stringByAppendingPathComponent:webTmpComponent];
    NSFileManager *webManager = [NSFileManager defaultManager];
    BOOL directoryResult = [webManager createDirectoryAtPath:webTmpDirPath withIntermediateDirectories:YES attributes:nil error:&directoryError];
    if (!directoryResult) {
        toastError(self, directoryError);
        return;
    }
    NSError *copyError = nil;
    NSString *targetName = [self.entryPath lastPathComponent];
    NSString *targetPath = [webTmpDirPath stringByAppendingPathComponent:targetName];
    BOOL copyResult = [webManager copyItemAtPath:self.entryPath toPath:targetPath error:&copyError];
    if (!copyResult) {
        toastError(self, copyError);
        return;
    }
    NSString *accessURLString = uAppWebAccessUrl(targetPath);
    NSURL *accessURL = [NSURL URLWithString:accessURLString];
    UIApplication *sharedApplication = [UIApplication sharedApplication];
    if ([sharedApplication canOpenURL:accessURL]) {
        [sharedApplication openURL:accessURL];
    }
#else
    if (!self.entryPath) return;
    NSError *readingError = nil;
    NSData *data = [NSData dataWithContentsOfFile:self.entryPath options:kNilOptions error:&readingError];
    if (!data) {
        toastError(self, readingError);
        return;
    }
    NSString *b64String = [data base64EncodedStringWithOptions:kNilOptions];
    NSString *urlString = [NSString stringWithFormat:@"data:application/x-apple-aspen-config;base64,%@", b64String];
    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) return;
    BOOL succeed = NO;
    UIApplication *sharedApplication = [UIApplication sharedApplication];
    if ([sharedApplication canOpenURL:url]) {
        succeed = [sharedApplication openURL:url];
    }
    else {
        [[UIPasteboard generalPasteboard] setURL:url];
        NSURL *exampleURL = [NSURL URLWithString:@"https://example.com/"];
        if ([sharedApplication canOpenURL:exampleURL]) {
            succeed = [sharedApplication openURL:exampleURL];
        }
    }
    if (!succeed) {
        toastMessage(self, NSLocalizedString(@"Cannot redirect to Safari.", nil));
    }
#endif
}

- (void)shareButtonItemTapped:(UIBarButtonItem *)sender {
    if (!self.entryPath) return;
    NSURL *shareURL = [NSURL fileURLWithPath:self.entryPath];
    if (!shareURL) return;
    XXTE_START_IGNORE_PARTIAL
    if (@available(iOS 9.0, *)) {
        UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[ shareURL ] applicationActivities:nil];
        if (XXTE_IS_IPAD) {
            activityViewController.modalPresentationStyle = UIModalPresentationPopover;
            UIPopoverPresentationController *popoverPresentationController = activityViewController.popoverPresentationController;
            popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionAny;
            popoverPresentationController.barButtonItem = sender;
        }
        [self.navigationController presentViewController:activityViewController animated:YES completion:nil];
    } else {
        toastMessage(self, NSLocalizedString(@"This feature requires iOS 9.0 or later.", nil));
    }
    XXTE_END_IGNORE_PARTIAL
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [%@ dealloc]", NSStringFromClass([self class]));
#endif
}

@end
