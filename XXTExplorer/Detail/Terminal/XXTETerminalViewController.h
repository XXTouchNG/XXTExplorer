//
//  XXTETerminalViewController.h
//  XXTouchApp
//
//  Created by Zheng on 10/11/2016.
//  Copyright © 2016 Zheng. All rights reserved.
//

#import "XXTEViewer.h"

@class XXTEEditorController;

@interface XXTETerminalViewController : UIViewController <XXTEViewer>

@property (nonatomic, assign) BOOL runImmediately;
@property (nonatomic, weak) XXTEEditorController *editor;

@end
