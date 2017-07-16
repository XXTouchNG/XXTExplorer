//
//  XXTExplorerItemDetailObjectViewController.m
//  XXTExplorer
//
//  Created by Zheng on 15/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTExplorerItemDetailObjectViewController.h"
#import "XXTEMoreTitleValueCell.h"
#import "XXTEMoreLinkNoIconCell.h"
#import <PromiseKit/PromiseKit.h>
#import "XXTEUserInterfaceDefines.h"
#import "XXTEDispatchDefines.h"

@interface XXTExplorerItemDetailObjectViewController ()

@property (nonatomic, strong) NSArray <NSString *> *objectDictionaryKeys;
@property (nonatomic, strong) NSArray *objectDictionaryValues;
@property (nonatomic, strong) NSArray *objectArray;

@end

@implementation XXTExplorerItemDetailObjectViewController

- (instancetype)initWithDetailObject:(id)detailObject {
    if (self = [super initWithStyle:UITableViewStyleGrouped]) {
        _detailObject = detailObject;
        [self setup];
    }
    return self;
}

- (void)setup {
    if ([self.detailObject isKindOfClass:[NSArray class]]) {
        self.objectArray = self.detailObject;
    } else if ([self.detailObject isKindOfClass:[NSDictionary class]]) {
        NSDictionary *detailDictionary = self.detailObject;
        NSArray <NSString *> *allKeys = [[detailDictionary allKeys] sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
            return [obj1 compare:obj2];
        }];
        NSMutableArray *allValues = [[NSMutableArray alloc] initWithCapacity:allKeys.count];
        [allKeys enumerateObjectsUsingBlock:^(NSString * _Nonnull thisKey, NSUInteger idx, BOOL * _Nonnull stop) {
            [allValues addObject:detailDictionary[thisKey]];
        }];
        self.objectDictionaryKeys = allKeys;
        self.objectDictionaryValues = [[NSArray alloc] initWithArray:allValues];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.estimatedRowHeight = UITableViewAutomaticDimension;
    self.tableView.rowHeight = 44.f;
    
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([XXTEMoreTitleValueCell class]) bundle:[NSBundle mainBundle]] forCellReuseIdentifier:XXTEMoreTitleValueCellReuseIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([XXTEMoreLinkNoIconCell class]) bundle:[NSBundle mainBundle]] forCellReuseIdentifier:XXTEMoreLinkNoIconCellReuseIdentifier];
    
}

#pragma mark - UITableViewDelegate && UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.objectDictionaryKeys || self.objectArray) {
        return 1;
    }
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.objectDictionaryKeys) {
        return self.objectDictionaryKeys.count;
    }
    else if (self.objectArray) {
        return self.objectArray.count;
    }
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    XXTEMoreLinkNoIconCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if ([cell isKindOfClass:[XXTEMoreTitleValueCell class]]) {
        NSString *detailText = ((XXTEMoreTitleValueCell *)cell).valueLabel.text;
        if (detailText && detailText.length > 0) {
            blockUserInteractions(self, YES);
            [PMKPromise new:^(PMKFulfiller fulfill, PMKRejecter reject) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                    [[UIPasteboard generalPasteboard] setString:detailText];
                    fulfill(nil);
                });
            }].finally(^() {
                showUserMessage(self, NSLocalizedString(@"Copied to the pasteboard.", nil));
                blockUserInteractions(self, NO);
            });
        }
    }
    else if ([cell isKindOfClass:[XXTEMoreLinkNoIconCell class]]) {
        id object = nil;
        if (self.objectDictionaryKeys) {
            object = self.objectDictionaryValues[indexPath.row];
        } else if (self.objectArray) {
            object = self.objectArray[indexPath.row];
        }
        XXTExplorerItemDetailObjectViewController *objectViewController = [[XXTExplorerItemDetailObjectViewController alloc] initWithDetailObject:object];
        objectViewController.entryBundle = self.entryBundle;
        objectViewController.title = cell.titleLabel.text;
        [self.navigationController pushViewController:objectViewController animated:YES];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSBundle *entryBundle = self.entryBundle;
    if (self.objectDictionaryKeys) {
        XXTEMoreTitleValueCell *cell = [tableView dequeueReusableCellWithIdentifier:XXTEMoreTitleValueCellReuseIdentifier];
        NSString *cellTitle = self.objectDictionaryKeys[indexPath.row];
        if (cellTitle) {
            cell.titleLabel.text = [entryBundle localizedStringForKey:cellTitle value:@"" table:@"Meta"];
        }
        id cellValue = self.objectDictionaryValues[indexPath.row];
        if ([cellValue isKindOfClass:[NSString class]]) {
            cell.valueLabel.text = cellValue;
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        else if ([cellValue isKindOfClass:[NSNumber class]]) {
            cell.valueLabel.text = [cellValue stringValue];
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        else if ([cellValue isKindOfClass:[NSArray class]] || [cellValue isKindOfClass:[NSDictionary class]]) {
            cell.valueLabel.text = @"";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        return cell;
    } else if (self.objectArray) {
        XXTEMoreLinkNoIconCell *cell = [tableView dequeueReusableCellWithIdentifier:XXTEMoreLinkNoIconCellReuseIdentifier];
        id cellTitle = self.objectArray[indexPath.row];
        if ([cellTitle isKindOfClass:[NSString class]]) {
            cell.titleLabel.text = cellTitle;
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        else if ([cellTitle isKindOfClass:[NSNumber class]]) {
            cell.titleLabel.text = [cellTitle stringValue];
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        else if ([cellTitle isKindOfClass:[NSArray class]] || [cellTitle isKindOfClass:[NSDictionary class]]) {
            cell.titleLabel.text = [NSString stringWithFormat:[entryBundle localizedStringForKey:@"Item %ld" value:@"" table:@"Meta"], indexPath.row];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        return cell;
    }
    return [UITableViewCell new];
}

@end
