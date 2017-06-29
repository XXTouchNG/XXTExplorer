//
//  XXTEMoreRemoteAddressCell.h
//  XXTExplorer
//
//  Created by Zheng on 28/06/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

static NSString * const XXTEMoreRemoteAddressCellReuseIdentifier = @"XXTEMoreRemoteAddressCellReuseIdentifier";

@interface XXTEMoreRemoteAddressCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UILabel *addressLabel;

@end
