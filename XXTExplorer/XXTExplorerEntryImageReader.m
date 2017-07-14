//
//  XXTExplorerEntryImageReader.m
//  XXTExplorer
//
//  Created by Zheng on 14/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTExplorerEntryImageReader.h"
#import "XXTEImageViewerController.h"
#import <CoreGraphics/CoreGraphics.h>
#import <ImageIO/ImageIO.h>

@implementation XXTExplorerEntryImageReader

@synthesize metaDictionary = _metaDictionary;
@synthesize entryPath = _entryPath;
@synthesize entryName = _entryName;
@synthesize entryDisplayName = _entryDisplayName;
@synthesize entryIconImage = _entryIconImage;
@synthesize displayMetaKeys = _displayMetaKeys;
@synthesize entryDescription = _entryDescription;
@synthesize entryExtensionDescription = _entryExtensionDescription;
@synthesize entryViewerDescription = _entryViewerDescription;

+ (NSArray <NSString *> *)supportedExtensions {
    return [XXTEImageViewerController suggestedExtensions];
}

- (instancetype)initWithPath:(NSString *)filePath {
    if (self = [super init]) {
        _entryPath = filePath;
        [self setupWithPath:filePath];
    }
    return self;
}

- (void)setupWithPath:(NSString *)path {
    _displayMetaKeys = @[ ];
    NSString *entryUpperedExtension = [[path pathExtension] uppercaseString];
    _entryExtensionDescription = [NSString stringWithFormat:@"%@ Image", entryUpperedExtension];
    _entryViewerDescription = [XXTEImageViewerController viewerName];
    
    CFStringRef imageKeys[2];
    CFTypeRef imageValues[2];
    imageKeys[0] = kCGImageSourceShouldCache;
    imageValues[0] = (CFTypeRef)kCFBooleanTrue;
    imageKeys[1] = kCGImageSourceShouldAllowFloat;
    imageValues[1] = (CFTypeRef)kCFBooleanTrue;
    CFDictionaryRef imageOptions = CFDictionaryCreate(NULL, (const void **) imageKeys,
                                                      (const void **) imageValues, 2,
                                                      &kCFTypeDictionaryKeyCallBacks,
                                                      &kCFTypeDictionaryValueCallBacks);
    
    CGImageSourceRef source = CGImageSourceCreateWithURL((__bridge CFURLRef)[NSURL fileURLWithPath:path], imageOptions);
    if (source) {
        CFDictionaryRef dictRef = CGImageSourceCopyPropertiesAtIndex(source, 0, imageOptions);
        NSDictionary* metadata = CFBridgingRelease(dictRef);
        
        _displayMetaKeys = @[ @"ColorModel", @"PixelWidth", @"PixelHeight", @"DPIHeight", @"DPIWidth", @"Depth", @"Orientation", @"ProfileName" ];
        _metaDictionary = metadata;
    }
    
}

@end
