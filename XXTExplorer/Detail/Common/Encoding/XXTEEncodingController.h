//
//  XXTEEncodingController.h
//  XXTExplorer
//
//  Created by Darwin on 8/2/19.
//  Copyright © 2019 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class XXTEEncodingController;

@protocol XXTEEncodingControllerDelegate <NSObject>

@optional
- (void)encodingControllerDidConfirm:(XXTEEncodingController *)controller;
- (void)encodingControllerDidChange:(XXTEEncodingController *)controller;
- (void)encodingControllerDidCancel:(XXTEEncodingController *)controller;

@end

@interface XXTEEncodingController : UITableViewController

@property (nonatomic, weak) id <XXTEEncodingControllerDelegate> delegate;
@property (nonatomic, assign) BOOL reopenMode;
@property (nonatomic, assign) CFStringEncoding selectedEncoding;

@end

NS_ASSUME_NONNULL_END
