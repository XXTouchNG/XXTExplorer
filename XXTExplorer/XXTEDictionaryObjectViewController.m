//
//  XXTEDictionaryObjectViewController.m
//  XXTExplorer
//
//  Created by Zheng on 01/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEDictionaryObjectViewController.h"
//#import "XUITitleValueCell.h"
//#import "XUI.h"
//#import "XUIStyle.h"
#import "XXTEMoreTitleValueCell.h"
#import "XXTEObjectViewController.h"
#import "NSObject+StringValue.h"
#import "XXTEBaseObjectViewController.h"
#import "XXTEUserInterfaceDefines.h"
#import <PromiseKit/PromiseKit.h>

@interface XXTEDictionaryObjectViewController ()

@property (nonatomic, strong, readonly) NSArray *allKeys;

@end

@implementation XXTEDictionaryObjectViewController {
    NSArray <Class> *supportedTypes;
}

@synthesize RootObject = _RootObject;

+ (NSArray <Class> *)supportedTypes {
    return @[ [NSDictionary class] ];
}

- (instancetype)initWithRootObject:(id)RootObject {
    if (self = [super init]) {
        _RootObject = RootObject;
        _allKeys = ((NSDictionary *)RootObject).allKeys;
        supportedTypes = [XXTEBaseObjectViewController supportedTypes];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([XXTEMoreTitleValueCell class]) bundle:[NSBundle mainBundle]] forCellReuseIdentifier:XXTEMoreTitleValueCellReuseIdentifier];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (0 == section) {
        return self.allKeys.count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0)
    {
        XXTEMoreTitleValueCell *cell =
        [tableView dequeueReusableCellWithIdentifier:XXTEMoreTitleValueCellReuseIdentifier];
        if (nil == cell)
        {
            cell = [[XXTEMoreTitleValueCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                 reuseIdentifier:XXTEMoreTitleValueCellReuseIdentifier];
        }
        cell.tintColor = XXTE_COLOR;
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        id pairKey = self.allKeys[indexPath.row];
        Class keyClass = [pairKey class];
        BOOL supportedKey = NO;
        for (Class supportedType in supportedTypes) {
            if ([keyClass isSubclassOfClass:supportedType]) {
                supportedKey = YES;
                break;
            }
        }
        if (supportedKey)
        {
            if ([pairKey isKindOfClass:[NSString class]]) {
                cell.titleLabel.text = [self.entryBundle localizedStringForKey:pairKey value:nil table:@"Meta"];
            } else {
                cell.titleLabel.text = [pairKey stringValue];
            }
        }
        else
        {
            cell.titleLabel.text = nil;
        }
        
        id pairValue = ((NSDictionary *)self.RootObject)[pairKey];
        Class valueClass = [pairValue class];
        BOOL supportedValue = NO;
        for (Class supportedType in supportedTypes) {
            if ([valueClass isSubclassOfClass:supportedType]) {
                supportedValue = YES;
                break;
            }
        }
        if (supportedValue)
        {
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.valueLabel.textColor = [UIColor grayColor];
            cell.valueLabel.text = [pairValue stringValue];
        }
        else
        {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            if ([pairValue respondsToSelector:@selector(count)]) {
                NSUInteger childCount = [pairValue count];
                cell.valueLabel.textColor = XXTE_COLOR;
                cell.valueLabel.text = [NSString stringWithFormat:@"(%@)", [@(childCount) stringValue]];
            }
        }
        
        return cell;
    }
    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (tableView == self.tableView) {
        if (0 == indexPath.section) {
            id pairKey = self.allKeys[indexPath.row];
            id pairValue = ((NSDictionary *)self.RootObject)[pairKey];
            Class valueClass = [pairValue class];
            BOOL supportedValue = NO;
            for (Class supportedType in supportedTypes) {
                if ([valueClass isSubclassOfClass:supportedType]) {
                    supportedValue = YES;
                    break;
                }
            }
            XXTEMoreTitleValueCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            if (supportedValue)
            {
                NSString *detailText = cell.valueLabel.text;
                if (detailText && detailText.length > 0) {
                    blockUserInteractions(self, YES, 0.2);
                    [PMKPromise new:^(PMKFulfiller fulfill, PMKRejecter reject) {
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                            [[UIPasteboard generalPasteboard] setString:detailText];
                            fulfill(nil);
                        });
                    }].finally(^() {
                        showUserMessage(self, NSLocalizedString(@"Copied to the pasteboard.", nil));
                        blockUserInteractions(self, NO, 0.2);
                    });
                }
            }
            else
            {
                XXTEObjectViewController *objectViewController = [[XXTEObjectViewController alloc] initWithRootObject:pairValue];
                objectViewController.title = cell.titleLabel.text;
                objectViewController.entryBundle = self.entryBundle;
                [self.navigationController pushViewController:objectViewController animated:YES];
            }
        }
    }
}

@end