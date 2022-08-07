//
//  XXTExplorerToolbar.m
//  XXTExplorer
//
//  Created by Zheng on 28/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTExplorerToolbar.h"
#import "XXTExplorerToolbarButtonItem.h"
#import "UIImage+ColoredImage.h"


@interface XXTExplorerToolbar () <XXTExplorerToolbarButtonItemDelegate>

@property (nonatomic, strong, readonly) NSArray <XXTExplorerToolbarButtonItem *> *defaultButtons;
@property (nonatomic, strong, readonly) NSArray <XXTExplorerToolbarButtonItem *> *editingButtons;
@property (nonatomic, strong, readonly) NSArray <XXTExplorerToolbarButtonItem *> *readonlyButtons;
@property (nonatomic, strong, readonly) NSArray <XXTExplorerToolbarButtonItem *> *historyButtons;
@property (nonatomic, strong, readonly) NSDictionary <NSString *, NSArray <XXTExplorerToolbarButtonItem *> *> *statusSeries;

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
    [[XXTExplorerToolbarButtonItem appearanceWhenContainedInInstancesOfClasses:@[[self class]]] setTintColor:XXTColorForeground()];
    
    self.backgroundColor = XXTColorPlainBackground();
    
    XXTExplorerToolbarButtonItem *fixedSpace = [[XXTExplorerToolbarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    fixedSpace.width = 20.0f;
    XXTExplorerToolbarButtonItem *flexibleSpace = [[XXTExplorerToolbarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
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
    
    NSMutableDictionary <NSString *, XXTExplorerToolbarButtonItem *> *buttons = [[NSMutableDictionary alloc] initWithCapacity:buttonTypes.count];
    for (NSString *buttonType in buttonTypes) {
        XXTExplorerToolbarButtonItem *newButtonItem = [[XXTExplorerToolbarButtonItem alloc] initWithName:buttonType andActionReceiver:self];
        [buttons setObject:newButtonItem
                    forKey:buttonType];
    }
    _buttons = buttons;
    
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
    
    _historyButtons =
    @[
        fixedSpace,
        flexibleSpace,
        buttons[XXTExplorerToolbarButtonTypeTrash],
        flexibleSpace,
        fixedSpace,
    ];
    
    _statusSeries =
    @{
        XXTExplorerToolbarStatusDefault: self.defaultButtons,
        XXTExplorerToolbarStatusEditing: self.editingButtons,
        XXTExplorerToolbarStatusReadonly: self.readonlyButtons,
        XXTExplorerToolbarStatusHistoryMode: self.historyButtons,
    };
}

- (void)drawRect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    CGContextSetStrokeColorWithColor(ctx, [UIColor separatorColor].CGColor);
    CGContextSetLineWidth(ctx, 1.0f);
    CGPoint aPoint[2] = {
        CGPointMake(0.0, CGRectGetHeight(self.frame)),
        CGPointMake(CGRectGetWidth(self.frame), CGRectGetHeight(self.frame))
    };
    CGContextAddLines(ctx, aPoint, 2);
    CGContextStrokePath(ctx);
}

- (void)updateStatus:(NSString *)status {
    for (NSString *buttonItemName in self.buttons) {
        XXTExplorerToolbarButtonItem *button = self.buttons[buttonItemName];
        button.enabled = NO;
    }
    [self setItems:self.statusSeries[status] animated:YES];
}

- (void)updateButtonType:(NSString *)buttonType toEnabled:(NSNumber *)enabled {
    [self updateButtonType:buttonType toStatus:nil toEnabled:enabled];
}

- (void)updateButtonType:(NSString *)buttonType toStatus:(XXTExplorerToolbarButtonItemStatus *)buttonStatus toEnabled:(NSNumber *)enabledVal {
    [self updateButtonType:buttonType toStatus:buttonStatus toEnabled:enabledVal toTraitCollection:self.traitCollection];
}

- (void)updateButtonType:(NSString *)buttonType toStatus:(XXTExplorerToolbarButtonItemStatus *)buttonStatus toEnabled:(NSNumber *)enabledVal toTraitCollection:(UITraitCollection *)traitCollection {
    
    XXTExplorerToolbarButtonItem *buttonItem = self.buttons[buttonType];
    
    if (buttonStatus) {
        [buttonItem setStatus:buttonStatus forTraitCollection:traitCollection];
    } else {
        if (traitCollection) {
            [buttonItem updateButtonStatusForTraitCollection:traitCollection];
        }
    }
    
    if (enabledVal) {
        if (buttonItem.enabled != [enabledVal boolValue]) {
            [buttonItem setEnabled:[enabledVal boolValue]];
        }
    }
    
}

#pragma mark - Button Tapped

- (void)toolbarButtonTapped:(UIButton *)button {
    if (_tapDelegate && [_tapDelegate respondsToSelector:@selector(toolbar:buttonTypeTapped:buttonItem:)]) {
        NSString *buttonType = nil;
        for (NSString *buttonKey in self.buttons) {
            XXTExplorerToolbarButtonItem *buttonItem = self.buttons[buttonKey];
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

#pragma mark - Redraw

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    for (NSString *buttonItemName in self.buttons) {
        [self updateButtonType:buttonItemName toStatus:nil toEnabled:nil toTraitCollection:self.traitCollection];
    }
}

@end
