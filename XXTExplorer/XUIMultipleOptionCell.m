//
//  XUIMultipleOptionCell.m
//  XXTExplorer
//
//  Created by Zheng on 30/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XUIMultipleOptionCell.h"
#import "XUI.h"
#import "XUILogger.h"

@implementation XUIMultipleOptionCell

+ (BOOL)xibBasedLayout {
    return YES;
}

+ (BOOL)layoutNeedsTextLabel {
    return YES;
}

+ (BOOL)layoutNeedsImageView {
    return YES;
}

+ (BOOL)layoutRequiresDynamicRowHeight {
    return NO;
}

+ (NSDictionary <NSString *, Class> *)entryValueTypes {
    return
    @{
      @"validTitles": [NSArray class],
      @"validValues": [NSArray class],
      @"maxCount": [NSNumber class],
      @"staticTextMessage": [NSString class],
      @"value": [NSArray class]
      };
}

+ (BOOL)checkEntry:(NSDictionary *)cellEntry withError:(NSError **)error {
    BOOL superResult = [super checkEntry:cellEntry withError:error];
    NSString *checkType = kXUICellFactoryErrorDomain;
    @try {
        NSArray *validTitles = cellEntry[@"validTitles"];
        NSArray *validValues = cellEntry[@"validValues"];
        if (validTitles && validValues) {
            if (validTitles.count != validValues.count) {
                superResult = NO;
                checkType = kXUICellFactoryErrorSizeDismatchDomain;
                @throw [NSString stringWithFormat:NSLocalizedString(@"The size of \"%@\" and \"%@\" does not match.", nil), @"validTitles", @"validValues"];
            }
        }
        for (NSString *validTitle in validTitles) {
            if (![validTitle isKindOfClass:[NSString class]]) {
                superResult = NO;
                checkType = kXUICellFactoryErrorInvalidTypeDomain;
                @throw [NSString stringWithFormat:NSLocalizedString(@"The member type of \"%@\" should be \"%@\".", nil), @"validTitles", @"NSString"];
            }
        }
    } @catch (NSString *exceptionReason) {
        NSError *exceptionError = [NSError errorWithDomain:checkType code:400 userInfo:@{ NSLocalizedDescriptionKey: exceptionReason }];
        if (error) {
            *error = exceptionError;
        }
    } @finally {
        
    }
    return superResult;
}

- (void)setupCell {
    [super setupCell];
    self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    XUI_START_IGNORE_PARTIAL
    if (XUI_SYSTEM_9) {
        self.detailTextLabel.font = [UIFont systemFontOfSize:17.f weight:UIFontWeightLight];
    }
    XUI_END_IGNORE_PARTIAL
    self.detailTextLabel.textColor = UIColor.grayColor;
    self.detailTextLabel.text = nil;
}

@end
