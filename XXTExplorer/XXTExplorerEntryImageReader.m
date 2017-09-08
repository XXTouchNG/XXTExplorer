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
@synthesize metaKeys = _metaKeys;
@synthesize entryDescription = _entryDescription;
@synthesize entryExtensionDescription = _entryExtensionDescription;
@synthesize entryViewerDescription = _entryViewerDescription;
@synthesize executable = _executable;
@synthesize editable = _editable;

+ (NSArray <NSString *> *)supportedExtensions {
    return [XXTEImageViewerController suggestedExtensions];
}

+ (UIImage *)defaultImage {
    return [UIImage imageNamed:@"XXTEFileReaderType-Image"];
}

+ (Class)relatedEditor {
    return nil;
}

- (instancetype)initWithPath:(NSString *)filePath {
    if (self = [super init]) {
        _entryPath = filePath;
        [self setupWithPath:filePath];
    }
    return self;
}

- (void)setupWithPath:(NSString *)path {
    _executable = NO;
    _editable = NO;
    NSString *entryExtension = [path pathExtension];
    NSString *entryBaseExtension = [entryExtension lowercaseString];
    NSString *entryUpperedExtension = [entryExtension uppercaseString];
    UIImage *iconImage = [self.class defaultImage];
    {
        UIImage *extensionIconImage = [UIImage imageNamed:[NSString stringWithFormat:kXXTEFileTypeImageNameFormat, entryBaseExtension]];
        if (extensionIconImage) {
            iconImage = extensionIconImage;
        }
    }
    _entryIconImage = iconImage;
    _entryExtensionDescription = [NSString stringWithFormat:@"%@ Image", entryUpperedExtension];
    _entryViewerDescription = [XXTEImageViewerController viewerName];
    
    // Meta lazy loading mode
}

- (NSArray <NSString *> *)metaKeys {
    if (!_metaKeys) {
        _metaKeys = @[ @"ColorModel", @"PixelWidth", @"PixelHeight", @"DPIHeight", @"DPIWidth", @"Depth", @"Orientation", @"ProfileName" ];
    }
    return _metaKeys;
}

- (NSDictionary <NSString *, id> *)metaDictionary {
    if (!_metaDictionary) {
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
        
        CGImageSourceRef source = CGImageSourceCreateWithURL(CFBridgingRetain([NSURL fileURLWithPath:self.entryPath]), imageOptions);
        if (source) {
            CFDictionaryRef dictRef = CGImageSourceCopyPropertiesAtIndex(source, 0, imageOptions);
            NSDictionary* metadata = CFBridgingRelease(dictRef);
            _metaDictionary = metadata;
        }
        if (source) {
            CFRelease(source);
        }
        if (imageOptions) {
            CFRelease(imageOptions);
        }
    }
    return _metaDictionary;
}

@end
