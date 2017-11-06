//
//  XXTESymbolViewController.h
//  XXTExplorer
//
//  Created by Zheng on 05/11/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

@class XXTEEditorController, XXTEEditorLanguage;

@interface XXTESymbolViewController : UITableViewController

@property (nonatomic, weak) XXTEEditorController *editor;
+ (BOOL)hasSymbolPatternsForLanguage:(XXTEEditorLanguage *)language;

@end
