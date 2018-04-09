//
//  XXTEPackageViewerController.m
//  XXTExplorer
//
//  Created by Zheng on 2017/8/5.
//  Copyright © 2017年 Zheng. All rights reserved.
//

#import "XXTEPackageViewerController.h"
#import "XXTExplorerEntryPackageReader.h"
#import "XXTEPackageExtractor.h"

@interface XXTEPackageViewerController () <XXTEPackageExtractorDelegate, UITextViewDelegate>

@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic, strong) UIBarButtonItem *installButtonItem;
@property (nonatomic, strong) UIBarButtonItem *respringButtonItem;
@property (nonatomic, strong) XXTEPackageExtractor *extractor;

@end

@implementation XXTEPackageViewerController

@synthesize entryPath = _entryPath;

+ (NSString *)viewerName {
    return NSLocalizedString(@"Installer", nil);
}

+ (NSArray <NSString *> *)suggestedExtensions {
    return @[ @"deb" ];
}

+ (Class)relatedReader {
    return [XXTExplorerEntryPackageReader class];
}

- (instancetype)initWithPath:(NSString *)path {
    if (self = [super init]) {
        _entryPath = path;
        
        XXTEPackageExtractor *extractor = [[XXTEPackageExtractor alloc] initWithPath:path];
        extractor.delegate = self;
        
        _extractor = extractor;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.title.length == 0) {
        NSString *entryPath = self.entryPath;
        if (entryPath) {
            NSString *entryName = [entryPath lastPathComponent];
            self.title = entryName;
        }
    }
    
    [self.view addSubview:self.textView];
    [self.textView insertText:@"[DEBIAN/control]\n\n"];
    
    [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithCustomView:self.activityIndicatorView] animated:NO];
    [self.activityIndicatorView startAnimating];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [self.extractor extractMetaData];
        dispatch_async_on_main_queue(^{
            [self.activityIndicatorView stopAnimating];
        });
    });

    XXTE_START_IGNORE_PARTIAL
    if (XXTE_COLLAPSED && [self.navigationController.viewControllers firstObject] == self) {
        [self.navigationItem setLeftBarButtonItems:self.splitButtonItems];
    }
    XXTE_END_IGNORE_PARTIAL
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }
}

#pragma mark - UIView Getters

- (UIActivityIndicatorView *)activityIndicatorView {
    if (!_activityIndicatorView) {
        UIActivityIndicatorView *activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        activityIndicatorView.hidesWhenStopped = YES;
        _activityIndicatorView = activityIndicatorView;
    }
    return _activityIndicatorView;
}

- (UIBarButtonItem *)installButtonItem {
    if (!_installButtonItem) {
        UIBarButtonItem *installButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Install", nil) style:UIBarButtonItemStyleDone target:self action:@selector(installButtonItemTapped:)];
        installButtonItem.enabled = NO;
        installButtonItem.tintColor = [UIColor whiteColor];
        _installButtonItem = installButtonItem;
    }
    return _installButtonItem;
}

- (UIBarButtonItem *)respringButtonItem {
    if (!_respringButtonItem) {
        UIBarButtonItem *respringButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Respring", nil) style:UIBarButtonItemStyleDone target:self action:@selector(respringButtonItemTapped:)];
        respringButtonItem.enabled = NO;
        respringButtonItem.tintColor = [UIColor whiteColor];
        _respringButtonItem = respringButtonItem;
    }
    return _respringButtonItem;
}

- (UITextView *)textView {
    if (!_textView) {
        UITextView *textView = [[UITextView alloc] initWithFrame:self.view.bounds];
        textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        textView.delegate = self;
        textView.editable = NO;
        textView.autocorrectionType = UITextAutocorrectionTypeNo;
        textView.autocapitalizationType = UITextAutocapitalizationTypeNone;
        textView.textColor = [UIColor blackColor];
        textView.font = [UIFont fontWithName:@"CourierNewPSMT" size:14.f];
        textView.alwaysBounceVertical = YES;
        _textView = textView;
    }
    return _textView;
}

#pragma mark - XXTEPackageExtractorDelegate

- (void)packageExtractor:(XXTEPackageExtractor *)extractor didFinishFetchingMetaData:(NSData *)metaData {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.installButtonItem.enabled = YES;
        [self.navigationItem setRightBarButtonItem:self.installButtonItem animated:YES];
        NSString *metaString = [[NSString alloc] initWithData:metaData encoding:NSUTF8StringEncoding];
        [self.textView insertText:metaString];
        [self.textView insertText:[NSString stringWithFormat:@"\n%@\n\n", NSLocalizedString(@"Tap \"Install\" to continue...", nil)]];
    });
}

- (void)packageExtractor:(XXTEPackageExtractor *)extractor didFailFetchingMetaDataWithError:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.installButtonItem.enabled = NO;
        [self.navigationItem setRightBarButtonItem:self.installButtonItem animated:YES];
        NSString *errorString = [error localizedDescription];
        [self.textView insertText:[NSString stringWithFormat:@"[ERROR] %@", errorString]];
        [self.textView insertText:@"\n"];
    });
}

- (void)packageExtractor:(XXTEPackageExtractor *)extractor didFinishInstallation:(NSString *)outputLog {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.respringButtonItem.enabled = YES;
        [self.navigationItem setRightBarButtonItem:self.respringButtonItem animated:YES];
        [self.textView insertText:outputLog];
        [self.textView insertText:[NSString stringWithFormat:@"\n%@\n\n", NSLocalizedString(@"Tap \"Respring\" to continue...", nil)]];
    });
}

- (void)packageExtractor:(XXTEPackageExtractor *)extractor didFailInstallationWithError:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.installButtonItem.enabled = YES;
        [self.navigationItem setRightBarButtonItem:self.installButtonItem animated:YES];
        NSString *errorString = [error localizedDescription];
        [self.textView insertText:[NSString stringWithFormat:@"[ERROR] %@", errorString]];
        [self.textView insertText:@"\n"];
    });
}

#pragma mark - UIControl Actions

- (void)installButtonItemTapped:(UIBarButtonItem *)sender {
    [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithCustomView:self.activityIndicatorView] animated:YES];
    UIViewController *blockVC = blockInteractions(self, YES);
    [self.activityIndicatorView startAnimating];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [self.extractor installPackage];
        dispatch_async_on_main_queue(^{
            [self.activityIndicatorView stopAnimating];
            blockInteractions(blockVC, NO);
        });
    });
}

- (void)respringButtonItemTapped:(UIBarButtonItem *)sender {
    [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithCustomView:self.activityIndicatorView] animated:YES];
    UIViewController *blockVC = blockInteractions(self, YES);
    [self.activityIndicatorView startAnimating];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [self.extractor killBackboardd];
        dispatch_async_on_main_queue(^{
            [self.activityIndicatorView stopAnimating];
            blockInteractions(blockVC, NO);
        });
    });
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [XXTEPackageViewerController dealloc]");
#endif
}

@synthesize awakeFromOutside;

@end
