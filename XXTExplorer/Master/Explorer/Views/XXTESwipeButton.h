/*
 * XXTESwipeTableCell is licensed under MIT license. See LICENSE.md file for more information.
 * Copyright (c) 2016 Imanol Fernandez @MortimerGoro
 */

#import <UIKit/UIKit.h>


@class XXTESwipeTableCell;

/** 
 * This is a convenience class to create XXTESwipeTableCell buttons
 * Using this class is optional because XXTESwipeTableCell is button agnostic and can use any UIView for that purpose
 * Anyway, it's recommended that you use this class because is totally tested and easy to use ;)
 */
@interface XXTESwipeButton : UIButton

/**
 * Convenience block callback for developers lazy to implement the XXTESwipeTableCellDelegate.
 * @return Return YES to autohide the swipe view
 */
typedef BOOL(^ XXTESwipeButtonCallback)(XXTESwipeTableCell * _Nonnull cell);
@property (nonatomic, strong, nullable) XXTESwipeButtonCallback callback;

/** A width for the expanded buttons. Defaults to 0, which means sizeToFit will be called. */
@property (nonatomic, assign) CGFloat buttonWidth;

/** 
 * Convenience static constructors
 */
+(nonnull instancetype) buttonWithTitle:(nonnull NSString *) title backgroundColor:(nullable UIColor *) color;
+(nonnull instancetype) buttonWithTitle:(nonnull NSString *) title backgroundColor:(nullable UIColor *) color padding:(NSInteger) padding;
+(nonnull instancetype) buttonWithTitle:(nonnull NSString *) title backgroundColor:(nullable UIColor *) color insets:(UIEdgeInsets) insets;
+(nonnull instancetype) buttonWithTitle:(nonnull NSString *) title backgroundColor:(nullable UIColor *) color callback:(nullable XXTESwipeButtonCallback) callback;
+(nonnull instancetype) buttonWithTitle:(nonnull NSString *) title backgroundColor:(nullable UIColor *) color padding:(NSInteger) padding callback:(nullable XXTESwipeButtonCallback) callback;
+(nonnull instancetype) buttonWithTitle:(nonnull NSString *) title backgroundColor:(nullable UIColor *) color insets:(UIEdgeInsets) insets callback:(nullable XXTESwipeButtonCallback) callback;
+(nonnull instancetype) buttonWithTitle:(nonnull NSString *) title icon:(nullable UIImage*) icon backgroundColor:(nullable UIColor *) color;
+(nonnull instancetype) buttonWithTitle:(nonnull NSString *) title icon:(nullable UIImage*) icon backgroundColor:(nullable UIColor *) color padding:(NSInteger) padding;
+(nonnull instancetype) buttonWithTitle:(nonnull NSString *) title icon:(nullable UIImage*) icon backgroundColor:(nullable UIColor *) color insets:(UIEdgeInsets) insets;
+(nonnull instancetype) buttonWithTitle:(nonnull NSString *) title icon:(nullable UIImage*) icon backgroundColor:(nullable UIColor *) color callback:(nullable XXTESwipeButtonCallback) callback;
+(nonnull instancetype) buttonWithTitle:(nonnull NSString *) title icon:(nullable UIImage*) icon backgroundColor:(nullable UIColor *) color padding:(NSInteger) padding callback:(nullable XXTESwipeButtonCallback) callback;
+(nonnull instancetype) buttonWithTitle:(nonnull NSString *) title icon:(nullable UIImage*) icon backgroundColor:(nullable UIColor *) color insets:(UIEdgeInsets) insets callback:(nullable XXTESwipeButtonCallback) callback;

-(void) setPadding:(CGFloat) padding;
-(void) setEdgeInsets:(UIEdgeInsets)insets;
-(void) centerIconOverText;
-(void) centerIconOverTextWithSpacing: (CGFloat) spacing;
-(void) iconTintColor:(nullable UIColor *)tintColor;


@end
