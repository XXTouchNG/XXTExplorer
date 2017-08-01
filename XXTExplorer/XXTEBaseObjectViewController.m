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
    
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([XXTEMoreTitleValueCell class]) bundle:[NSBundle mainBundle]] forCellReuseIdentifier:XXTEMoreTitleValueCellReuseIdentifier];
    
    _singleValueCell = ({
        id Object = self.RootObject;
        XXTEMoreTitleValueCell *cell = [[XXTEMoreTitleValueCell alloc] init];
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
