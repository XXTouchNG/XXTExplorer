//
//  XXTEObjectViewController.h
//  XXTExplorer
//
//  Created by Zheng on 17/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEViewer.h"

typedef enum : NSUInteger {
    XXTEObjectContainerDisplayModeNone = 0,
    XXTEObjectContainerDisplayModeCount,
    XXTEObjectContainerDisplayModeDescription,
} XXTEObjectContainerDisplayMode;

/**
 *
 * XXTEObjectViewController
 *
 * Render and _display_ an instance of NSString, NSNumber, NSDate, NSArray or NSDictionary,
 * all properties are read-only, nothing will happen if you tap any "Value Cell",
 * if you tap a cell whose value is an instance of NSArray/NSDictionary,
 * it will push another XXTEObjectViewController and set its RootObject to the value of that cell.
 *
 **/
@interface XXTEObjectViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, XXTEViewer>

+ (NSArray <Class> *)supportedTypes;

@property (nonatomic, strong) NSBundle *entryBundle;
@property (nonatomic, copy, readonly) id RootObject;
@property (nonatomic, strong, readonly) UITableView *tableView;
@property (nonatomic, assign) UITableViewStyle tableViewStyle;

@property (nonatomic, assign) XXTEObjectContainerDisplayMode containerDisplayMode;

/**
 * Create a new instance with the root object.
 * @param RootObject an instance of NSString, NSNumber, NSDate, NSArray or NSDictionary
 * @return the new instance of XXTEObjectViewController
 */
- (instancetype)initWithRootObject:(id)RootObject;

@end
