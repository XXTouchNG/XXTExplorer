//
//  XXTExplorerToolbar.h
//  XXTExplorer
//
//  Created by Zheng on 28/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

static NSString * const XXTExplorerToolbarStatusDefault = @"XXTExplorerToolbarStatusDefault";
static NSString * const XXTExplorerToolbarStatusEditing = @"XXTExplorerToolbarStatusEditing";
static NSString * const XXTExplorerToolbarStatusReadonly = @"XXTExplorerToolbarStatusReadonly";

static NSString * const XXTExplorerToolbarButtonTypeScan = @"XXTExplorerToolbarButtonTypeScan";
static NSString * const XXTExplorerToolbarButtonTypeCompress = @"XXTExplorerToolbarButtonTypeCompress";
static NSString * const XXTExplorerToolbarButtonTypeAddItem = @"XXTExplorerToolbarButtonTypeAddItem";
static NSString * const XXTExplorerToolbarButtonTypeSort = @"XXTExplorerToolbarButtonTypeSort";
static NSString * const XXTExplorerToolbarButtonTypeShare = @"XXTExplorerToolbarButtonTypeShare";
static NSString * const XXTExplorerToolbarButtonTypePaste = @"XXTExplorerToolbarButtonTypePaste";
static NSString * const XXTExplorerToolbarButtonTypeTrash = @"XXTExplorerToolbarButtonTypeTrash";

static NSString * const XXTExplorerToolbarButtonStatusNormal = @"Normal";
static NSString * const XXTExplorerToolbarButtonStatusSelected = @"Selected";

@class XXTExplorerToolbar;

@protocol XXTExplorerToolbarDelegate <NSObject>

- (void)toolbar:(XXTExplorerToolbar *)toolbar buttonTypeTapped:(NSString *)buttonType;

@end

@interface XXTExplorerToolbar : UIToolbar

@property (nonatomic, weak) id <XXTExplorerToolbarDelegate> tapDelegate;
@property (nonatomic, strong, readonly) NSDictionary <NSString *, UIBarButtonItem *> *buttons;

- (void)updateStatus:(NSString *)status;
- (void)updateButtonType:(NSString *)buttonType enabled:(BOOL)enabled;
- (void)updateButtonType:(NSString *)buttonType status:(NSString *)buttonStatus enabled:(BOOL)enabled;

@end
