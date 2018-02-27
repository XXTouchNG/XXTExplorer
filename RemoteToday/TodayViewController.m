//
//  TodayViewController.m
//  RemoteToday
//
//  Created by Zheng Wu on 2018/2/27.
//  Copyright © 2018年 Zheng. All rights reserved.
//

#import "TodayViewController.h"
#import <NotificationCenter/NotificationCenter.h>

#import "TodayRemoteCell.h"

@interface TodayViewController () <NCWidgetProviding>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) TodayRemoteCell *remoteCell;

@end

@implementation TodayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _remoteCell = [[[UINib nibWithNibName:NSStringFromClass([TodayRemoteCell class]) bundle:nil] instantiateWithOwner:self options:nil] firstObject];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult))completionHandler {
    // Perform any setup necessary in order to update the view.
    
    // If an error is encountered, use NCUpdateResultFailed
    // If there's no update required, use NCUpdateResultNoData
    // If there's an update, use NCUpdateResultNewData

    completionHandler(NCUpdateResultNewData);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableView && indexPath.section == 0 && indexPath.row == 0) {
        return self.remoteCell;
    }
    return [UITableViewCell new];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableView && indexPath.section == 0) {
        if (indexPath.row == 0) {
            return 100.0;
        }
    }
    return 0.0;
}

@end
