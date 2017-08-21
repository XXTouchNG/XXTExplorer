//
//  XXTEEditorDefaults.h
//  XXTExplorer
//
//  Created by Zheng on 16/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#ifndef XXTEEditorDefaults_h
#define XXTEEditorDefaults_h

#import <Foundation/Foundation.h>

static NSString * const XXTEEditorReadOnly = @"XXTEEditorReadOnly"; // NSNumber - Bool
static NSString * const XXTEEditorFullScreenWhenEditing = @"XXTEEditorFullScreenWhenEditing"; // NSNumber - Bool

static NSString * const XXTEEditorThemeName = @"XXTEEditorThemeName"; // NSString

static NSString * const XXTEEditorHighlightEnabled = @"XXTEEditorHighlightEnabled"; // NSNumber - Bool
static NSString * const XXTEEditorLineNumbersEnabled = @"XXTEEditorLineNumbersEnabled"; // NSNumber - Bool
static NSString * const XXTEEditorKeyboardRowEnabled = @"XXTEEditorKeyboardRowEnabled"; // NSNumber - Bool
static NSString * const XXTEEditorShowInvisibleCharacters = @"XXTEEditorShowInvisibleCharacters"; // NSNumber - Bool

static NSString * const XXTEEditorAutoCorrection = @"XXTEEditorAutoCorrection"; // NSNumber - Enum
static NSString * const XXTEEditorSpellChecking = @"XXTEEditorSpellChecking"; // NSNumber - Enum
static NSString * const XXTEEditorAutoCapitalization = @"XXTEEditorAutoCapitalization"; // NSNumber - Enum

static NSString * const XXTEEditorFontName = @"XXTEEditorFontName"; // NSString
static NSString * const XXTEEditorFontSize = @"XXTEEditorFontSize"; // NSNumber

static NSString * const XXTEEditorAutoIndent = @"XXTEEditorAutoIndent";
static NSString * const XXTEEditorSoftTabs = @"XXTEEditorSoftTabs";
static NSString * const XXTEEditorTabWidth = @"XXTEEditorTabWidth"; // NSNumber

static NSString * const XXTEEditorSearchRegularExpression = @"XXTEEditorSearchRegularExpression"; // NSNumber - Bool
static NSString * const XXTEEditorSearchCaseSensitive = @"XXTEEditorSearchCaseSensitive"; // NSNumber - Bool

typedef enum : NSUInteger {
    XXTEEditorTabWidthValue_2 = 2,
    XXTEEditorTabWidthValue_3 = 3,
    XXTEEditorTabWidthValue_4 = 4,
    XXTEEditorTabWidthValue_8 = 8,
} XXTEEditorTabWidthValue;


#endif /* XXTEEditorDefaults_h */
