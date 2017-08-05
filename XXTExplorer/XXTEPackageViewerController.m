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
#import "XXTEUserInterfaceDefines.h"
#import "XXTEDispatchDefines.h"

@interface XXTEPackageViewerController () <XXTEPackageExtractorDelegate, UITextViewDelegate>

@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic, strong) UIBarButtonItem *installButtonItem;
@property (nonatomic, strong) XXTEPackageExtractor *extractor;

@end

@implementation XXTEPackageViewerController

@synthesize entryPath = _entryPath;

+ (NSString *)viewerName {
    return @"Installer";
}

+ (NSArray <NSString *> *)suggestedExtensions {
    return @[ @"deb" ];
}

+ (Class)relatedReader {
    return [XXTExplorerEntryPackageReader class];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
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
    
    NSString *entryPath = self.entryPath;
    if (entryPath) {
        NSString *entryName = [entryPath lastPathComponent];
        self.title = entryName;
    }
    
    [self.view addSubview:self.textView];
    [self.textView insertText:@"[DEBIAN/control]\n\n"];
    
    [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithCustomView:self.activityIndicatorView] animated:NO];
    [self.activityIndicatorView startAnimating];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [self.extractor extractMetaData];
        dispatch_async_on_main_queue(^{
            [self.activityIndicatorView stopAnimating];
            [self.navigationItem setRightBarButtonItem:self.installButtonItem animated:YES];
        });
    });
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
        _installButtonItem = installButtonItem;
    }
    return _installButtonItem;
}

- (UITextView *)textView {
    if (!_textView) {
        UITextView *textView = [[UITextView alloc] initWithFrame:self.view.bounds];
        textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        textView.delegate = self;
        textView.editable = NO;
        textView.autocorrectionType = UITextAutocorrectionTypeNo;
        textView.autocapitalizationType = UITextAutocapitalizationTypeNone;
        textView.textColor = [UIColor grayColor];
        textView.font = [UIFont fontWithName:@"CourierNewPSMT" size:14.f];
        textView.alwaysBounceVertical = YES;
        _textView = textView;
    }
    return _textView;
}

#pragma mark - XXTEPackageExtractorDelegate

- (void)packageExtractor:(XXTEPackageExtractor *)extractor didFinishFetchingMetaData:(NSData *)metaData {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *metaString = [[NSString alloc] initWithData:metaData encoding:NSUTF8StringEncoding];
        [self.textView insertText:metaString];
        [self.textView insertText:@"\nTap \"Install\" to continue..."];
    });
}

- (void)packageExtractor:(XXTEPackageExtractor *)extractor didFailFetchingMetaDataWithError:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *errorString = [error localizedDescription];
        [self.textView insertText:errorString];
        [self.textView insertText:@"\n"];
    });
}

- (void)packageExtractor:(XXTEPackageExtractor *)extractor didFinishInstalling:(NSString *)outputLog {
    
}

- (void)packageExtractor:(XXTEPackageExtractor *)extractor didFailInstallingWithError:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *errorString = [error localizedDescription];
        [self.textView insertText:errorString];
        [self.textView insertText:@"\n"];
    });
}

#pragma mark - UIControl Actions

- (void)installButtonItemTapped:(UIBarButtonItem *)sender {
    [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithCustomView:self.activityIndicatorView] animated:YES];
    [self.activityIndicatorView startAnimating];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [self.extractor installPackage];
        dispatch_async_on_main_queue(^{
            [self.activityIndicatorView stopAnimating];
            [self.navigationItem setRightBarButtonItem:self.installButtonItem animated:YES];
        });
    });
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [XXTEPackageViewerController dealloc]");
#endif
}

@end
