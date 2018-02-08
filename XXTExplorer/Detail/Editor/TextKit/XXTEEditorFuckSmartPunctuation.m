//
//  XXTEEditorFuckSmartPunctuation.m
//  XXTExplorer
//
//  Created by Zheng Wu on 2018/2/8.
//  Copyright © 2018年 Zheng. All rights reserved.
//

#import "XXTEEditorFuckSmartPunctuation.h"
#import <objc/runtime.h>

@implementation XXTEEditorFuckSmartPunctuation

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [objc_getClass("UITextInputController") class];
        Class myClass = [self class];
        
        SEL originalSelector = @selector(checkSmartPunctuationForWordInRange:);
        SEL swizzledSelector = @selector(checkSmartPunctuationForWordInRange:);
        
        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        if (originalMethod != NULL) {
            Method swizzledMethod = class_getInstanceMethod(myClass, swizzledSelector);
            
            BOOL didAddMethod =
            class_addMethod(class,
                            originalSelector,
                            method_getImplementation(swizzledMethod),
                            method_getTypeEncoding(swizzledMethod));
            
            if (didAddMethod) {
                class_replaceMethod(class,
                                    swizzledSelector,
                                    method_getImplementation(originalMethod),
                                    method_getTypeEncoding(originalMethod));
            } else {
                method_exchangeImplementations(originalMethod, swizzledMethod);
            }
        }
    });
}

- (void)checkSmartPunctuationForWordInRange:(id)arg1 {
    
}

@end
