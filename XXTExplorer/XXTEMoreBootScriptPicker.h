//
//  XXTEMoreBootScriptPicker.h
//  XXTExplorer
//
//  Created by Zheng on 09/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTExplorerViewController.h"

@class XXTEMoreBootScriptPicker;

@protocol XXTEMoreBootScriptPickerDelegate <NSObject>

@optional
- (void)bootScriptPicker:(XXTEMoreBootScriptPicker *)picker didSelectedBootScriptPath:(NSString *)path;

@end

@interface XXTEMoreBootScriptPicker : XXTExplorerViewController

@property (nonatomic, strong) NSString *selectedBootScriptPath;

@property (nonatomic, weak) id <XXTEMoreBootScriptPickerDelegate> delegate;
@property (nonatomic, copy) NSArray <NSString *> *allowedExtensions;
@property (nonatomic, assign, readonly) BOOL allowsMultipleSelection; // not implemented

@end
