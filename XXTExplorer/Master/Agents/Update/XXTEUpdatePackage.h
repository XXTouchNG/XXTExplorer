//
// Created by Zheng on 09/08/2017.
// Copyright (c) 2017 Zheng. All rights reserved.
//

#import <JSONModel/JSONModel.h>

@interface XXTEUpdatePackage : JSONModel

// required cydia
@property (nonatomic, copy) NSString *latestVersion;
@property (nonatomic, copy) NSString *updateDescription;
@property (nonatomic, copy) NSString *cydiaURLString;

// template cydia
@property (nonatomic, copy) NSString *templateURLString;
@property (nonatomic, copy) NSString *templatePath; // unmanaged
@property (nonatomic, copy) NSString *aptURLString;
@property (nonatomic, copy) NSString *packageID;

// online updating
@property (nonatomic, copy) NSString *downloadURLString;
@property (nonatomic, copy) NSString *downloadPath;
@property (nonatomic, copy) NSString *downloadMD5;
@property (nonatomic, copy) NSString *downloadSHA1;
@property (nonatomic, copy) NSString *downloadSHA256;
@property (nonatomic, copy) NSString *downloadSHA512;

@end
