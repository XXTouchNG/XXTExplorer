//
//  XUIMultipleOptionViewController.h
//  XXTExplorer
//
//  Created by Zheng on 31/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XUIViewController.h"
#import "XUILinkMultipleListCell.h"

@class XUIMultipleOptionViewController;

@protocol XUIMultipleOptionViewControllerDelegate <NSObject>

- (void)multipleOptionViewController:(XUIMultipleOptionViewController *)controller didSelectOption:(NSArray <NSNumber *> *)optionIndexes;

@end

@interface XUIMultipleOptionViewController : XUIViewController

@property (nonatomic, weak) id <XUIMultipleOptionViewControllerDelegate> delegate;
@property (nonatomic, strong, readonly) XUILinkMultipleListCell *cell;
- (instancetype)initWithCell:(XUILinkMultipleListCell *)cell;

@end
