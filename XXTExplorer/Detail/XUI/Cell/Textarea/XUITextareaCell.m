//
//  XUITextareaCell.m
//  XXTExplorer
//
//  Created by Zheng on 10/09/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XUITextareaCell.h"
#import "XUI.h"
#import "XUILogger.h"

@implementation XUITextareaCell

+ (BOOL)xibBasedLayout {
    return NO;
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
    return @{ };
}

+ (BOOL)testEntry:(NSDictionary *)cellEntry withError:(NSError **)error {
    BOOL superResult = [super testEntry:cellEntry withError:error];
    NSString *checkType = kXUICellFactoryErrorDomain;
    @try {
        NSString *alignmentString = cellEntry[@"alignment"];
        if (alignmentString) {
            NSArray <NSString *> *validAlignment = @[ @"left", @"right", @"center", @"natural", @"justified" ];
            if (![validAlignment containsObject:alignmentString]) {
                superResult = NO;
                checkType = kXUICellFactoryErrorUnknownEnumDomain;
                @throw [NSString stringWithFormat:NSLocalizedString(@"key \"%@\" (\"%@\") is invalid.", nil), @"alignment", alignmentString];
            }
        }
        NSString *keyboardString = cellEntry[@"keyboard"];
        if (keyboardString) {
            NSArray <NSString *> *validKeyboard = @[ @"numbers", @"phone", @"ascii", @"default" ];
            if (![validKeyboard containsObject:keyboardString]) {
                superResult = NO;
                checkType = kXUICellFactoryErrorUnknownEnumDomain;
                @throw [NSString stringWithFormat:NSLocalizedString(@"key \"%@\" (\"%@\") is invalid.", nil), @"keyboard", keyboardString];
            }
        }
        NSString *autoCapsString = cellEntry[@"autoCaps"];
        if (autoCapsString) {
            NSArray <NSString *> *validAutoCaps = @[ @"sentences", @"words", @"all", @"none" ];
            if (![validAutoCaps containsObject:autoCapsString]) {
                superResult = NO;
                checkType = kXUICellFactoryErrorUnknownEnumDomain;
                @throw [NSString stringWithFormat:NSLocalizedString(@"key \"%@\" (\"%@\") is invalid.", nil), @"autoCaps", autoCapsString];
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
}

@end
