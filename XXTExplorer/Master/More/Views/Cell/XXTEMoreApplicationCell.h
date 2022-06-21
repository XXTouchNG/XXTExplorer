//
//  XXTEMoreApplicationCell.h
//  XXTPickerCollection
//
//  Created by Zheng on 03/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

static NSString * const kXXTEMoreApplicationCellReuseIdentifier = @"kXXTEMoreApplicationCellReuseIdentifier";
static CGFloat const XXTEMoreApplicationCellHeight = 68.f;

@interface XXTEMoreApplicationCell : UITableViewCell

- (NSString *)applicationName;
- (void)setApplicationName:(NSString *)name;

- (NSString *)applicationBundleID;
- (void)setApplicationBundleID:(NSString *)bundleID;

- (void)setApplicationIconImage:(UIImage *)image;
- (void)setSearchText:(NSString *)searchText;

@end
