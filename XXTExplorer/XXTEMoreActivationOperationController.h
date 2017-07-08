//
//  XXTEMoreActivationOperationController.h
//  XXTExplorer
//
//  Created by Zheng Wu on 06/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

@class XXTEMoreActivationOperationController;

@protocol XXTEMoreActivationOperationControllerDelegate <NSObject>

@optional
- (void)activationOperationController:(XXTEMoreActivationOperationController *)controller operationSelectedWithIndex:(NSUInteger)index;

@end

@interface XXTEMoreActivationOperationController : UITableViewController
@property (nonatomic, weak) id <XXTEMoreActivationOperationControllerDelegate> delegate;
@property (nonatomic, assign) NSUInteger actionIndex;
@property (nonatomic, assign) NSUInteger selectedOperation;

@end
