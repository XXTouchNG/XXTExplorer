//
//  XXTExplorerEntryParser.h
//  XXTExplorer
//
//  Created by Zheng on 28/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XXTExplorerEntryParser : NSObject

+ (NSArray <NSString *> *)internalLauncherExtensions;
+ (NSArray <NSString *> *)internalArchiverExtensions;
+ (NSDateFormatter *)entryDateFormatter;
- (NSDictionary *)entryOfPath:(NSString *)path withError:(NSError **)error;

@end
