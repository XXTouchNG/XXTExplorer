//
//  XXTEEditorTextInput.h
//  XXTExplorer
//
//  Created by Zheng on 07/09/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

@class XXTEEditorLanguage;

@interface XXTEEditorTextInput : NSObject <UITextViewDelegate>

@property (nonatomic, strong) XXTEEditorLanguage *language;

@property (nonatomic, assign) BOOL autoIndent;
@property (nonatomic, strong) NSString *tabWidthString;
@property (nonatomic, weak) id <UIScrollViewDelegate> scrollViewDelegate;

@end
