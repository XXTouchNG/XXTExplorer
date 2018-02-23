//
//  UITextField+DisableFuckingSmartXXX.m
//  XXTExplorer
//
//  Created by Zheng Wu on 2017/12/28.
//  Copyright © 2017年 Zheng. All rights reserved.
//

#import "UITextField+DisableFuckingSmartXXX.h"

@implementation UITextField (DisableFuckingSmartXXX)

XXTE_START_IGNORE_PARTIAL
- (UITextSmartDashesType)smartDashesType {
    return UITextSmartDashesTypeNo;
}
XXTE_END_IGNORE_PARTIAL
XXTE_START_IGNORE_PARTIAL
- (UITextSmartQuotesType)smartQuotesType {
    return UITextSmartQuotesTypeNo;
}
XXTE_END_IGNORE_PARTIAL
XXTE_START_IGNORE_PARTIAL
- (UITextSmartInsertDeleteType)smartInsertDeleteType {
    return UITextSmartInsertDeleteTypeNo;
}
XXTE_END_IGNORE_PARTIAL

@end
