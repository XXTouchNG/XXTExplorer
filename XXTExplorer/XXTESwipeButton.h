/*
 * XXTESwipeTableCell is licensed under MIT license. See LICENSE.md file for more information.
 * Copyright (c) 2014 Imanol Fernandez @MortimerGoro
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
typedef BOOL(^XXTESwipeButtonCallback)(XXTESwipeTableCell * sender);
@property (nonatomic, strong) XXTESwipeButtonCallback callback;

/** A width for the expanded buttons. Defaults to 0, which means sizeToFit will be called. */
@property (nonatomic, assign) CGFloat buttonWidth;

/** 
 * Convenience static constructors
 */
+(instancetype) buttonWithTitle:(NSString *) title backgroundColor:(UIColor *) color;
+(instancetype) buttonWithTitle:(NSString *) title backgroundColor:(UIColor *) color padding:(NSInteger) padding;
+(instancetype) buttonWithTitle:(NSString *) title backgroundColor:(UIColor *) color insets:(UIEdgeInsets) insets;
+(instancetype) buttonWithTitle:(NSString *) title backgroundColor:(UIColor *) color callback:(XXTESwipeButtonCallback) callback;
+(instancetype) buttonWithTitle:(NSString *) title backgroundColor:(UIColor *) color padding:(NSInteger) padding callback:(XXTESwipeButtonCallback) callback;
+(instancetype) buttonWithTitle:(NSString *) title backgroundColor:(UIColor *) color insets:(UIEdgeInsets) insets callback:(XXTESwipeButtonCallback) callback;
+(instancetype) buttonWithTitle:(NSString *) title icon:(UIImage*) icon backgroundColor:(UIColor *) color;
+(instancetype) buttonWithTitle:(NSString *) title icon:(UIImage*) icon backgroundColor:(UIColor *) color padding:(NSInteger) padding;
+(instancetype) buttonWithTitle:(NSString *) title icon:(UIImage*) icon backgroundColor:(UIColor *) color insets:(UIEdgeInsets) insets;
+(instancetype) buttonWithTitle:(NSString *) title icon:(UIImage*) icon backgroundColor:(UIColor *) color callback:(XXTESwipeButtonCallback) callback;
+(instancetype) buttonWithTitle:(NSString *) title icon:(UIImage*) icon backgroundColor:(UIColor *) color padding:(NSInteger) padding callback:(XXTESwipeButtonCallback) callback;
+(instancetype) buttonWithTitle:(NSString *) title icon:(UIImage*) icon backgroundColor:(UIColor *) color insets:(UIEdgeInsets) insets callback:(XXTESwipeButtonCallback) callback;

-(void) setPadding:(CGFloat) padding;
-(void) setEdgeInsets:(UIEdgeInsets)insets;
-(void) centerIconOverText;
-(void) centerIconOverTextWithSpacing: (CGFloat) spacing;

@end
