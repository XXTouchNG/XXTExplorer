//
//  XXTEBaseObjectViewController.m
//  XXTExplorer
//
//  Created by Zheng on 01/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEBaseObjectViewController.h"
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
    return [NSObject baseTypes];
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
        cell.titleLabel.text = NSLocalizedString(@"Value", nil);
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
    return 44.f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (tableView == self.tableView) {
        if (0 == indexPath.section) {
            XXTEMoreTitleValueCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            NSString *detailText = cell.valueLabel.text;
            if (detailText && detailText.length > 0) {
                blockInteractions(self, YES);;
                [PMKPromise new:^(PMKFulfiller fulfill, PMKRejecter reject) {
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                        [[UIPasteboard generalPasteboard] setString:detailText];
                        fulfill(nil);
                    });
                }].finally(^() {
                    toastMessage(self, NSLocalizedString(@"Copied to the pasteboard.", nil));
                    blockInteractions(self, NO);;
                });
            }
        }
    }
}

@end
