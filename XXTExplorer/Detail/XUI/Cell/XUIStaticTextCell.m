//
//  XUIStaticTextCell.m
//  XXTExplorer
//
//  Created by Zheng on 29/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XUIStaticTextCell.h"
#import "XUILogger.h"

@interface XUIStaticTextCell ()

@property (weak, nonatomic) IBOutlet UITextView *cellStaticTextView;

@end

@implementation XUIStaticTextCell

+ (BOOL)xibBasedLayout {
    return YES;
}

+ (BOOL)layoutNeedsTextLabel {
    return NO;
}

+ (BOOL)layoutNeedsImageView {
    return NO;
}

+ (BOOL)layoutRequiresDynamicRowHeight {
    return YES;
}

+ (NSDictionary <NSString *, Class> *)entryValueTypes {
    return
    @{
      @"alignment": [NSString class],
      @"selectable": [NSNumber class],
      };
}

+ (BOOL)checkEntry:(NSDictionary *)cellEntry withError:(NSError **)error {
    BOOL superResult = [super checkEntry:cellEntry withError:error];
    NSString *checkType = kXUICellFactoryErrorDomain;
    @try {
        NSString *alignmentString = cellEntry[@"alignment"];
        if (alignmentString) {
            NSArray <NSString *> *validAlignment = @[ @"left", @"right", @"center", @"natural", @"justified" ];
            if (![validAlignment containsObject:alignmentString]) {
                superResult = NO;
                checkType = kXUICellFactoryErrorUnknownEnumDomain;
                @throw [NSString stringWithFormat:NSLocalizedString(@"key \"alignment\" (\"%@\") is invalid.", nil), alignmentString];
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
    self.selectionStyle = UITableViewCellSelectionStyleNone;
}

- (void)setXui_label:(NSString *)xui_label {
    [super setXui_label:xui_label];
    self.cellStaticTextView.text = xui_label;
}

- (void)setXui_alignment:(NSString *)xui_alignment {
    _xui_alignment = xui_alignment;
    if ([xui_alignment isEqualToString:@"left"]) {
        self.cellStaticTextView.textAlignment = NSTextAlignmentLeft;
    }
    else if ([xui_alignment isEqualToString:@"center"]) {
        self.cellStaticTextView.textAlignment = NSTextAlignmentCenter;
    }
    else if ([xui_alignment isEqualToString:@"right"]) {
        self.cellStaticTextView.textAlignment = NSTextAlignmentRight;
    }
    else if ([xui_alignment isEqualToString:@"natural"]) {
        self.cellStaticTextView.textAlignment = NSTextAlignmentNatural;
    }
    else if ([xui_alignment isEqualToString:@"justified"]) {
        self.cellStaticTextView.textAlignment = NSTextAlignmentJustified;
    }
    else {
        self.cellStaticTextView.textAlignment = NSTextAlignmentNatural;
    }
}

- (void)setXui_selectable:(NSNumber *)xui_selectable {
    _xui_selectable = xui_selectable;
    self.cellStaticTextView.selectable = [xui_selectable boolValue];
}

- (void)setTheme:(XUITheme *)theme {
    [super setTheme:theme];
    self.cellStaticTextView.textColor = theme.labelColor;
    self.cellStaticTextView.tintColor = theme.tintColor;
}

@end
