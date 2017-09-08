//
//  XXTEBaseObjectViewController.m
//  XXTExplorer
//
//  Created by Zheng on 01/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEBaseObjectViewController.h"
//#import "XUITitleValueCell.h"
//#import "XUIStaticTextCell.h"
#import "XXTEMoreTitleValueCell.h"
#import "NSObject+StringValue.h"
#import "XXTEUserInterfaceDefines.h"
#import <PromiseKit/PromiseKit.h>

@interface XXTEBaseObjectViewController ()

@property (nonatomic, strong) XXTEMoreTitleValueCell *singleValueCell;

@end

@implementation XXTEBaseObjectViewController

@synthesize RootObject = _RootObject;

+ (NSArray <Class> *)supportedTypes {
    return @[ [NSString class], [NSURL class], [NSNumber class], [NSData class], [NSDate class], [NSNull class] ];
}

- (instancetype)initWithRootObject:(id)RootObject {
    if (self = [super init]) {
        _RootObject = RootObject;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _singleValueCell = ({
        id Object = self.RootObject;
        XXTEMoreTitleValueCell *cell = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
        cell.titleLabel.text = [self.entryBundle localizedStringForKey:@"Value" value:nil table:@"Meta"];
        cell.valueLabel.text = [Object stringValue];
        cell;
    });
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (0 == section) {
        return 1;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
        if (indexPath.section == 0) {
            return self.singleValueCell;
        }
    }
    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (XXTE_SYSTEM_8) {
        return UITableViewAutomaticDimension;
    } else {
        UITableViewCell *cell = self.singleValueCell;
        [cell setNeedsUpdateConstraints];
        [cell updateConstraintsIfNeeded];
        
        cell.bounds = CGRectMake(0.0f, 0.0f, CGRectGetWidth(tableView.bounds), CGRectGetHeight(cell.bounds));
        [cell setNeedsLayout];
        [cell layoutIfNeeded];
        
        CGFloat height = [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
        return (height > 0) ? (height + 1.0) : 44.f;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (tableView == self.tableView) {
        if (0 == indexPath.section) {
            XXTEMoreTitleValueCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            NSString *detailText = cell.valueLabel.text;
            if (detailText && detailText.length > 0) {
                blockUserInteractions(self, YES, 2.0);
                [PMKPromise new:^(PMKFulfiller fulfill, PMKRejecter reject) {
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                        [[UIPasteboard generalPasteboard] setString:detailText];
                        fulfill(nil);
                    });
                }].finally(^() {
                    showUserMessage(self, NSLocalizedString(@"Copied to the pasteboard.", nil));
                    blockUserInteractions(self, NO, 2.0);
                });
            }
        }
    }
}

@end
