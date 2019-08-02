//
//  XXTEEditorEncodingHelper.m
//  XXTExplorer
//
//  Created by Darwin on 8/2/19.
//  Copyright © 2019 Zheng. All rights reserved.
//

#import "XXTEEditorEncodingHelper.h"

@implementation XXTEEditorEncodingHelper

+ (NSDictionary *)encodingMap {
    static NSDictionary *encodingMap = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        encodingMap = @{
                        @(kCFStringEncodingUTF8): @"Unicode (UTF-8)",
                        @(kCFStringEncodingASCII): @"Western (ASCII)",
                        @(kCFStringEncodingISOLatin1): @"Western (ISO Latin 1)",
                        @(kCFStringEncodingMacRoman): @"Western (Mac OS Roman)",
                        @(kCFStringEncodingWindowsLatin1): @"Western (Windows Latin 1, CP 1252)",
                        @(kCFStringEncodingDOSLatin1): @"Western (DOS Latin 1, CP 850)",
                        @(kCFStringEncodingISOLatin3): @"Western (ISO Latin 3)",
                        @(kCFStringEncodingISOLatin9): @"Western (ISO Latin 9)",
                        @(kCFStringEncodingDOSLatinUS): @"Latin-US (DOS, CP 437)",
                        @(kCFStringEncodingISOLatin7): @"Baltic (ISO Latin 7)",
                        @(kCFStringEncodingWindowsBalticRim): @"Baltic (Windows)",
                        @(kCFStringEncodingDOSBalticRim): @"Baltic (DOS)",
                        @(kCFStringEncodingISOLatin2): @"Central European (ISO Latin 2)",
                        @(kCFStringEncodingISOLatin4): @"Central European (ISO Latin 4)",
                        @(kCFStringEncodingMacCentralEurRoman): @"Central European (Mac OS)",
                        @(kCFStringEncodingWindowsLatin2): @"Central European (Windows Latin 2)",
                        @(kCFStringEncodingDOSLatin2): @"Central European (DOS Latin 2, CP 852)",
                        @(kCFStringEncodingKOI8_R): @"Cyrillic (KOI8-R)",
                        @(kCFStringEncodingISOLatinCyrillic): @"Cyrillic (ISO 8859-5)",
                        @(kCFStringEncodingMacCyrillic): @"Cyrillic (Mac OS)",
                        @(kCFStringEncodingWindowsCyrillic): @"Cyrillic (Windows, CP 1251)",
                        @(kCFStringEncodingDOSCyrillic): @"Cyrillic (DOS)",
                        @(kCFStringEncodingISOLatinGreek): @"Greek (ISO 8859-7)",
                        @(kCFStringEncodingMacGreek): @"Greek (Mac OS)",
                        @(kCFStringEncodingWindowsGreek): @"Greek (Windows, CP 1253)",
                        @(kCFStringEncodingDOSGreek): @"Greek (DOS)",
                        @(kCFStringEncodingDOSGreek1): @"Greek (DOS Greek 1)",
                        @(kCFStringEncodingDOSGreek2): @"Greek (DOS Greek 2)",
                        @(kCFStringEncodingISOLatin6): @"Nordic (ISO Latin 6)",
                        @(kCFStringEncodingDOSNordic): @"Nordic (DOS)",
                        @(kCFStringEncodingISOLatin8): @"Celtic (ISO Latin 8)",
                        @(kCFStringEncodingMacCeltic): @"Celtic (Mac OS)",
                        @(kCFStringEncodingISOLatin10): @"Romanian (ISO Latin 10)",
                        @(kCFStringEncodingMacRomanian): @"Romanian (Mac OS)",
                        @(kCFStringEncodingISOLatin5): @"Turkish (ISO Latin 5)",
                        @(kCFStringEncodingMacTurkish): @"Turkish (Mac OS)",
                        @(kCFStringEncodingWindowsLatin5): @"Turkish (Windows Latin 5)",
                        @(kCFStringEncodingDOSTurkish): @"Turkish (DOS)",
                        @(kCFStringEncodingShiftJIS): @"Japanese (Shift JIS)",
                        @(kCFStringEncodingISO_2022_JP): @"Japanese (ISO 2022-JP)",
                        @(kCFStringEncodingISO_2022_JP_1): @"Japanese (ISO 2022-JP-1)",
                        @(kCFStringEncodingISO_2022_JP_2): @"Japanese (ISO 2022-JP-2)",
                        @(kCFStringEncodingISO_2022_JP_3): @"Japanese (ISO 2022-JP-3)",
                        @(kCFStringEncodingEUC_JP): @"Japanese (EUC)",
                        @(kCFStringEncodingMacJapanese): @"Japanese (Mac OS)",
                        @(kCFStringEncodingDOSJapanese): @"Japanese (Windows, DOS)",
                        @(kCFStringEncodingGB_18030_2000): @"Chinese (GB 18030)",
                        @(kCFStringEncodingISO_2022_CN): @"Chinese (ISO 2022-CN)",
                        @(kCFStringEncodingISO_2022_CN_EXT): @"Chinese (ISO 2022-CN-EXT)",
                        @(kCFStringEncodingGB_2312_80): @"Simplified Chinese (GB 2312)",
                        @(kCFStringEncodingMacChineseSimp): @"Simplified Chinese (Mac OS)",
                        @(kCFStringEncodingDOSChineseSimplif): @"Simplified Chinese (Windows, DOS)",
                        @(kCFStringEncodingBig5): @"Traditional Chinese (Big 5)",
                        @(kCFStringEncodingBig5_HKSCS_1999): @"Traditional Chinese (Big 5 HKSCS)",
                        @(kCFStringEncodingEUC_TW): @"Traditional Chinese (EUC)",
                        @(kCFStringEncodingMacChineseTrad): @"Traditional Chinese (Mac OS)",
                        @(kCFStringEncodingDOSChineseTrad): @"Traditional Chinese (Windows, DOS)",
                        @(kCFStringEncodingEUC_KR): @"Korean (EUC)",
                        @(kCFStringEncodingMacKorean): @"Korean (Mac OS)",
                        @(kCFStringEncodingWindowsKoreanJohab): @"Korean (Windows Johab)",
                        @(kCFStringEncodingDOSKorean): @"Korean (Windows, DOS)",
                        @(kCFStringEncodingMacVietnamese): @"Vietnamese (Mac OS)",
                        @(kCFStringEncodingWindowsVietnamese): @"Vietnamese (Windows)",
                        @(kCFStringEncodingISOLatinThai): @"Thai (ISO 8859-11)",
                        @(kCFStringEncodingMacThai): @"Thai (Mac OS)",
                        @(kCFStringEncodingDOSThai): @"Thai (Windows, DOS)",
                        @(kCFStringEncodingISOLatinHebrew): @"Hebrew (ISO 8859-8)",
                        @(kCFStringEncodingMacHebrew): @"Hebrew (Mac OS)",
                        @(kCFStringEncodingWindowsHebrew): @"Hebrew (Windows)",
                        @(kCFStringEncodingDOSHebrew): @"Hebrew (DOS)",
                        @(kCFStringEncodingISOLatinArabic): @"Arabic (ISO 8859-6)",
                        @(kCFStringEncodingMacArabic): @"Arabic (Mac OS)",
                        @(kCFStringEncodingWindowsArabic): @"Arabic (Windows)",
                        @(kCFStringEncodingDOSArabic): @"Arabic (DOS)",
                        @(kCFStringEncodingUTF16): @"Unicode (UTF-16)",
                        @(kCFStringEncodingUTF16BE): @"Unicode (UTF-16BE)",
                        @(kCFStringEncodingUTF16LE): @"Unicode (UTF-16LE)",
                        @(kCFStringEncodingUTF32): @"Unicode (UTF-32)",
                        @(kCFStringEncodingUTF32BE): @"Unicode (UTF-32BE)",
                        @(kCFStringEncodingUTF32LE): @"Unicode (UTF-32LE)",
                        @(kCFStringEncodingEBCDIC_US): @"Western (EBCDIC US)",
                        @(kCFStringEncodingEBCDIC_CP037): @"Western (EBCDIC Latin 1)",
                        @(kCFStringEncodingNonLossyASCII): @"Non-lossy ASCII",
                        };
    });
    return encodingMap;
}

+ (NSString *)encodingNameForEncoding:(CFStringEncoding)encoding {
    return [[self class] encodingMap][@(encoding)];
}

@end
