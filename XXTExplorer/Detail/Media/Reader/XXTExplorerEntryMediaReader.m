//
//  XXTExplorerEntryMediaReader.m
//  XXTExplorer
//
//  Created by Zheng on 14/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTExplorerEntryMediaReader.h"
#import "XXTEMediaPlayerController.h"
#import <AVFoundation/AVFoundation.h>

@implementation XXTExplorerEntryMediaReader

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
@synthesize encryptionType = _encryptionType;

+ (NSArray <NSString *> *)supportedExtensions {
    return [XXTEMediaPlayerController suggestedExtensions];
}

+ (UIImage *)defaultImage {
    return [UIImage imageNamed:@"XXTEFileReaderType-Media"];
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
    _entryExtensionDescription = [NSString stringWithFormat:@"%@ Media", entryUpperedExtension];
    _entryViewerDescription = [XXTEMediaPlayerController viewerName];
}

- (NSArray <NSString *> *)metaKeys {
    if (!_metaKeys) {
        _metaKeys = @[ @"PixelWidth", @"PixelHeight", @"VideoMediaType", @"VideoDuration", @"VideoNominalFrameRate", @"VideoEstimatedDataRate", @"AudioMediaType", @"AudioDuration" ];
    }
    return _metaKeys;
}

- (NSDictionary <NSString *, id> *)metaDictionary {
    if (!_metaDictionary) {
        
        NSURL *entryURL = [NSURL fileURLWithPath:self.entryPath];
        NSMutableDictionary *mutableMetaDictionary = [[NSMutableDictionary alloc] init];
        
        AVURLAsset *asset = (AVURLAsset *)[AVAsset assetWithURL:entryURL];
        
        {
            AVAssetTrack *videoTrack = nil;
            NSArray <AVAssetTrack *> *videoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
            if (videoTracks.count > 0) {
                if ([videoTracks count] > 0)
                    videoTrack = [videoTracks objectAtIndex:0];
                CGSize trackDimensions = {
                    .width = 0.0,
                    .height = 0.0,
                };
                trackDimensions = [videoTrack naturalSize];
                int pixelWidth = trackDimensions.width;
                int pixelHeight = trackDimensions.height;
                NSString *mediaType = [videoTrack mediaType];
                float frameRate = [videoTrack nominalFrameRate];
                float bps = [videoTrack estimatedDataRate];
                mutableMetaDictionary[@"PixelWidth"] = @(pixelWidth);
                mutableMetaDictionary[@"PixelHeight"]= @(pixelHeight);
                if (mediaType) {
                    mutableMetaDictionary[@"VideoMediaType"] = mediaType;
                }
                mutableMetaDictionary[@"VideoNominalFrameRate"] = @(frameRate);
                mutableMetaDictionary[@"VideoEstimatedDataRate"] = @(bps);
                XXTE_START_IGNORE_PARTIAL
                NSTimeInterval duration = CMTimeGetSeconds(videoTrack.timeRange.duration);
                NSDateComponentsFormatter *dateComponentsFormatter = [[NSDateComponentsFormatter alloc] init];
                mutableMetaDictionary[@"VideoDuration"] = [dateComponentsFormatter stringFromTimeInterval:duration];
                XXTE_END_IGNORE_PARTIAL
            }
            
            AVAssetTrack *audioTrack = nil;
            NSArray <AVAssetTrack *> *audioTracks = [asset tracksWithMediaType:AVMediaTypeAudio];
            if (audioTracks.count > 0) {
                if ([audioTracks count] > 0)
                    audioTrack = [audioTracks objectAtIndex:0];
                NSString *mediaType = [audioTrack mediaType];
                if (mediaType) {
                    mutableMetaDictionary[@"AudioMediaType"] = mediaType;
                }
                XXTE_START_IGNORE_PARTIAL
                NSTimeInterval duration = CMTimeGetSeconds(audioTrack.timeRange.duration);
                NSDateComponentsFormatter *dateComponentsFormatter = [[NSDateComponentsFormatter alloc] init];
                mutableMetaDictionary[@"AudioDuration"] = [dateComponentsFormatter stringFromTimeInterval:duration];
                XXTE_END_IGNORE_PARTIAL
            }
        }
        
        _metaDictionary = [[NSDictionary alloc] initWithDictionary:mutableMetaDictionary];
    }
    return _metaDictionary;
}

@end
