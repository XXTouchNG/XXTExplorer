//
//  XXTEMoreUserDefaultsOperationController.h
//  XXTExplorer
//
//  Created by Zheng on 08/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

@class XXTEMoreUserDefaultsOperationController;

@protocol XXTEMoreUserDefaultsOperationControllerDelegate <NSObject>

@optional
- (void)userDefaultsOperationController:(XXTEMoreUserDefaultsOperationController *)controller operationSelectedWithIndex:(NSUInteger)index;

@end

@interface XXTEMoreUserDefaultsOperationController : UITableViewController
@property (nonatomic, weak) id <XXTEMoreUserDefaultsOperationControllerDelegate> delegate;
@property (nonatomic, copy) NSDictionary *userDefaultsEntry;
@property (nonatomic, assign) NSUInteger selectedOperation;

@end
