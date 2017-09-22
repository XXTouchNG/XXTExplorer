//
// Created by Zheng on 09/08/2017.
// Copyright (c) 2017 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XXTEAPTPackage : NSObject

@property (nonatomic, strong) NSString *apt_Package; // identify
@property (nonatomic, strong) NSString *apt_Version; // check version
@property (nonatomic, strong) NSString *apt_Architecture; // should be iphoneos-arm
@property (nonatomic, strong) NSString *apt_Filename; // download
@property (nonatomic, strong) NSNumber *apt_Size; // verification
@property (nonatomic, strong) NSNumber *apt_MD5sum; // verification
@property (nonatomic, strong) NSString *apt_Name; // for display

+ (XXTEAPTPackage *)packageWithDictionary:(NSDictionary *)dictionary;

@end