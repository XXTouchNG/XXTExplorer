//
//  UITextView+DisableFuckingSmartXXX.m
//  XXTExplorer
//
//  Created by Zheng on 14/12/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "UITextView+DisableFuckingSmartXXX.h"

@implementation UITextView (DisableFuckingSmartXXX)

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

/*
- (UITextAutocorrectionType)autocorrectionType {
    return UITextAutocorrectionTypeNo;
}

- (UITextAutocapitalizationType)autocapitalizationType {
    return UITextAutocapitalizationTypeNone;
}
 */

@end
