//
//  XXTETerminalViewController.m
//  XXTouchApp
//
//  Created by Zheng on 10/11/2016.
//  Copyright © 2016 Zheng. All rights reserved.
//

#import "XXTELuaVModel.h"
#import "XXTETerminalTextView.h"
#import "XXTETerminalViewController.h"
#import "XXTEEditorController+NavigationBar.h"
#import "XXTExplorerEntryTerminalReader.h"

@interface XXTETerminalViewController () <UITextViewDelegate, XXTELuaVModelDelegate>

@property (nonatomic, strong) XXTELuaVModel *virtualModel;
@property (nonatomic, strong) XXTETerminalTextView *textView;
@property (nonatomic, strong) UIBarButtonItem *launchItem;
@property (nonatomic, strong) UIBarButtonItem *activityIndicatorItem;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;

@end

@implementation XXTETerminalViewController

@synthesize entryPath = _entryPath;

+ (NSString *)viewerName {
    return NSLocalizedString(@"Local Debugger", nil);
}

+ (NSArray <NSString *> *)suggestedExtensions {
    return @[ @"lua" ];
}

+ (Class)relatedReader {
    return [XXTExplorerEntryTerminalReader class];
}

- (instancetype)initWithPath:(NSString *)path {
    if (self = [super init]) {
        _entryPath = path;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    if (self.title.length == 0) {
        if (self.entryPath) {
            NSString *entryName = [self.entryPath lastPathComponent];
            self.title = entryName;
        } else {
            self.title = NSLocalizedString(@"Console", nil);
        }
    }
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.rightBarButtonItem = self.launchItem;
    
    [self.view addSubview:self.textView];
    [self updateViewConstraints];
    [self loadProcess:self.runImmediately];
    
    XXTE_START_IGNORE_PARTIAL
    if (XXTE_COLLAPSED && [self.navigationController.viewControllers firstObject] == self) {
        [self.navigationItem setLeftBarButtonItems:self.splitButtonItems];
    }
    XXTE_END_IGNORE_PARTIAL
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [self.editor renderNavigationBarTheme:YES];
    [super viewWillAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (void)willMoveToParentViewController:(UIViewController *)parent {
    if (parent == nil) {
        [self.editor renderNavigationBarTheme:NO];
        if (self.virtualModel.running) {
            [self shutdownVirtualMachine];
        }
    } else {
        [self.editor renderNavigationBarTheme:YES];
    }
    [super willMoveToParentViewController:parent];
}

- (void)dealloc {
    [self resetVirtualMachine];
#ifdef DEBUG
    NSLog(@"- [XXTETerminalViewController dealloc]");
#endif
}

#pragma mark - Load

- (void)loadProcess:(BOOL)run {
    [self.textView setText:@""];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    if (self.entryPath) {
        [self displayWelcomeMessage:run];
        if (run) {
            [self performSelector:@selector(executeScript) withObject:nil afterDelay:.6f];
        }
    }
}

#pragma mark - Getters

- (XXTETerminalTextView *)textView {
    if (!_textView) {
        XXTETerminalTextView *textView = [[XXTETerminalTextView alloc] initWithFrame:self.view.bounds];
        textView.autocorrectionType = UITextAutocorrectionTypeNo;
        textView.autocapitalizationType = UITextAutocapitalizationTypeNone;
        textView.dataDetectorTypes = UIDataDetectorTypeNone;
        textView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
        textView.alwaysBounceVertical = YES;
        textView.delegate = self;
        textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        textView.editable = NO;
        _textView = textView;
    }
    return _textView;
}

- (UIBarButtonItem *)launchItem {
    if (!_launchItem) {
        _launchItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(launchItemTapped:)];
    }
    return _launchItem;
}

- (UIActivityIndicatorView *)activityIndicator {
    if (!_activityIndicator) {
        UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        _activityIndicator = activityIndicator;
    }
    return _activityIndicator;
}

- (UIBarButtonItem *)activityIndicatorItem {
    if (!_activityIndicatorItem) {
        UIBarButtonItem *activityIndicatorItem = [[UIBarButtonItem alloc] initWithCustomView:self.activityIndicator];
        activityIndicatorItem.tintColor = [UIColor whiteColor];
        _activityIndicatorItem = activityIndicatorItem;
    }
    return _activityIndicatorItem;
}

#pragma mark - Redirect

- (void)redirectStandardOutput:(int)fd {
    NSPipe *pipe = [NSPipe pipe];
    NSFileHandle *pipeReadHandle = [pipe fileHandleForReading];
    int result = dup2([[pipe fileHandleForWriting] fileDescriptor], fd);
    if (result != -1) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(redirectNotificationHandle:)
                                                     name:NSFileHandleReadCompletionNotification
                                                   object:pipeReadHandle];
        [pipeReadHandle readInBackgroundAndNotify];
    }
}

- (void)redirectNotificationHandle:(NSNotification *)aNotification {
    NSData *data = [[aNotification userInfo] objectForKey:NSFileHandleNotificationDataItem];
    NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    [self.textView appendString:str];
    [[aNotification object] readInBackgroundAndNotify];
}

#pragma mark - Execute

- (void)displayWelcomeMessage:(BOOL)run {
    [self.textView appendMessage:[NSString stringWithFormat:@"%@\n", NSLocalizedString(@LUA_COPYRIGHT, nil)]];
    if (run) {
        [self.textView appendMessage:[NSString stringWithFormat:NSLocalizedString(@"\nTesting %@...\n", nil), self.entryPath]];
    } else {
        [self.textView appendMessage:NSLocalizedString(@"\nReady.\n", nil)];
    }
}

- (void)displayFinishMessage {
    [self.textView appendMessage:NSLocalizedString(@"\n\nTest finished.\n", nil)];
}

- (void)launchVirtualMachine {
    [self resetVirtualMachine];
    
    XXTELuaVModel *virtualModel = [[XXTELuaVModel alloc] init];
    virtualModel.delegate = self;
    [virtualModel setFakeIOEnabled:YES];
    if (virtualModel.stdoutHandler && virtualModel.stderrHandler) {
        [self redirectStandardOutput:fileno(virtualModel.stdoutHandler)];
        [self redirectStandardOutput:fileno(virtualModel.stderrHandler)];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateTextViewInsetsWithKeyboardNotification:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateTextViewInsetsWithKeyboardNotification:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    self.virtualModel = virtualModel;
}

- (void)resetVirtualMachine {
    if (self.virtualModel.running) {
        return;
    }
    self.virtualModel = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)shutdownVirtualMachine {
    [self.virtualModel setRunning:NO];
}

- (void)executeScript {
    [self launchVirtualMachine];
    NSError *err = nil;
    BOOL result = [self.virtualModel loadFileFromPath:self.entryPath error:&err];
    if (!result && err) {
        [self.textView appendError:[NSString stringWithFormat:@"\n%@\n", [err localizedDescription]]];
        self.launchItem.enabled = YES;
        return;
    } else {
        [self.textView appendMessage:NSLocalizedString(@"\nSyntax check passed, testing...\n\n", nil)];
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSError *err = nil;
        BOOL result = [self.virtualModel pcallWithError:&err];
        dispatch_async_on_main_queue(^{
            if (!result && err) {
                [self.textView appendError:[NSString stringWithFormat:@"\n%@", [err localizedDescription]]];
                return;
            }
        });
    });
}

#pragma mark - Actions

- (void)launchItemTapped:(UIBarButtonItem *)sender {
    if (self.virtualModel.running) return;
    self.launchItem.enabled = NO;
    [self loadProcess:YES];
}

- (void)closeItemTapped:(UIBarButtonItem *)sender {
    if (self.virtualModel.running) {
        [self shutdownVirtualMachine];
        return;
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITextViewDelegate

- (BOOL)textView:(XXTETerminalTextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    NSString *originalText = textView.text;
    if (
        range.location == originalText.length &&
        range.length == 0 &&
        text.length != 0
        ) {
        if ([text isEqualToString:@"\n"]) {
            [textView insertText:text];
            NSString *bufferedString = [textView getBufferString];
            const char *buf = bufferedString.UTF8String;
            if (self.virtualModel.stdinWriteHandler) {
                write(fileno(self.virtualModel.stdinWriteHandler), buf, strlen(buf));
            }
            return NO;
        }
        [self.textView resetTypingAttributes];
        return YES;
    }
    else if (
             range.location == originalText.length - 1 &&
             text.length == 0 &&
             [textView canDeleteBackward]
             ) {
        return YES;
    }
    textView.selectedRange = NSMakeRange(textView.text.length, 0);
    return NO;
}

#pragma mark - XXTELuaVModelDelegate

- (void)virtualMachineDidChangedState:(XXTELuaVModel *)vm {
    dispatch_sync_on_main_queue(^{
        self.textView.editable = vm.running;
        self.launchItem.enabled = !vm.running;
        if (!vm.running) {
            [self.activityIndicator stopAnimating];
            [self.navigationItem setRightBarButtonItem:self.launchItem];
            if ([self.textView isFirstResponder]) {
                [self.textView resignFirstResponder];
            }
            [self performSelector:@selector(displayFinishMessage) withObject:nil afterDelay:.6f];
        } else {
            [self.navigationItem setRightBarButtonItem:self.activityIndicatorItem];
            [self.activityIndicator startAnimating];
        }
    });
}

#pragma mark - Keyboard Events

- (void)updateTextViewInsetsWithKeyboardNotification:(NSNotification *)notification
{
    UIEdgeInsets newInsets = UIEdgeInsetsZero;
    if (notification)
    {
        CGRect keyboardFrame;
        [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardFrame];
        keyboardFrame = [self.view convertRect:keyboardFrame fromView:nil];
        newInsets.bottom = self.view.frame.size.height - keyboardFrame.origin.y;
    }
    UITextView *textView = self.textView;
    textView.contentInset = newInsets;
    textView.scrollIndicatorInsets = newInsets;
}

@synthesize awakeFromOutside;

@end
