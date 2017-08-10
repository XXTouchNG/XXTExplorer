//
//  XXTETextEditorController.m
//  XXTExplorer
//
//  Created by Zheng Wu on 10/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTETextEditorController.h"
#import "XXTECodeViewerController.h"

@interface XXTETextEditorController ()

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
    
}

- (void)configureConstraints {
    
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [XXTETextEditorController dealloc]");
#endif
}

@end
