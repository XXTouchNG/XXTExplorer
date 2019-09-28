//
//  XXTExplorerToolbar.h
//  XXTExplorer
//
//  Created by Zheng on 28/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XXTExplorerToolbarButtonItem.h"


static NSString * const XXTExplorerToolbarStatusDefault = @"XXTExplorerToolbarStatusDefault";
static NSString * const XXTExplorerToolbarStatusEditing = @"XXTExplorerToolbarStatusEditing";
static NSString * const XXTExplorerToolbarStatusReadonly = @"XXTExplorerToolbarStatusReadonly";
static NSString * const XXTExplorerToolbarStatusHistoryMode = @"XXTExplorerToolbarStatusHistoryMode";

#ifndef APPSTORE
    static NSString * const XXTExplorerToolbarButtonTypeScan = @"XXTExplorerToolbarButtonTypeScan";
#else
    static NSString * const XXTExplorerToolbarButtonTypeSettings = @"XXTExplorerToolbarButtonTypeSettings";
#endif
static NSString * const XXTExplorerToolbarButtonTypeCompress = @"XXTExplorerToolbarButtonTypeCompress";
static NSString * const XXTExplorerToolbarButtonTypeAddItem = @"XXTExplorerToolbarButtonTypeAddItem";
static NSString * const XXTExplorerToolbarButtonTypeSort = @"XXTExplorerToolbarButtonTypeSort";
static NSString * const XXTExplorerToolbarButtonTypeShare = @"XXTExplorerToolbarButtonTypeShare";
static NSString * const XXTExplorerToolbarButtonTypePaste = @"XXTExplorerToolbarButtonTypePaste";
static NSString * const XXTExplorerToolbarButtonTypeTrash = @"XXTExplorerToolbarButtonTypeTrash";

static NSString * const XXTExplorerToolbarButtonStatusNormal = @"Normal";
static NSString * const XXTExplorerToolbarButtonStatusSelected = @"Selected";

@class XXTExplorerToolbar, XXTExplorerToolbarButtonItem;

@protocol XXTExplorerToolbarDelegate <NSObject>

- (void)toolbar:(XXTExplorerToolbar *)toolbar buttonTypeTapped:(NSString *)buttonType buttonItem:(XXTExplorerToolbarButtonItem *)buttonItem;

@end

@interface XXTExplorerToolbar : UIToolbar

@property (nonatomic, weak) id <XXTExplorerToolbarDelegate> tapDelegate;
@property (nonatomic, strong, readonly) NSDictionary <NSString *, XXTExplorerToolbarButtonItem *> *buttons;

// toolbar status
- (void)updateStatus:(NSString *)status;

// button status
- (void)updateButtonType:(NSString *)buttonType toEnabled:(NSNumber *)enabledVal;
- (void)updateButtonType:(NSString *)buttonType toStatus:(XXTExplorerToolbarButtonItemStatus *)buttonStatus toEnabled:(NSNumber *)enabledVal;

@end
