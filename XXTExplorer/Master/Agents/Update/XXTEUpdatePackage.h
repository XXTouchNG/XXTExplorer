//
// Created by Zheng on 09/08/2017.
// Copyright (c) 2017 Zheng. All rights reserved.
//

#import <JSONModel/JSONModel.h>

@interface XXTEUpdatePackage : JSONModel

@property (nonatomic, strong) NSString *latestVersion;
@property (nonatomic, strong) NSString *updateDescription;
@property (nonatomic, strong) NSString *downloadURLString;
@property (nonatomic, strong) NSString *downloadPath;
@property (nonatomic, strong) NSString *cydiaURL;

@end
