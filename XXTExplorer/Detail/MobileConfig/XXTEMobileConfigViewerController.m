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
    return @[ @"mobileconfig" ];
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
        actionView.center = CGPointMake(CGRectGetWidth(self.view.bounds) / 2.0, CGRectGetHeight(self.view.bounds) / 2.0);
        actionView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        actionView.iconImageView.image = [XXTExplorerEntryMobileConfigReader defaultImage];
        actionView.titleLabel.text = NSLocalizedString(@"Continue in Safari", nil);
        actionView.descriptionLabel.text = @"";
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(launchButtonTapped:)];
        [actionView addGestureRecognizer:tapGesture];
        _actionView = actionView;
    }
    return _actionView;
}

#pragma mark - Actions

- (void)launchButtonTapped:(UIGestureRecognizer *)sender {
    LGAlertView *alertView = [[LGAlertView alloc] initWithTitle:NSLocalizedString(@"Redirect Confirm", nil) message:NSLocalizedString(@"You will be redirected to \"Safari\" and \"Preferences\".\nFollow the instruction to finish configuration.", nil) style:LGAlertViewStyleAlert buttonTitles:@[] cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:NSLocalizedString(@"Continue", nil) actionHandler:nil cancelHandler:^(LGAlertView * _Nonnull alertView) {
        [alertView dismissAnimated];
    } destructiveHandler:^(LGAlertView * _Nonnull alertView) {
        [alertView dismissAnimated];
        [self openInSafariImmediately];
    }];
    [alertView showAnimated];
}

- (void)openInSafariImmediately {
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
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [%@ dealloc]", NSStringFromClass([self class]));
#endif
}

@end
