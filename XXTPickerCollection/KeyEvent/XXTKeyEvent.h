//
//  XXTKeyEvent.h
//  XXTPickerCollection
//
//  Created by Zheng on 30/04/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XXTKeyEvent : NSObject <NSCopying, NSMutableCopying, NSCoding>
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *command;

+ (instancetype)eventWithTitle:(NSString *)title command:(NSString *)command;
@end
