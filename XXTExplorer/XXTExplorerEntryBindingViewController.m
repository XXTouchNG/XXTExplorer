//
//  XXTExplorerEntryBindingViewController.m
//  XXTExplorer
//
//  Created by Zheng on 15/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTExplorerEntryBindingViewController.h"
#import "XXTEAppDefines.h"
#import "XXTExplorerDefaults.h"

@interface XXTExplorerEntryBindingViewController ()

@property (nonatomic, copy, readonly) NSDictionary *bindingDictionary;

@end

@implementation XXTExplorerEntryBindingViewController {
    
}

- (instancetype)initWithExtension:(NSString *)extension {
    if (self = [super initWithStyle:UITableViewStyleGrouped]) {
        _extension = extension;
        _bindingDictionary = XXTEDefaultsObject(XXTExplorerViewEntryBindingKey);
    }
    return self;
}

@end
