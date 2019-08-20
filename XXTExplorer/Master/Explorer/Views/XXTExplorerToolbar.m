//
//  XXTExplorerToolbar.m
//  XXTExplorer
//
//  Created by Zheng on 28/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTExplorerToolbar.h"

@interface XXTExplorerToolbar ()

@property (nonatomic, strong, readonly) NSArray <UIBarButtonItem *> *defaultButtons;
@property (nonatomic, strong, readonly) NSArray <UIBarButtonItem *> *editingButtons;
@property (nonatomic, strong, readonly) NSArray <UIBarButtonItem *> *readonlyButtons;
@property (nonatomic, strong, readonly) NSDictionary <NSString *, NSArray <UIBarButtonItem *> *> *statusSeries;

@end

@implementation XXTExplorerToolbar

- (instancetype)init {
    if (self = [super init]) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setup];
    }
    return self;
}

- (void)setup {
    [[UIBarButtonItem appearanceWhenContainedIn:[self class], nil] setTintColor:XXTColorForeground()];
    
    if (@available(iOS 13.0, *)) {
        self.backgroundColor = [UIColor systemBackgroundColor];
    } else {
        self.backgroundColor = [UIColor whiteColor];
    }
    
    UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    fixedSpace.width = 20.0f;
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
#ifndef APPSTORE
    NSArray <NSString *> *buttonTypes =
    @[
      XXTExplorerToolbarButtonTypeScan,
      XXTExplorerToolbarButtonTypeCompress,
      XXTExplorerToolbarButtonTypeAddItem,
      XXTExplorerToolbarButtonTypeSort,
      XXTExplorerToolbarButtonTypeShare,
      XXTExplorerToolbarButtonTypePaste,
      XXTExplorerToolbarButtonTypeTrash
      ];
#else
    NSArray <NSString *> *buttonTypes =
    @[
      XXTExplorerToolbarButtonTypeSettings,
      XXTExplorerToolbarButtonTypeCompress,
      XXTExplorerToolbarButtonTypeAddItem,
      XXTExplorerToolbarButtonTypeSort,
      XXTExplorerToolbarButtonTypeShare,
      XXTExplorerToolbarButtonTypePaste,
      XXTExplorerToolbarButtonTypeTrash
      ];
#endif
    
    NSMutableDictionary <NSString *, UIBarButtonItem *> *buttons = [[NSMutableDictionary alloc] initWithCapacity:buttonTypes.count];
    for (NSString *buttonType in buttonTypes) {
        UIImage *itemImage = [UIImage imageNamed:[NSString stringWithFormat:@"%@-%@", buttonType, XXTExplorerToolbarButtonStatusNormal]];
        itemImage = [itemImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        UIButton *newButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 26.0, 26.0)];
        [newButton addTarget:self action:@selector(toolbarButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [newButton setImage:itemImage forState:UIControlStateNormal];
        UIBarButtonItem *newButtonItem = [[UIBarButtonItem alloc] initWithCustomView:newButton];
        [buttons setObject:newButtonItem
                    forKey:buttonType];
    }
    _buttons = buttons;
    
    if (@available(iOS 11.0, *)) {
#ifndef APPSTORE
        _defaultButtons =
        @[
          fixedSpace,
          buttons[XXTExplorerToolbarButtonTypeScan],
          flexibleSpace,
          buttons[XXTExplorerToolbarButtonTypeAddItem],
          flexibleSpace,
          buttons[XXTExplorerToolbarButtonTypePaste],
          flexibleSpace,
          buttons[XXTExplorerToolbarButtonTypeSort],
          fixedSpace,
          ];
#else
        _defaultButtons =
        @[
          fixedSpace,
          buttons[XXTExplorerToolbarButtonTypeAddItem],
          flexibleSpace,
          buttons[XXTExplorerToolbarButtonTypeSort],
          flexibleSpace,
          buttons[XXTExplorerToolbarButtonTypePaste],
          flexibleSpace,
          buttons[XXTExplorerToolbarButtonTypeSettings],
          fixedSpace,
          ];
#endif
        
        _editingButtons =
        @[
          fixedSpace,
          buttons[XXTExplorerToolbarButtonTypeShare],
          flexibleSpace,
          buttons[XXTExplorerToolbarButtonTypeCompress],
          flexibleSpace,
          buttons[XXTExplorerToolbarButtonTypePaste],
          flexibleSpace,
          buttons[XXTExplorerToolbarButtonTypeTrash],
          fixedSpace,
          ];
        
        _readonlyButtons =
        @[
          fixedSpace,
          flexibleSpace,
          buttons[XXTExplorerToolbarButtonTypeSort],
          flexibleSpace,
          fixedSpace,
          ];
    }
    else
    {
#ifndef APPSTORE
        _defaultButtons =
        @[
          buttons[XXTExplorerToolbarButtonTypeScan],
          flexibleSpace,
          buttons[XXTExplorerToolbarButtonTypeAddItem],
          flexibleSpace,
          buttons[XXTExplorerToolbarButtonTypePaste],
          flexibleSpace,
          buttons[XXTExplorerToolbarButtonTypeSort],
          ];
#else
        _defaultButtons =
        @[
          buttons[XXTExplorerToolbarButtonTypeAddItem],
          flexibleSpace,
          buttons[XXTExplorerToolbarButtonTypeSort],
          flexibleSpace,
          buttons[XXTExplorerToolbarButtonTypePaste],
          flexibleSpace,
          buttons[XXTExplorerToolbarButtonTypeSettings],
          ];
#endif
        
        _editingButtons =
        @[
          buttons[XXTExplorerToolbarButtonTypeShare],
          flexibleSpace,
          buttons[XXTExplorerToolbarButtonTypeCompress],
          flexibleSpace,
          buttons[XXTExplorerToolbarButtonTypePaste],
          flexibleSpace,
          buttons[XXTExplorerToolbarButtonTypeTrash],
          ];
        
        _readonlyButtons =
        @[
          flexibleSpace,
          buttons[XXTExplorerToolbarButtonTypeSort],
          flexibleSpace,
          ];
    }
    
    _statusSeries =
    @{
      XXTExplorerToolbarStatusDefault: self.defaultButtons,
      XXTExplorerToolbarStatusEditing: self.editingButtons,
      XXTExplorerToolbarStatusReadonly: self.readonlyButtons
      };
    
    [self updateStatus:XXTExplorerToolbarStatusDefault];
}

- (void)drawRect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    if (@available(iOS 13.0, *)) {
        CGContextSetStrokeColorWithColor(ctx, [UIColor separatorColor].CGColor);
    } else {
        CGContextSetRGBStrokeColor(ctx, 0.85, 0.85, 0.85, 1.0);
    }
    CGContextSetLineWidth(ctx, 1.0f);
    CGPoint aPoint[2] = {
#ifndef APPSTORE
        CGPointMake(0.0, CGRectGetHeight(self.frame)),
        CGPointMake(CGRectGetWidth(self.frame), CGRectGetHeight(self.frame))
#else
        CGPointMake(0.0, 0.0),
        CGPointMake(CGRectGetWidth(self.frame), 0.0)
#endif
    };
    CGContextAddLines(ctx, aPoint, 2);
    CGContextStrokePath(ctx);
}

- (void)updateStatus:(NSString *)status {
    for (NSString *buttonItemName in self.buttons) {
        UIBarButtonItem *button = self.buttons[buttonItemName];
        button.enabled = NO;
    }
    [self setItems:self.statusSeries[status] animated:YES];
}

- (void)updateButtonType:(NSString *)buttonType enabled:(BOOL)enabled {
    [self updateButtonType:buttonType status:nil enabled:enabled];
}

- (void)updateButtonType:(NSString *)buttonType status:(NSString *)buttonStatus enabled:(BOOL)enabled {
    UIBarButtonItem *buttonItem = self.buttons[buttonType];
    if (buttonStatus) {
        UIImage *statusImage = [UIImage imageNamed:[NSString stringWithFormat:@"%@-%@", buttonType, buttonStatus]];
        statusImage = [statusImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        if (statusImage) {
            UIButton *button = [buttonItem customView];
            [button setImage:statusImage forState:UIControlStateNormal];
        }
    }
    if (buttonItem.enabled != enabled) {
        [buttonItem setEnabled:enabled];
    }
}

#pragma mark - Button Tapped

- (void)toolbarButtonTapped:(UIButton *)button {
    if (_tapDelegate && [_tapDelegate respondsToSelector:@selector(toolbar:buttonTypeTapped:buttonItem:)]) {
        NSString *buttonType = nil;
        for (NSString *buttonKey in self.buttons) {
            UIBarButtonItem *buttonItem = self.buttons[buttonKey];
            if (buttonItem.customView == button) {
                buttonType = buttonKey;
                break;
            }
        }
        if (buttonType) {
            [_tapDelegate toolbar:self buttonTypeTapped:buttonType buttonItem:self.buttons[buttonType]];
        }
    }
}

@end
