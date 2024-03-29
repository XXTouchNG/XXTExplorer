//
//  XXTEMoreAddressCell.h
//  XXTExplorer
//
//  Created by Zheng on 28/06/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XXTEAutoLabel.h"

static NSString * const XXTEMoreAddressCellReuseIdentifier = @"XXTEMoreAddressCellReuseIdentifier";

@interface XXTEMoreAddressCell : UITableViewCell
@property (weak, nonatomic) IBOutlet XXTEAutoLabel *addressLabel;

@end
