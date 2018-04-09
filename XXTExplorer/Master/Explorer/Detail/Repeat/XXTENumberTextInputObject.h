//
//  XXTENumberTextInputObject.h
//  XXTExplorer
//
//  Created by Zheng on 09/04/2018.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface XXTENumberTextInputObject : NSObject

+ (NSRegularExpression *)numberRegex;
@property (nonatomic, strong) UITextField *textInput;
@property (nonatomic, assign) NSUInteger maxLength;
- (void)shake;

@end
