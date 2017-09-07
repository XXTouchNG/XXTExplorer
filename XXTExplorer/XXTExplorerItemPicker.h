//
//  XXTExplorerItemPicker.h
//  XXTExplorer
//
//  Created by Zheng on 09/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTExplorerViewController+SharedInstance.h"

@class XXTExplorerItemPicker;

@protocol XXTExplorerItemPickerDelegate <NSObject>

@optional
- (void)itemPickerDidCancelSelectingItem:(XXTExplorerItemPicker *)picker;
- (void)itemPicker:(XXTExplorerItemPicker *)picker didSelectedItemAtPath:(NSString *)path;

@end

@interface XXTExplorerItemPicker : XXTExplorerViewController

@property (nonatomic, strong) NSString *selectedBootScriptPath;

@property (nonatomic, weak) id <XXTExplorerItemPickerDelegate> delegate;
@property (nonatomic, copy) NSArray <NSString *> *allowedExtensions;
@property (nonatomic, assign, readonly) BOOL allowsMultipleSelection; // not implemented

@end
