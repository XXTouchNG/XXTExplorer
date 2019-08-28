//
//  XXTETerminalViewController.m
//  XXTouchApp
//
//  Created by Zheng on 10/11/2016.
//  Copyright © 2016 Zheng. All rights reserved.
//

#import "XXTELuaVModel.h"
#import "XXTEAppDefines.h"
#import "XXTExplorerDefaults.h"
#import "XXTETerminalTextView.h"
#import "XXTETerminalViewController.h"
#import "XXTEEditorController+NavigationBar.h"
#import "XXTExplorerEntryTerminalReader.h"

typedef enum : NSUInteger {
    XXTETerminalContentTypeDoNotLog = 0,
    XXTETerminalContentTypeTips,
    XXTETerminalContentTypeStandardOutput,
    XXTETerminalContentTypeStandardError,
} XXTETerminalContentType;


@interface XXTETerminalViewController () <UITextViewDelegate, XXTELuaVModelDelegate>

@property (nonatomic, strong) XXTELuaVModel *virtualModel;
@property (nonatomic, strong) XXTETerminalTextView *textView;
@property (nonatomic, strong) UIBarButtonItem *launchItem;
@property (nonatomic, strong) UIBarButtonItem *closeItem;
@property (nonatomic, strong) UIBarButtonItem *activityIndicatorItem;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) NSMutableArray <NSPipe *> *pipes;

@property (nonatomic, strong) NSString *logPath;
@property (nonatomic, strong) NSFileHandle *logHandle;

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
        _pipes = [NSMutableArray array];
        
        BOOL saveLogs = XXTEDefaultsBool(XXTExplorerTerminalSaveLogs, YES);
        if (saveLogs) {
            NSString *logName = [NSString stringWithFormat:@"%@-%@.log", NSStringFromClass([self class]), [[NSUUID UUID] UUIDString]];
            NSString *logPath = [[XXTERootPath() stringByAppendingPathComponent:@"log"] stringByAppendingPathComponent:logName];
            _logPath = logPath;
            BOOL created = [[NSFileManager defaultManager] createFileAtPath:logPath contents:[NSData data] attributes:nil];
            if (created) {
                NSFileHandle *logHandle = [NSFileHandle fileHandleForWritingAtPath:logPath];
                _logHandle = logHandle;
            }
        } else {
            _logPath = nil;
            _logHandle = nil;
        }
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
    
    self.view.backgroundColor = XXTColorPlainBackground();
    self.navigationItem.rightBarButtonItem = self.launchItem;
    
    [self.view addSubview:self.textView];
    [self updateViewConstraints];
    [self loadProcess:self.runImmediately];
    
    XXTE_START_IGNORE_PARTIAL
    if ([self.navigationController.viewControllers firstObject] == self) {
        if (XXTE_COLLAPSED) {
            [self.navigationItem setLeftBarButtonItems:self.splitButtonItems];
        } else {
            [self.navigationItem setLeftBarButtonItem:self.closeItem];
        }
    }
    XXTE_END_IGNORE_PARTIAL
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateTextViewInsetsWithKeyboardNotification:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateTextViewInsetsWithKeyboardNotification:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    if (XXTE_IS_FULLSCREEN(self) || self.navigationController == self.editor.navigationController) {
        [self.editor renderNavigationBarTheme:YES];
    }
    [super viewWillAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    if (self.virtualModel.running) {
        [self shutdownVirtualMachine];
    }
    [super viewDidDisappear:animated];
}

- (void)willMoveToParentViewController:(UIViewController *)parent {
    if (parent == nil) {
        [self.editor renderNavigationBarTheme:NO];
        if (self.virtualModel.running) {
            [self shutdownVirtualMachine];
        }
    } else {
        if (XXTE_IS_FULLSCREEN(self) || parent == self.editor.navigationController) {
            [self.editor renderNavigationBarTheme:YES];
        }
    }
    
    [super willMoveToParentViewController:parent];
}

- (void)dealloc {
    [self resetVirtualMachine];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.logHandle closeFile];
#ifdef DEBUG
    NSLog(@"- [%@ dealloc]", NSStringFromClass([self class]));
#endif
}

#pragma mark - Load

- (void)loadProcess:(BOOL)run {
    [self resetContentOfTextView:self.textView];
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
        activityIndicator.color = XXTColorTint();
        activityIndicator.tintColor = XXTColorTint();
        _activityIndicator = activityIndicator;
    }
    return _activityIndicator;
}

- (UIBarButtonItem *)activityIndicatorItem {
    if (!_activityIndicatorItem) {
        UIBarButtonItem *activityIndicatorItem = [[UIBarButtonItem alloc] initWithCustomView:self.activityIndicator];
        activityIndicatorItem.tintColor = XXTColorTint();
        _activityIndicatorItem = activityIndicatorItem;
    }
    return _activityIndicatorItem;
}

- (UIBarButtonItem *)closeItem {
    if (!_closeItem) {
        UIBarButtonItem *closeItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", nil) style:UIBarButtonItemStylePlain target:self action:@selector(closeItemTapped:)];
        _closeItem = closeItem;
    }
    return _closeItem;
}

#pragma mark - Redirect

- (void)registerFileHandlerNotification:(int)fd isStdout:(BOOL)type
{
    NSPipe *pipe = [NSPipe pipe];
    NSFileHandle *pipeReadHandle = pipe.fileHandleForReading;
    int result = dup2(pipe.fileHandleForWriting.fileDescriptor, fd);
    if (result > 0)
    {
        if (type) {
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(fileHandlerReadabilityHandlerStdout:)
                                                         name:NSFileHandleReadCompletionNotification
                                                       object:pipeReadHandle];
            [pipeReadHandle readInBackgroundAndNotify];
        } else {
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(fileHandlerReadabilityHandlerStderr:)
                                                         name:NSFileHandleReadCompletionNotification
                                                       object:pipeReadHandle];
            [pipeReadHandle readInBackgroundAndNotify];
        }
    }
    [self.pipes addObject:pipe];
}

- (void)fileHandlerReadabilityHandlerStdout:(NSNotification *)aNotification
{
    NSFileHandle *pipeReadHandle = [aNotification object];
    NSPipe *pipe = nil;
    for (NSPipe *pipe0 in self.pipes) {
        if (pipe0.fileHandleForReading == pipeReadHandle) {
            pipe = pipe0;
        }
    }
    if (!pipe) {
        return;
    }
    NSData *data = [[aNotification userInfo] objectForKey:NSFileHandleNotificationDataItem];
    NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    [self appendContent:str contentType:XXTETerminalContentTypeStandardOutput toTextView:self.textView];
    if ([pipeReadHandle isKindOfClass:[NSFileHandle class]]) {
        [pipeReadHandle readInBackgroundAndNotify];
    }
}

- (void)fileHandlerReadabilityHandlerStderr:(NSNotification *)aNotification
{
    NSFileHandle *pipeReadHandle = [aNotification object];
    NSPipe *pipe = nil;
    for (NSPipe *pipe0 in self.pipes) {
        if (pipe0.fileHandleForReading == pipeReadHandle) {
            pipe = pipe0;
        }
    }
    if (!pipe) {
        return;
    }
    NSData *data = [[aNotification userInfo] objectForKey:NSFileHandleNotificationDataItem];
    NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    [self appendContent:str contentType:XXTETerminalContentTypeStandardError toTextView:self.textView];
    if ([pipeReadHandle isKindOfClass:[NSFileHandle class]]) {
        [pipeReadHandle readInBackgroundAndNotify];
    }
}

#pragma mark - Execute

- (void)displayWelcomeMessage:(BOOL)run {
    if (self.logPath && self.logHandle) {
        [self appendContent:[NSString stringWithFormat:NSLocalizedString(@"Begin logging at: %@\n\n", nil), self.logPath] contentType:XXTETerminalContentTypeDoNotLog toTextView:self.textView];
    }
    [self appendContent:[NSString stringWithFormat:@"%@\n", NSLocalizedString(@LUA_COPYRIGHT, nil)] contentType:XXTETerminalContentTypeTips toTextView:self.textView];
    if (run) {
        [self appendContent:[NSString stringWithFormat:NSLocalizedString(@"\nTesting %@...\n", nil), self.entryPath] contentType:XXTETerminalContentTypeTips toTextView:self.textView];
    } else {
        [self appendContent:NSLocalizedString(@"\nReady.\n", nil) contentType:XXTETerminalContentTypeTips toTextView:self.textView];
    }
}

- (void)displayFinishMessage {
    [self appendContent:NSLocalizedString(@"\n\nTest finished.\n", nil) contentType:XXTETerminalContentTypeTips toTextView:self.textView];
}

- (void)launchVirtualMachine {
    [self resetVirtualMachine];
    
    XXTELuaVModel *virtualModel = [[XXTELuaVModel alloc] init];
    virtualModel.delegate = self;
    [virtualModel setFakeIOEnabled:YES];
    if (virtualModel.stdoutHandler)
    {
        [self registerFileHandlerNotification:fileno(virtualModel.stdoutHandler) isStdout:YES];
    }
    if (virtualModel.stderrHandler)
    {
        [self registerFileHandlerNotification:fileno(virtualModel.stderrHandler) isStdout:NO];
    }
    self.virtualModel = virtualModel;
}

- (void)resetVirtualMachine {
    if (self.virtualModel.running) {
        return;
    }
    [self shutdownVirtualMachine];
}

- (void)shutdownVirtualMachine {
    if (self.virtualModel.running) {
        [self.virtualModel setRunning:NO];
    }
    self.virtualModel = nil;
    [self.pipes removeAllObjects];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSFileHandleReadCompletionNotification object:nil];
}

- (void)executeScript {
    [self launchVirtualMachine];
    NSError *err = nil;
    BOOL result = [self.virtualModel loadFileFromPath:self.entryPath error:&err];
    if (!result && err) {
        [self appendContent:[NSString stringWithFormat:@"\n%@\n", [err localizedDescription]] contentType:XXTETerminalContentTypeStandardError toTextView:self.textView];
        self.launchItem.enabled = YES;
        if ([self->_delegate respondsToSelector:@selector(terminalDidTerminate:withError:)]) {
            // preprocess with lua error
            if (err.code != -1) {
                [self->_delegate terminalDidTerminate:self withError:err];
            }
        }
        return;
    } else {
        [self appendContent:NSLocalizedString(@"\nSyntax check passed, testing...\n\n", nil) contentType:XXTETerminalContentTypeTips toTextView:self.textView];
    }
    @weakify(self);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        @strongify(self);
        NSError *err = nil;
        BOOL result = [self.virtualModel pcallWithError:&err];
        dispatch_async_on_main_queue(^{
            if (!result && err) {
                [self appendContent:[NSString stringWithFormat:@"\n%@", [err localizedDescription]] contentType:XXTETerminalContentTypeStandardError toTextView:self.textView];
                if ([self->_delegate respondsToSelector:@selector(terminalDidTerminate:withError:)]) {
                    // preprocess with lua error
                    if (err.code != -1) {
                        [self->_delegate terminalDidTerminate:self withError:err];
                    }
                }
            } else {
                if ([self->_delegate respondsToSelector:@selector(terminalDidTerminateWithSuccess:)]) {
                    [self->_delegate terminalDidTerminateWithSuccess:self];
                }
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

#pragma mark - Logs

- (void)appendContent:(NSString *)content contentType:(XXTETerminalContentType)type toTextView:(XXTETerminalTextView *)textView
{
    if (type == XXTETerminalContentTypeTips) {
        [textView appendMessage:content];
    } else if (type == XXTETerminalContentTypeStandardOutput) {
        [textView appendString:content];
    } else if (type == XXTETerminalContentTypeStandardError) {
        [textView appendError:content];
    } else {
        [textView appendMessage:content];
    }
    if (self.logHandle && type != XXTETerminalContentTypeDoNotLog) {
        NSData *logData = [[content stringByAppendingString:@NSStringLineBreakCRLF] dataUsingEncoding:NSUTF8StringEncoding];
        [self.logHandle writeData:logData];
    }
}

- (void)resetContentOfTextView:(XXTETerminalTextView *)textView
{
    [textView setText:@""];
    if (self.logHandle) {
        [self.logHandle truncateFileAtOffset:0];
        [self.logHandle synchronizeFile];
    }
}

#pragma mark - UITextViewDelegate

- (BOOL)textView:(XXTETerminalTextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    NSString *originalText = textView.text;
    if (
        range.location == originalText.length &&
        range.length == 0 &&
        text.length != 0
        ) {
        if ([text isEqualToString:@NSStringLineBreakLF]) {
            NSString *bufferedString = [textView getBufferString];
            [textView insertText:text];
            [self.virtualModel.inputPipe.fileHandleForWriting writeData:[[bufferedString stringByAppendingString:@NSStringLineBreakLF] dataUsingEncoding:NSUTF8StringEncoding]];
            if (self.logHandle) {
                NSData *logData = [[bufferedString stringByAppendingString:@NSStringLineBreakCRLF] dataUsingEncoding:NSUTF8StringEncoding];
                [self.logHandle writeData:logData];
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
    @weakify(self);
    dispatch_sync_on_main_queue(^{
        @strongify(self);
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
    if (!self.textView.isFirstResponder) {
        return;
    }
    
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
