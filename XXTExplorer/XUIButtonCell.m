//
//  XUIButtonCell.m
//  XXTExplorer
//
//  Created by Zheng on 29/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XUIButtonCell.h"
#import "XUIStyle.h"

@interface XUIButtonCell ()

@property (weak, nonatomic) IBOutlet UILabel *xui_button_label;

@end

@implementation XUIButtonCell

+ (BOOL)xibBasedLayout {
    return NO;
}

+ (BOOL)layoutNeedsTextLabel {
    return YES;
}

+ (BOOL)layoutNeedsImageView {
    return YES;
}

+ (NSDictionary <NSString *, Class> *)entryValueTypes {
    return
    @{
      @"action": [NSString class],
      @"kwargs": [NSArray class]
      };
}

+ (BOOL)checkEntry:(NSDictionary *)cellEntry withError:(NSError **)error {
    BOOL superResult = [super checkEntry:cellEntry withError:error];
    return superResult;
}

- (void)setupCell {
    [super setupCell];
    self.selectionStyle = UITableViewCellSelectionStyleDefault;
    self.textLabel.textColor = XUI_COLOR;
}

@end