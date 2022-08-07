//
// Created by Zheng on 09/08/2017.
// Copyright (c) 2017 Zheng. All rights reserved.
//

#import <JSONModel/JSONModel.h>

@interface XXTEUpdatePackage : JSONModel

// required cydia
@property (nonnull, nonatomic, copy) NSString *latestVersion;
@property (nonnull, nonatomic, copy) NSString *updateDescription;
@property (nullable, nonatomic, copy) NSString *cydiaURLString;

// template cydia
@property (nullable, nonatomic, copy) NSString *templateURLString;
@property (nullable, nonatomic, copy) NSString *aptURLString;
@property (nullable, nonatomic, copy) NSString *packageID;

// online updating
@property (nullable, nonatomic, copy) NSString *downloadURLString;
@property (nullable, nonatomic, copy) NSString *downloadPath;
@property (nullable, nonatomic, copy) NSString *downloadSHA256;

@end
