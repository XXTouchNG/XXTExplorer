//
//  AVAssetTrack+CoreMediaExtensions.m
//  XXTExplorer
//
//  Created by Zheng on 14/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "AVAssetTrack+CoreMediaExtensions.h"

@implementation AVAssetTrack (CoreMediaExtensions)

- (NSString *)mediaFormat {
    NSMutableString *format = [[NSMutableString alloc] init];
    for (int i = 0; i < self.formatDescriptions.count; i++) {
        CMFormatDescriptionRef desc =
        (__bridge CMFormatDescriptionRef)self.formatDescriptions[i];
        // Get String representation of media type (vide, soun, sbtl, etc.)
        NSString *type = FourCCString(CMFormatDescriptionGetMediaType(desc));
        // Get String representation media subtype (avc1, aac, tx3g, etc.)
        NSString *subType = FourCCString(CMFormatDescriptionGetMediaSubType(desc));
        // Format string as type/subType
        [format appendFormat:@"%@/%@", type, subType];
        // Comma separate if more than one format description
        if (i < self.formatDescriptions.count - 1) {
            [format appendString:@","];
        }
    }
    return format;
}

static NSString * FourCCString(FourCharCode code) {
    NSString *result = [NSString stringWithFormat:@"%c%c%c%c",
                        (char)(code >> 24) & 0xff,
                        (char)(code >> 16) & 0xff,
                        (char)(code >> 8) & 0xff,
                        (char)code & 0xff];
    NSCharacterSet *characterSet = [NSCharacterSet whitespaceCharacterSet];
    return [result stringByTrimmingCharactersInSet:characterSet];
}

@end
