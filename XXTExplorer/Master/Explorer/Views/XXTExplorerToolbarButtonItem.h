//
//  XXTExplorerToolbarButtonItem.h
//  XXTExplorer
//
//  Created by MMM on 2019/9/28.
//  Copyright © 2019 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NSString XXTExplorerToolbarButtonItemStatus;
static XXTExplorerToolbarButtonItemStatus * const XXTExplorerToolbarButtonItemStatusNormal = @"Normal";
static XXTExplorerToolbarButtonItemStatus * const XXTExplorerToolbarButtonItemStatusSelected = @"Selected";


@protocol XXTExplorerToolbarButtonItemDelegate <NSObject>
- (void)toolbarButtonTapped:(UIButton *)button;

@end

@interface XXTExplorerToolbarButtonItem : UIBarButtonItem

@property (nonatomic, strong, readonly) NSString *name;
@property (nonatomic, weak, readonly) id <XXTExplorerToolbarButtonItemDelegate> actionReceiver;

@property (nonatomic, strong, readonly) XXTExplorerToolbarButtonItemStatus *status;
- (void)setStatus:(XXTExplorerToolbarButtonItemStatus *)status forTraitCollection:(nullable UITraitCollection *)traitCollection;

- (instancetype)initWithName:(NSString *)name andActionReceiver:(id <XXTExplorerToolbarButtonItemDelegate>)actionReceiver;
- (void)updateButtonStatus;
- (void)updateButtonStatusForTraitCollection:(nullable UITraitCollection *)traitCollection;

@end

NS_ASSUME_NONNULL_END
