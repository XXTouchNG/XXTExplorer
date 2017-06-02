//
//  XXTExplorerViewController.h
//  XXTExplorer
//
//  Created by Zheng on 25/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XXTExplorerViewController : UIViewController

@property (nonatomic, copy, readonly) NSString *entryPath;
//@property (nonatomic, strong, readonly) NSUserDefaults *explorerDefaults;
//@property (nonatomic, copy, readonly) NSDictionary *explorerBuiltInDefaults;
// @property (nonatomic, strong, readonly) NSFileManager *explorerFileManager;
//@property (nonatomic, strong, readonly) NSDateFormatter *explorerDateFormatter;

+ (NSString *)rootPath;
+ (NSFileManager *)explorerFileManager;
+ (NSDateFormatter *)explorerDateFormatter;
+ (NSUserDefaults *)explorerDefaults;
+ (NSDictionary *)explorerBuiltInDefaults;

- (instancetype)initWithEntryPath:(NSString *)path;

@end
