//
//  XXTETextEditorController.m
//  XXTExplorer
//
//  Created by Zheng Wu on 10/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTETextEditorController.h"
#import "XXTECodeViewerController.h"

#import "XXTETextEditorView.h"
#import <Masonry/Masonry.h>

#import "SKHelper.h"

@interface XXTETextEditorController () <UITextViewDelegate>

@property (nonatomic, strong) XXTETextEditorView *textView;

@end

@implementation XXTETextEditorController

@synthesize entryPath = _entryPath;

+ (NSString *)editorName {
    return NSLocalizedString(@"Text Editor", nil);
}

+ (NSArray <NSString *> *)suggestedExtensions {
    return [XXTECodeViewerController suggestedExtensions];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (instancetype)initWithPath:(NSString *)path {
    if (self = [super init]) {
        _entryPath = path;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configure];
    [self configureSubviews];
    [self configureConstraints];
    
    // Test
    NSAttributedString *attributedString = [SKHelper test:self.entryPath];
    self.textView.attributedText = attributedString;
}

- (void)configure {
    NSString *entryPath = self.entryPath;
    if (entryPath) {
        NSString *entryName = [entryPath lastPathComponent];
        self.title = entryName;
    }
    self.view.backgroundColor = [UIColor whiteColor];
}

- (void)configureSubviews {
    [self.view addSubview:self.textView];
}

- (void)configureConstraints {
    [self.textView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
}

#pragma mark - UIView Getters

- (XXTETextEditorView *)textView {
    if (!_textView) {
        XXTETextEditorView *textView = [[XXTETextEditorView alloc] init];
        textView.delegate = self;
        textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        textView.selectable = YES;
        textView.editable = NO; // default is NO
        textView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
        _textView = textView;
    }
    return _textView;
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [XXTETextEditorController dealloc]");
#endif
}

@end
