//
//  XXTECommonWebViewController.m
//  XXTExplorer
//
//  Created by Zheng on 03/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTECommonWebViewController.h"
#import <LGAlertView/LGAlertView.h>

@interface XXTECommonWebViewController () <WKUIDelegate>

@end

@implementation XXTECommonWebViewController

@synthesize entryPath = _entryPath;

- (instancetype)init {
    if (self = [super init]) {
        [self configure];
    }
    return self;
}

- (instancetype)initWithPath:(NSString *)path {
    NSURL *fileURL = [NSURL fileURLWithPath:path];
    if (self = [super initWithURL:fileURL]) {
        _entryPath = path;
        [self configure];
    }
    return self;
}

- (instancetype)initWithURL:(NSURL *)url {
    if (self = [super initWithURL:url]) {
        [self configure];
    }
    return self;
}

- (void)configure { // do not override [super setup]
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }
    
    self.loadingBarTintColor = [XXTColorForeground() colorWithAlphaComponent:0.33];
    self.showLoadingBar = YES;
    self.showUrlWhileLoading = NO;
    self.hideWebViewBoundaries = NO;
    
    if (isiPhoneX() || XXTE_IS_IPAD) {
        self.hidesBottomBarWhenPushed = YES;
    } else {
        self.hidesBottomBarWhenPushed = NO;
    }
    
    @weakify(self);
    if (@available(iOS 9.0, *)) {
        self.wk_shouldStartLoadRequestHandler = ^BOOL(NSURLRequest *request, WKNavigationType navigationType) {
            @strongify(self);
            NSURL *url = request.URL;
            NSArray <NSString *> *allowedSchemes = @[@"xxt", @"cydia"];
            if ([allowedSchemes containsObject:url.scheme]) {
                [self dismissViewControllerAnimated:YES completion:^{
                    if ([[UIApplication sharedApplication] canOpenURL:url])
                    {
                        [[UIApplication sharedApplication] openURL:url];
                    }
                }];
                return NO;
            }
            return YES;
        };
    } else {
        // Fallback on earlier versions
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    if (isiPhoneX()) {
//        if (self.navigationButtonsHidden == YES)
//        {
//            self.hidesBottomBarWhenPushed = NO;
//        }
//    }
    
    if (self.webView) {
        self.webView.opaque = NO;
    } else if (self.wkWebView) {
        if (@available(iOS 9.0, *)) {
            self.wkWebView.opaque = NO;
            self.wkWebView.UIDelegate = self;
        }
    }

    XXTE_START_IGNORE_PARTIAL
    if (XXTE_COLLAPSED && [self.navigationController.viewControllers firstObject] == self) {
        [self.navigationItem setLeftBarButtonItems:self.splitButtonItems];
        [self setApplicationLeftBarButtonItems:self.splitButtonItems];
    }
    XXTE_END_IGNORE_PARTIAL
}

- (void)showPlaceholderTitle {
    
}

#pragma mark - WKUIDelegate

XXTE_START_IGNORE_PARTIAL
- (nullable WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures
{
    if (webView == self.wkWebView) {
        if (![navigationAction.targetFrame isMainFrame]) {
            [webView loadRequest:navigationAction.request];
        }
    }
    return nil;
}
XXTE_END_IGNORE_PARTIAL

XXTE_START_IGNORE_PARTIAL
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler
{
    if (webView == self.wkWebView) {
        LGAlertView *alertView = [[LGAlertView alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"From \"%@\"", nil), webView.URL.host] message:message style:LGAlertViewStyleAlert buttonTitles:@[ NSLocalizedString(@"OK", nil) ] cancelButtonTitle:nil destructiveButtonTitle:nil actionHandler:^(LGAlertView * _Nonnull alertView, NSUInteger index, NSString * _Nullable title) {
            if (completionHandler) {
                completionHandler();
            }
            [alertView dismissAnimated];
        } cancelHandler:nil destructiveHandler:nil];
        [alertView showAnimated];
    }
}
XXTE_END_IGNORE_PARTIAL

XXTE_START_IGNORE_PARTIAL
- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL result))completionHandler
{
    if (webView == self.wkWebView) {
        LGAlertView *alertView = [[LGAlertView alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"From \"%@\"", nil), webView.URL.host] message:message style:LGAlertViewStyleAlert buttonTitles:@[ NSLocalizedString(@"Confirm", nil) ] cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil actionHandler:^(LGAlertView * _Nonnull alertView, NSUInteger index, NSString * _Nullable title) {
            if (completionHandler) {
                completionHandler(YES);
            }
            [alertView dismissAnimated];
        } cancelHandler:^(LGAlertView * _Nonnull alertView) {
            if (completionHandler) {
                completionHandler(NO);
            }
            [alertView dismissAnimated];
        } destructiveHandler:nil];
        [alertView showAnimated];
    }
}
XXTE_END_IGNORE_PARTIAL

XXTE_START_IGNORE_PARTIAL
- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(nullable NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable result))completionHandler
{
    if (webView == self.wkWebView) {
        LGAlertView *alertView = [[LGAlertView alloc] initWithTextFieldsAndTitle:[NSString stringWithFormat:NSLocalizedString(@"From \"%@\"", nil), webView.URL.host] message:prompt numberOfTextFields:1 textFieldsSetupHandler:^(UITextField * _Nonnull textField, NSUInteger index) {
            textField.text = defaultText;
        } buttonTitles:@[ NSLocalizedString(@"Confirm", nil) ] cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil actionHandler:^(LGAlertView * _Nonnull alertView, NSUInteger index, NSString * _Nullable title) {
            if (completionHandler) {
                UITextField *textField = [alertView.textFieldsArray firstObject];
                completionHandler(textField.text);
            }
            [alertView dismissAnimated];
        } cancelHandler:^(LGAlertView * _Nonnull alertView) {
            if (completionHandler) {
                completionHandler(nil);
            }
            [alertView dismissAnimated];
        } destructiveHandler:nil];
        [alertView showAnimated];
    }
}
XXTE_END_IGNORE_PARTIAL

XXTE_START_IGNORE_PARTIAL
- (void)webViewDidClose:(WKWebView *)webView {
    if (self.navigationController && self.navigationController.topViewController && self.navigationController.topViewController != self)
    {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}
XXTE_END_IGNORE_PARTIAL

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [%@ dealloc]", NSStringFromClass([self class]));
#endif
}

@end
