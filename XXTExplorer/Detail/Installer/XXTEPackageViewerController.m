//
//  XXTEPackageViewerController.m
//  XXTExplorer
//
//  Created by Zheng on 2017/8/5.
//  Copyright © 2017年 Zheng. All rights reserved.
//

#import "XXTEPackageViewerController.h"
#import "XXTExplorerEntryPackageReader.h"

#import "XXTEApplePackageExtractor.h"
#import "XXTEDebianPackageExtractor.h"

@interface XXTEPackageViewerController () <XXTEPackageExtractorDelegate, UITextViewDelegate>

@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic, strong) UIBarButtonItem *installButtonItem;
@property (nonatomic, strong) UIBarButtonItem *respringButtonItem;
@property (nonatomic, strong) id <XXTEPackageExtractor> extractor;
@property (nonatomic, copy) NSDictionary *stdoutAttributes;
@property (nonatomic, copy) NSDictionary *stderrAttributes;

@end

@implementation XXTEPackageViewerController

@synthesize entryPath = _entryPath;

+ (NSString *)viewerName {
    return NSLocalizedString(@"External Installer", nil);
}

+ (NSArray <NSString *> *)suggestedExtensions {
    return @[ @"deb", @"ipa" ];
}

+ (Class)relatedReader {
    return [XXTExplorerEntryPackageReader class];
}

- (instancetype)initWithPath:(NSString *)path {
    if (self = [super init]) {
        _entryPath = path;
        
        const char *path1 = [path fileSystemRepresentation];
        FILE *fil = fopen(path1, "rb");
        int32_t magic = 0x0;
        if (fil) {
            fread(&magic, 4, 1, fil);
            fclose(fil);
        }
        if (magic == 0x72613c21) {
            // debian package
            XXTEDebianPackageExtractor *extractor = [[XXTEDebianPackageExtractor alloc] initWithPath:path];
            extractor.delegate = self;
            _extractor = extractor;
        } else if (magic == 0x04034b50) {
            // ipa package
            XXTEApplePackageExtractor *extractor = [[XXTEApplePackageExtractor alloc] initWithPath:path];
            extractor.delegate = self;
            _extractor = extractor;
        } else {
            _extractor = nil;
        }
        
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
    
    id <XXTEPackageExtractor> extractor = self.extractor;
    if (!extractor) {
        [self.textView insertText:[NSString stringWithFormat:@"%@\n\n", NSLocalizedString(@"Unsupported package format.\nSupported formats are: deb, ipa.", nil)]];
    } else {
        if ([extractor isKindOfClass:[XXTEDebianPackageExtractor class]]) {
            [self.textView insertText:@"[DEBIAN/control]\n\n"];
        } else if ([extractor isKindOfClass:[XXTEApplePackageExtractor class]]) {
            
        }
        [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithCustomView:self.activityIndicatorView] animated:NO];
        [self.activityIndicatorView startAnimating];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            [self.extractor extractMetaData];
            dispatch_async_on_main_queue(^{
                [self.activityIndicatorView stopAnimating];
            });
        });
    }
    
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
        textView.font = [UIFont fontWithName:@"Courier" size:14.f];
        textView.delegate = self;
        textView.editable = NO;
        textView.autocorrectionType = UITextAutocorrectionTypeNo;
        textView.autocapitalizationType = UITextAutocapitalizationTypeNone;
        if (@available(iOS 13.0, *)) {
            textView.textColor = [UIColor labelColor];
        } else {
            textView.textColor = [UIColor blackColor];
        }
        textView.alwaysBounceVertical = YES;
        textView.typingAttributes = self.stdoutAttributes;
        _textView = textView;
    }
    return _textView;
}

- (NSDictionary *)stdoutAttributes {
    if (!_stdoutAttributes) {
        _stdoutAttributes =
        @{
          NSFontAttributeName: [UIFont fontWithName:@"Courier" size:14.f],
          NSForegroundColorAttributeName: [UIColor blackColor]
          };
    }
    return _stdoutAttributes;
}

- (NSDictionary *)stderrAttributes {
    if (!_stderrAttributes) {
        _stderrAttributes =
        @{
          NSFontAttributeName: [UIFont fontWithName:@"Courier" size:14.f],
          NSForegroundColorAttributeName: XXTColorDanger()
          };
    }
    return _stderrAttributes;
}

#pragma mark - XXTEDebianPackageExtractorDelegate

- (void)packageExtractor:(XXTEDebianPackageExtractor *)extractor didFinishFetchingMetaData:(NSData *)metaData {
    dispatch_async(dispatch_get_main_queue(), ^{
        UITextView *textView = self.textView;
        self.installButtonItem.enabled = YES;
        [self.navigationItem setRightBarButtonItem:self.installButtonItem animated:YES];
        textView.typingAttributes = self.stdoutAttributes;
        NSString *metaString = [[NSString alloc] initWithData:metaData encoding:NSUTF8StringEncoding];
        [textView insertText:metaString];
        [textView insertText:@"\n"];
        [textView insertText:[NSString stringWithFormat:@"%@", NSLocalizedString(@"Tap \"Install\" to continue...", nil)]];
        [textView insertText:@"\n"];
        [textView insertText:@"\n"];
    });
}

- (void)packageExtractor:(XXTEDebianPackageExtractor *)extractor didFailFetchingMetaDataWithError:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        UITextView *textView = self.textView;
        self.installButtonItem.enabled = NO;
        [self.navigationItem setRightBarButtonItem:self.installButtonItem animated:YES];
        textView.typingAttributes = self.stderrAttributes;
        NSString *errorString = [error localizedDescription];
        [textView insertText:@"\n"];
        [textView insertText:[NSString stringWithFormat:NSLocalizedString(@"[ERROR] %@", nil), errorString]];
        [textView insertText:@"\n"];
        [textView insertText:@"\n"];
    });
}

- (void)packageExtractor:(id<XXTEPackageExtractor>)extractor didReceiveStandardOutput:(NSString *)outputLog {
    dispatch_async(dispatch_get_main_queue(), ^{
        UITextView *textView = self.textView;
        textView.typingAttributes = self.stdoutAttributes;
        [textView insertText:outputLog];
    });
}

- (void)packageExtractor:(id<XXTEPackageExtractor>)extractor didReceiveStandardError:(NSString *)outputLog {
    dispatch_async(dispatch_get_main_queue(), ^{
        UITextView *textView = self.textView;
        textView.typingAttributes = self.stderrAttributes;
        [textView insertText:outputLog];
    });
}

- (void)packageExtractorDidFinishInstallation:(id<XXTEPackageExtractor>)extractor {
    dispatch_async(dispatch_get_main_queue(), ^{
        UITextView *textView = self.textView;
        self.respringButtonItem.enabled = YES;
        textView.typingAttributes = self.stdoutAttributes;
        if ([extractor respondsToSelector:@selector(killBackboardd)]) {
            [self.navigationItem setRightBarButtonItem:self.respringButtonItem animated:YES];
            [textView insertText:@"\n"];
            [textView insertText:[NSString stringWithFormat:@"%@", NSLocalizedString(@"Tap \"Respring\" to continue...", nil)]];
            [textView insertText:@"\n"];
            [textView insertText:@"\n"];
        } else {
            [textView insertText:@"\n"];
            [textView insertText:[NSString stringWithFormat:@"%@", NSLocalizedString(@"Operation completed.", nil)]];
            [textView insertText:@"\n"];
            [textView insertText:@"\n"];
        }
    });
}

- (void)packageExtractor:(XXTEDebianPackageExtractor *)extractor didFailInstallationWithError:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        UITextView *textView = self.textView;
        self.installButtonItem.enabled = YES;
        [self.navigationItem setRightBarButtonItem:self.installButtonItem animated:YES];
        textView.typingAttributes = self.stderrAttributes;
        NSString *errorString = [error localizedDescription];
        [textView insertText:@"\n"];
        [textView insertText:[NSString stringWithFormat:NSLocalizedString(@"[FAILED] %@", nil), errorString]];
        [textView insertText:@"\n"];
        [textView insertText:@"\n"];
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
        if ([self.extractor respondsToSelector:@selector(killBackboardd)])
        {
            [self.extractor killBackboardd];
        }
        dispatch_async_on_main_queue(^{
            [self.activityIndicatorView stopAnimating];
            blockInteractions(blockVC, NO);
        });
    });
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [%@ dealloc]", NSStringFromClass([self class]));
#endif
}

@synthesize awakeFromOutside;

@end
