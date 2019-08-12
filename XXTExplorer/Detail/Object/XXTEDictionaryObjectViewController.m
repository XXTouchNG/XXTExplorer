//
//  XXTEDictionaryObjectViewController.m
//  XXTExplorer
//
//  Created by Zheng on 01/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEDictionaryObjectViewController.h"
#import "XXTEMoreTitleValueCell.h"
#import "XXTEObjectViewController.h"
#import "NSObject+XUIStringValue.h"
#import "XXTEBaseObjectViewController.h"
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44.f;
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
        [self configureCell:cell forRowAtIndexPath:indexPath];
        
        return cell;
    }
    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

- (void)configureCell:(XXTEMoreTitleValueCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.tintColor = XXTColorForeground();
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSBundle *entryBundle = self.entryBundle;
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
        if (self.entryBundle && [pairKey isKindOfClass:[NSString class]]) {
            NSString *localizedKey = [mainBundle localizedStringForKey:(pairKey) value:nil table:(@"Meta")];
            if (!localizedKey)
                localizedKey = [entryBundle localizedStringForKey:(pairKey) value:nil table:(@"Meta")];
            cell.titleLabel.text = localizedKey;
        } else {
            cell.titleLabel.text = [pairKey xui_stringValue];
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
        if (@available(iOS 13.0, *)) {
            cell.valueLabel.textColor = [UIColor secondaryLabelColor];
        } else {
            cell.valueLabel.textColor = [UIColor darkGrayColor];
        }
        cell.valueLabel.text = [pairValue xui_stringValue];
    }
    else
    {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        if (self.containerDisplayMode == XXTEObjectContainerDisplayModeNone) {
            cell.valueLabel.text = @"";
        } else if (self.containerDisplayMode == XXTEObjectContainerDisplayModeCount) {
            if ([pairValue respondsToSelector:@selector(count)]) {
                NSUInteger childCount = [pairValue count];
                cell.valueLabel.textColor = XXTColorForeground();
                cell.valueLabel.text = [NSString stringWithFormat:@"(%@)", [@(childCount) stringValue]];
            }
        } else if (self.containerDisplayMode == XXTEObjectContainerDisplayModeDescription) {
            cell.valueLabel.text = [[[pairValue description] componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] componentsJoinedByString:@""];
        }
    }
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
                    UIViewController *blockVC = blockInteractions(self, YES);
                    [PMKPromise new:^(PMKFulfiller fulfill, PMKRejecter reject) {
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                            [[UIPasteboard generalPasteboard] setString:detailText];
                            fulfill(nil);
                        });
                    }].finally(^() {
                        toastMessage(self, NSLocalizedString(@"Copied to the pasteboard.", nil));
                        blockInteractions(blockVC, NO);
                    });
                }
            }
            else
            {
                XXTEObjectViewController *objectViewController = [[XXTEObjectViewController alloc] initWithRootObject:pairValue];
                objectViewController.title = cell.titleLabel.text;
                objectViewController.entryBundle = self.entryBundle;
                objectViewController.tableViewStyle = self.tableViewStyle;
                objectViewController.containerDisplayMode = self.containerDisplayMode;
                [self.navigationController pushViewController:objectViewController animated:YES];
            }
        }
    }
}

@end
