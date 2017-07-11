//
//  XXTEScanViewController.h
//  XXTExplorer
//
//  Created by Zheng on 09/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

@class XXTEScanViewController;

@protocol XXTEScanViewControllerDelegate <NSObject>

@optional
- (void)scanViewController:(XXTEScanViewController *)controller openURL:(NSURL *)url;
@optional
- (void)scanViewController:(XXTEScanViewController *)controller copyString:(NSString *)string;
@optional
- (void)scanViewController:(XXTEScanViewController *)controller activateLicense:(NSString *)licenseCode;

@end

@interface XXTEScanViewController : UIViewController

@property (nonatomic, weak) id <XXTEScanViewControllerDelegate> delegate;

@end
