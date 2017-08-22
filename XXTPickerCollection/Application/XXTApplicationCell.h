//
//  XXTApplicationCell.h
//  XXTPickerCollection
//
//  Created by Zheng on 03/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

static NSString * const kXXTApplicationCellReuseIdentifier = @"kXXTApplicationCellReuseIdentifier";

static NSString * const kXXTApplicationDetailKeyName = @"kXXTApplicationDetailKeyName";
static NSString * const kXXTApplicationDetailKeyBundleID = @"kXXTApplicationDetailKeyBundleID";
static NSString * const kXXTApplicationDetailKeyBundlePath = @"kXXTApplicationDetailKeyBundlePath";
static NSString * const kXXTApplicationDetailKeyContainerPath = @"kXXTApplicationDetailKeyContainerPath";
static NSString * const kXXTApplicationDetailKeyIconImage = @"kXXTApplicationDetailKeyIconImage";

@interface XXTApplicationCell : UITableViewCell

- (void)setApplicationName:(NSString *)name;

- (NSString *)applicationBundleID;
- (void)setApplicationBundleID:(NSString *)bundleID;

- (void)setApplicationIconImage:(UIImage *)image;

@end
