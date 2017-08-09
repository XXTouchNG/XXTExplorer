//
// Created by Zheng on 09/08/2017.
// Copyright (c) 2017 Zheng. All rights reserved.
//

#import "XXTEAPTHelper.h"
#import "XXTEAPTPackage.h"
#import <PromiseKit/PromiseKit.h>
#import <PromiseKit/NSURLConnection+PromiseKit.h>

#import <zlib.h>
#import <sys/stat.h>
#import "XXTEAppDefines.h"

@interface XXTEAPTHelper ()

@property (nonatomic, strong, readonly) NSString *temporarilyLocation;

@end

@implementation XXTEAPTHelper {

}

- (instancetype)initWithRepositoryURL:(NSURL *)repositoryURL {
    if (self = [super init]) {
        _repositoryURL = repositoryURL;
        NSString *temporarilyLocation = [[[sharedDelegate() sharedRootPath] stringByAppendingPathComponent:@"caches"] stringByAppendingPathComponent:@"_XXTEAPTHelper"];
        struct stat temporarilyLocationStat;
        if (0 != lstat([temporarilyLocation UTF8String], &temporarilyLocationStat))
            if (0 != mkdir([temporarilyLocation UTF8String], 0755))
                NSLog(@"%@", [NSString stringWithFormat:@"Cannot create temporarily directory \"%@\".", temporarilyLocation]); // just log
        _temporarilyLocation = temporarilyLocation;
    }
    return self;
}

- (void)sync {
    [NSURLConnection GET:[self.repositoryURL absoluteString] query:@{}]
    .then(^(id packageData) {
        if (packageData) {
            if ([packageData isKindOfClass:[NSString class]])
            {
                NSString *packageString = packageData;
                if (packageString) {
                    return packageString;
                }
            }
            else if ([packageData isKindOfClass:[NSData class]])
            {
                if ([packageData length] == 0) @throw NSLocalizedString(@"Empty response.", nil);
                
                unsigned full_length = (unsigned)[packageData length];
                unsigned half_length = full_length / 2;
                
                NSMutableData *decompressed = [NSMutableData dataWithLength: full_length + half_length];
                BOOL done = NO;
                int status;
                
                z_stream strm;
                strm.next_in = (Bytef *)[packageData bytes];
                strm.avail_in = full_length;
                strm.total_out = 0;
                strm.zalloc = Z_NULL;
                strm.zfree = Z_NULL;
                
                if (inflateInit2(&strm, (15 + 32)) != Z_OK) @throw NSLocalizedString(@"Cannot deflate raw data.", nil);
                while (!done)
                {
                    // Make sure we have enough room and reset the lengths.
                    if (strm.total_out >= [decompressed length])
                        [decompressed increaseLengthBy: half_length];
                    strm.next_out = [decompressed mutableBytes] + strm.total_out;
                    strm.avail_out = (uInt)([decompressed length] - strm.total_out);
                    
                    // Inflate another chunk.
                    status = inflate (&strm, Z_SYNC_FLUSH);
                    if (status == Z_STREAM_END) done = YES;
                    else if (status != Z_OK) break;
                }
                if (inflateEnd (&strm) != Z_OK) @throw NSLocalizedString(@"Cannot deflate data.", nil);
                
                // Set real length.
                if (done)
                {
                    [decompressed setLength: strm.total_out];
                    NSData *packageData = [NSData dataWithData:decompressed];
                    NSString *packageString = [[NSString alloc] initWithData:packageData encoding:NSUTF8StringEncoding];
                    if (packageString) {
                        return packageString;
                    }
                }
                else {
                    @throw NSLocalizedString(@"Deflating terminated unexpectedly.", nil);
                }
            }
        }
        @throw NSLocalizedString(@"Invalid package data.", nil);
        return @"";
    })
    .then(^(NSString *packageString) {
        NSError *logError = nil;
        NSString *randomUUIDString = [[NSUUID UUID] UUIDString];
        NSString *temporarilyName = [NSString stringWithFormat:@".tmp_%@_%@", @"Package", randomUUIDString];
        NSString *saveLocation = [self.temporarilyLocation stringByAppendingPathComponent:temporarilyName];
        [packageString writeToFile:saveLocation atomically:YES encoding:NSUTF8StringEncoding error:&logError];
        if (logError) {
//            @throw [logError localizedDescription];
        }
        NSMutableArray <NSDictionary *> *packageContentArray = [[NSMutableArray alloc] init];
        NSArray <NSString *> *packageArray = [packageString componentsSeparatedByString:@"\n\n"];
        for (NSString *packageContent in packageArray) {
            NSMutableDictionary <NSString *, NSString *> *packageMutableDictionary = [[NSMutableDictionary alloc] init];
            NSArray <NSString *> *packageLines = [packageContent componentsSeparatedByString:@"\n"];
            for (NSString *packageLine in packageLines) {
                NSArray <NSString *> *lineComponents = [packageLine componentsSeparatedByString:@":"];
                if (lineComponents.count != 2) continue;
                NSString *lineKey = [lineComponents[0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                NSString *lineValue = [lineComponents[1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                [packageMutableDictionary setObject:lineValue forKey:lineKey];
            }
            [packageContentArray addObject:[[NSDictionary alloc] initWithDictionary:packageMutableDictionary]];
        }
        return [[NSArray alloc] initWithArray:packageContentArray];
    })
    .then(^(NSArray <NSDictionary *> *packageContentArray) {
        NSMutableDictionary <NSString *, XXTEAPTPackage *> *packages = [[NSMutableDictionary alloc] initWithCapacity:packageContentArray.count];
        for (NSDictionary *packageContent in packageContentArray) {
            XXTEAPTPackage *package = [XXTEAPTPackage packageWithDictionary:packageContent];
            if (package) {
                NSString *pkgIdentifier = package.apt_Package;
                XXTEAPTPackage *pkg1 = packages[pkgIdentifier];
                if (!pkg1) {
                    [packages setObject:package forKey:pkgIdentifier];
                }
            }
        }
        return [[NSDictionary alloc] initWithDictionary:packages];
    })
    .then(^(NSDictionary <NSString *, XXTEAPTPackage *> *packages) {
        _packageMap = packages;
        if (_delegate && [_delegate respondsToSelector:@selector(aptHelperDidSyncReady:)]) {
            [_delegate aptHelperDidSyncReady:self];
        }
    })
    .catch(^(NSError *error) {
        if (error) {
            if (_delegate && [_delegate respondsToSelector:@selector(aptHelper:didSyncFailWithError:)]) {
                [_delegate aptHelper:self didSyncFailWithError:error];
            }
        }
    });
}

@end
