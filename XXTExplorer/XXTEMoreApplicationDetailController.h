//
//  XXTEMoreApplicationDetailController.h
//  XXTExplorer
//
//  Created by Zheng Wu on 30/06/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

static NSString * const kXXTEMoreApplicationDetailKeyName = @"kXXTEMoreApplicationDetailKeyName";
static NSString * const kXXTEMoreApplicationDetailKeyBundleID = @"kXXTEMoreApplicationDetailKeyBundleID";
static NSString * const kXXTEMoreApplicationDetailKeyBundlePath = @"kXXTEMoreApplicationDetailKeyBundlePath";
static NSString * const kXXTEMoreApplicationDetailKeyContainerPath = @"kXXTEMoreApplicationDetailKeyContainerPath";
static NSString * const kXXTEMoreApplicationDetailKeyIconImage = @"kXXTEMoreApplicationDetailKeyIconImage";

@interface XXTEMoreApplicationDetailController : UITableViewController
@property (nonatomic, copy) NSDictionary *applicationDetail;

@end
