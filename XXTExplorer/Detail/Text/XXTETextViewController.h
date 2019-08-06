//
//  XXTETextViewController.h
//  XXTExplorer
//
//  Created by Zheng on 10/01/2018.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import "XXTEViewer.h"

@interface XXTETextViewController : UIViewController <XXTEViewer>

@property (nonatomic, assign, getter=isLockedState) BOOL lockedState;
@property (nonatomic, assign) CFStringEncoding currentEncoding;

@end
