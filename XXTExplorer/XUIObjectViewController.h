//
//  XUIObjectViewController.h
//  XXTExplorer
//
//  Created by Zheng on 17/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 *
 * XUIObjectViewController
 *
 * Render and _display_ an instance of NSString, NSNumber, NSDate, NSArray or NSDictionary,
 * all properties are read-only, nothing will happen if you tap any "Value Cell",
 * if you tap a cell whose value is an instance of NSArray/NSDictionary,
 * it will push another XUIObjectViewController and set its RootObject to the value of that cell.
 *
 **/
@interface XUIObjectViewController : UITableViewController

@property (nonatomic, copy, readonly) id RootObject;

/**
 * Create a new instance with the root object.
 * @param RootObject an instance of NSString, NSNumber, NSDate, NSArray or NSDictionary
 * @return the new instance of XUIObjectViewController
 */
- (instancetype)initWithRootObject:(id)RootObject;

@end
