//
//  XXTEShield.m
//  XXTExplorer
//
//  Created by Zheng Wu on 13/12/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEShield.h"
#import <Bugly/Bugly.h>

@implementation XXTEShield

- (void)recordWithReason:(NSError *)reason
{
    [Bugly reportError:reason];
}

@end
