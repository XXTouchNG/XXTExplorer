//
//  RMModel.m
//  XXTExplorer
//
//  Created by Zheng on 12/01/2018.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import "RMModel.h"
#import "RMHandler.h"

static NSErrorDomain RMModelErrorDomain = @"RMModelErrorDomain";
#define RMError(format, ...) [NSError errorWithDomain:RMModelErrorDomain code:RMApiErrorCode userInfo:@{ NSLocalizedDescriptionKey: [NSString stringWithFormat:NSLocalizedString((format), nil), __VA_ARGS__] }]
#define RMFatalError(format, ...) [NSError errorWithDomain:RMModelErrorDomain code:RMApiFatalErrorCode userInfo:@{ NSLocalizedDescriptionKey: [NSString stringWithFormat:NSLocalizedString((format), nil), __VA_ARGS__] }]

@implementation RMModel

+ (PMKPromise *)promiseResponse:(NSDictionary *)resp {
    return [PMKPromise promiseWithResolver:^(PMKResolver resolve) {
        if (resp[@"code"] == nil) {
            resolve(RMFatalError(NSLocalizedString(@"Internal server error (%@).", nil), @(RMApiFatalErrorCode)));
            return;
        }
        if (NO == [resp[@"code"] isKindOfClass:[NSNumber class]])
        {
            resolve(RMError(NSLocalizedString(@"Unknown server response (%@).", nil), @(RMApiErrorCode)));
            return;
        }
        NSInteger retCode = [resp[@"code"] integerValue];
        if (retCode == 1) {
            
        }
        else {
            id retData = resp[@"data"];
            if ([retData isKindOfClass:[NSString class]]) {
                NSString *retMsg = retData;
                resolve(RMError(NSLocalizedString(@"Server message: %@.", nil), retMsg));
                return;
            } else {
                resolve(RMError(NSLocalizedString(@"Unknown server response (%@).", nil), @(retCode)));
                return;
            }
        }
        id retData = resp[@"data"];
        if ([retData isKindOfClass:[NSDictionary class]]) {
            resolve([self promiseModelWithDictionary:retData]);
        } else if ([retData isKindOfClass:[NSArray class]]) {
            resolve([self promiseModelsWithList:retData]);
        } else if ([retData isKindOfClass:[NSString class]]) {
            resolve(retData);
        } else if (!retData || [retData isKindOfClass:[NSNull class]]) {
            resolve(RMError(NSLocalizedString(@"Empty server response (%@).", nil), @(255)));
        } else {
            resolve(RMError(NSLocalizedString(@"Unknown server response type (%@).", nil), NSStringFromClass([retData class])));
        }
    }];
}

+ (PMKPromise *)promiseModelWithDictionary:(NSDictionary *)retData {
    return [PMKPromise promiseWithResolver:^(PMKResolver resolve) {
        NSError *parseErr = nil;
        RMModel *model = [[[self class] alloc] initWithDictionary:retData error:&parseErr];
        if (!model) {
            resolve(parseErr);
            return;
        }
        resolve(model);
    }];
}

+ (PMKPromise *)promiseModelsWithList:(NSArray <NSDictionary *> *)retData {
    return [PMKPromise promiseWithResolver:^(PMKResolver resolve) {
        NSMutableArray <RMModel *> *retArr = [[NSMutableArray alloc] init];
        for (NSDictionary *modelDict in retData) {
            NSError *parseErr = nil;
            RMModel *model = [[[self class] alloc] initWithDictionary:modelDict error:&parseErr];
            if (!model) {
                resolve(parseErr);
                return;
            }
            [retArr addObject:model];
        }
        resolve([retArr copy]);
    }];
}

+ (PMKPromise *)promiseGETRequest:(NSString *)url {
    return [NSURLConnection GET:url query:@{}]
    .then(^(NSDictionary *reqResult) {
        return [[self class] promiseResponse:reqResult];
    });
}

+ (PMKPromise *)promisePOSTRequest:(NSString *)url POSTFields:(NSDictionary *)fields {
    return [NSURLConnection POST:url JSON:fields]
    .then(^(NSDictionary *reqResult) {
        return [[self class] promiseResponse:reqResult];
    });
}

- (NSString *)description {
    return [NSString stringWithFormat:@"[%@]: %@", NSStringFromClass([self class]), [self toJSONString]];
}

@end
