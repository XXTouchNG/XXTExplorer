//
//  NSFileManager+DeepSize.m
//  XXTouchApp
//
//  Created by Zheng on 14/11/2016.
//  Copyright © 2016 Zheng. All rights reserved.
//

#import "NSFileManager+DeepSize.h"
#import <sys/stat.h>

@implementation NSFileManager (DeepSize)

- (NSArray *)listItemsInDirectoryAtPath:(NSString *)path deep:(BOOL)deep cancelFlag:(int *)cancelFlag
{
    NSString *absolutePath = path;
    NSArray *relativeSubpaths = (deep ? [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:absolutePath error:nil] : [[NSFileManager defaultManager] contentsOfDirectoryAtPath:absolutePath error:nil]);
    
    NSMutableArray *absoluteSubpaths = [[NSMutableArray alloc] init];
    
    for (NSString *relativeSubpath in relativeSubpaths)
    {
        NSString *absoluteSubpath = [absolutePath stringByAppendingPathComponent:relativeSubpath];
        [absoluteSubpaths addObject:absoluteSubpath];
        if (cancelFlag && *cancelFlag != 0) {
            break;
        }
    }
    
    return [NSArray arrayWithArray:absoluteSubpaths];
}

- (NSNumber *)sizeOfDirectoryAtPath:(NSString *)path error:(NSError **)error cancelFlag:(int *)cancelFlag
{
//    BOOL isDirectory = NO;
//    BOOL fileExists = [self fileExistsAtPath:path isDirectory:&isDirectory];
    struct stat fileStat;
    if (0 == lstat([path UTF8String], &fileStat) && S_ISDIR(fileStat.st_mode))
    {
        if ((error == nil) || ((*error) == nil))
        {
            NSNumber *size = [self sizeOfItemAtPath:path error:error];
            double sizeValue = [size doubleValue];
            
            if ((error == nil) || ((*error) == nil))
            {
                NSArray *subpaths = [self listItemsInDirectoryAtPath:path deep:YES cancelFlag:cancelFlag];
                NSUInteger subpathsCount = [subpaths count];
                
                for (NSUInteger i = 0; i < subpathsCount; i++)
                {
                    NSString *subpath = [subpaths objectAtIndex:i];
                    NSNumber *subpathSize = [self sizeOfItemAtPath:subpath error:error];
                    
                    if ((error == nil) || ((*error) == nil))
                    {
                        sizeValue += [subpathSize doubleValue];
                    }
                    else {
                        return nil;
                    }
                    
                    if (cancelFlag && *cancelFlag != 0) {
                        break;
                    }
                }
                
                return [NSNumber numberWithDouble:sizeValue];
            }
        }
    }
    return nil;
}

- (NSNumber *)sizeOfItemAtPath:(NSString *)path error:(NSError **)error
{
    return (NSNumber *)[[self attributesOfItemAtPath:path error:error] objectForKey:NSFileSize];
}

@end
