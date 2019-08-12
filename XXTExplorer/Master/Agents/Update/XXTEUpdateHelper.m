//
// Created by Zheng on 09/08/2017.
// Copyright (c) 2017 Zheng. All rights reserved.
//

#import "XXTEUpdateHelper.h"
#import "XXTEUpdatePackage.h"
#import <PromiseKit/PromiseKit.h>
#import <PromiseKit/NSURLConnection+PromiseKit.h>

#import <zlib.h>
#import <sys/stat.h>

@interface XXTEUpdateHelper ()

@end

@implementation XXTEUpdateHelper {

}

- (instancetype)initWithRepositoryURL:(NSURL *)repositoryURL {
    if (self = [super init]) {
        _repositoryURL = repositoryURL;
        NSString *temporarilyLocation = [[XXTERootPath() stringByAppendingPathComponent:@"caches"] stringByAppendingPathComponent:@"_XXTEUpdateHelper"];
        struct stat temporarilyLocationStat;
        if (0 != lstat([temporarilyLocation UTF8String], &temporarilyLocationStat))
            if (0 != mkdir([temporarilyLocation UTF8String], 0755))
                NSLog(@"%@", [NSString stringWithFormat:@"Cannot create temporarily directory \"%@\".", temporarilyLocation]); // just log
        _temporarilyLocation = temporarilyLocation;
    }
    return self;
}

+ (PMKPromise *)syncPromiseWithValue:(id)apiResp {
    return [PMKPromise promiseWithResolver:^(PMKResolver resolve) {
        if ([apiResp isKindOfClass:[NSDictionary class]])
        {
            resolve(apiResp);
        }
        else if ([apiResp isKindOfClass:[NSString class]])
        {
            NSError *jsonError = nil;
            NSDictionary *apiRespDict = [NSJSONSerialization JSONObjectWithData:[apiResp dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&jsonError];
            if (apiRespDict) {
                resolve(apiRespDict);
            } else if (jsonError) {
                resolve(jsonError);
            } else {
                resolve(nil);
            }
        }
    }];
}

+ (PMKPromise *)syncPromiseWithDictionary:(NSDictionary *)apiResp {
    return [PMKPromise promiseWithResolver:^(PMKResolver resolve) {
        NSError *apiError = nil;
        XXTEUpdatePackage *model = [[XXTEUpdatePackage alloc] initWithDictionary:apiResp error:&apiError];
        if (model) {
            resolve(model);
            return;
        }
        if (apiError) {
            resolve(apiError);
            return;
        }
        resolve(nil);
    }];
}

- (void)sync {
    [NSURLConnection GET:[self.repositoryURL absoluteString] query:@{}]
    .then(^(id apiResp)
    {
        return [[self class] syncPromiseWithValue:apiResp];
    })
    .then(^(NSDictionary *apiResp)
    {
        return [[self class] syncPromiseWithDictionary:apiResp];
    })
    .then(^(XXTEUpdatePackage *package)
    {
        if (package)
        {
            self.respPackage = package;
        }
    })
    .catch(^(NSError *error)
    {
        XXTEUpdatePackage *pkg = self.respPackage;
        if (!pkg)
        {
            if (error)
            {
                if ([self->_delegate respondsToSelector:@selector(jsonHelper:didSyncFailWithError:)])
                {
                    [self->_delegate jsonHelper:self didSyncFailWithError:error];
                }
            }
        }
    })
    .finally(^
    {
        XXTEUpdatePackage *pkg = self.respPackage;
        if (pkg)
        {
            if ([self->_delegate respondsToSelector:@selector(jsonHelperDidSyncReady:)])
            {
                [self->_delegate jsonHelperDidSyncReady:self];
            }
        }
    });
}

@end
