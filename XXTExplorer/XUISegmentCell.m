//
//  XUISegmentCell.m
//  XXTExplorer
//
//  Created by Zheng on 30/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XUISegmentCell.h"
#import "XUILogger.h"

@interface XUISegmentCell ()

@property (weak, nonatomic) IBOutlet UISegmentedControl *xui_segmentControl;

@end

@implementation XUISegmentCell

@synthesize xui_value = _xui_value;

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
    return NO;
}

+ (NSDictionary <NSString *, Class> *)entryValueTypes {
    return
    @{
      @"validTitles": [NSArray class],
      @"validValues": [NSArray class],
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
    
    [self.xui_segmentControl addTarget:self action:@selector(xuiSegmentValueChanged:) forControlEvents:UIControlEventValueChanged];
}

- (void)setXui_validTitles:(NSArray <NSString *> *)xui_validTitles {
    _xui_validTitles = xui_validTitles;
    [self.xui_segmentControl removeAllSegments];
    NSUInteger titleIdx = 0;
    for (NSString *validTitle in xui_validTitles) {
        [self.xui_segmentControl insertSegmentWithTitle:validTitle atIndex:titleIdx animated:NO];
        titleIdx++;
    }
    if (self.xui_value) {
        NSInteger selectedIdx = [self.xui_value integerValue];
        [self.xui_segmentControl setSelectedSegmentIndex:selectedIdx];
    }
}

- (void)setXui_value:(id)xui_value {
    _xui_value = xui_value;
    if (xui_value) {
        NSUInteger selectedIndex = [self.xui_validValues indexOfObject:xui_value];
        if (selectedIndex != NSNotFound) {
            if (self.xui_segmentControl.numberOfSegments > selectedIndex) {
                [self.xui_segmentControl setSelectedSegmentIndex:selectedIndex];
            }
        }
    }
}

- (IBAction)xuiSegmentValueChanged:(UISegmentedControl *)sender {
    if (sender == self.xui_segmentControl) {
        NSUInteger selectedIndex = sender.selectedSegmentIndex;
        if (selectedIndex < self.xui_validValues.count) {
            id selectedValue = self.xui_validValues[selectedIndex];
            self.xui_value = selectedValue;
            [self.defaultsService saveDefaultsFromCell:self];
        }
    }
}

@end
