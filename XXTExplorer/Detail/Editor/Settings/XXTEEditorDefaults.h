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


#pragma mark - States (No Value)

static NSString * const XXTEEditorLanguageReloaded = @"XXTEEditorLanguageReloaded"; // -> self.language
static NSString * const XXTEEditorLockedStateChanged = @"XXTEEditorLockedStateChanged"; // -> self.isLockedState
static NSString * const XXTEEditorInitialNumberOfLinesChanged = @"XXTEEditorInitialNumberOfLinesChanged"; // -> self.initialNumberOfLines


#pragma mark - Preferences (Contains Value)

static NSString * const XXTEEditorReadOnly = @"XXTEEditorReadOnly"; // NSNumber - Bool
static NSString * const XXTEEditorSimpleTitleView = @"XXTEEditorSimpleTitleView"; // NSNumber - Bool
static NSString * const XXTEEditorFullScreenWhenEditing = @"XXTEEditorFullScreenWhenEditing"; // NSNumber - Bool

static NSString * const XXTEEditorThemeName = @"XXTEEditorThemeName"; // NSString

static NSString * const XXTEEditorHighlightEnabled = @"XXTEEditorHighlightEnabled"; // NSNumber - Bool
static NSString * const XXTEEditorLineNumbersEnabled = @"XXTEEditorLineNumbersEnabled"; // NSNumber - Bool

static NSString * const XXTEEditorKeyboardRowAccessoryEnabled = @"XXTEEditorKeyboardRowAccessoryEnabled"; // NSNumber - Bool
static NSString * const XXTEEditorKeyboardASCIIPreferred = @"XXTEEditorKeyboardASCIIPreferred"; // NSNumber - Bool
static NSString * const XXTEEditorShowInvisibleCharacters = @"XXTEEditorShowInvisibleCharacters"; // NSNumber - Bool

static NSString * const XXTEEditorIndentWrappedLines = @"XXTEEditorIndentWrappedLines"; // NSNumber - Bool
static NSString * const XXTEEditorAutoWordWrap = @"XXTEEditorAutoWordWrap"; // NSNumber - Bool
static NSString * const XXTEEditorWrapColumn = @"XXTEEditorWrapColumn"; // NSNumber - NSUInteger, min = 10

static NSString * const XXTEEditorAutoCorrection = @"XXTEEditorAutoCorrection"; // NSNumber - Enum
static NSString * const XXTEEditorSpellChecking = @"XXTEEditorSpellChecking"; // NSNumber - Enum
static NSString * const XXTEEditorAutoCapitalization = @"XXTEEditorAutoCapitalization"; // NSNumber - Enum
static NSString * const XXTEEditorAutoBrackets = @"XXTEEditorAutoBrackets"; // NSNumber - Bool

static NSString * const XXTEEditorFontName = @"XXTEEditorFontName"; // NSString
static NSString * const XXTEEditorFontSize = @"XXTEEditorFontSize"; // NSNumber -> Integer from 8 to 32

static NSString * const XXTEEditorAutoIndent = @"XXTEEditorAutoIndent"; // NSNumber - Bool
static NSString * const XXTEEditorSoftTabs = @"XXTEEditorSoftTabs"; // NSNumber - Bool
static NSString * const XXTEEditorTabWidth = @"XXTEEditorTabWidth"; // NSNumber -> 2, 3, 4 or 8

static NSString * const XXTEEditorSearchRegularExpression = @"XXTEEditorSearchRegularExpression"; // NSNumber - Bool
static NSString * const XXTEEditorSearchCaseSensitive = @"XXTEEditorSearchCaseSensitive"; // NSNumber - Bool
static NSString * const XXTEEditorSearchCircular = @"XXTEEditorSearchCircular"; // NSNumber - Bool

typedef enum : NSUInteger {
    XXTEEditorTabWidthValue_2 = 2,
    XXTEEditorTabWidthValue_3 = 3,
    XXTEEditorTabWidthValue_4 = 4,
    XXTEEditorTabWidthValue_8 = 8,
} XXTEEditorTabWidthValue;

#endif /* XXTEEditorDefaults_h */
