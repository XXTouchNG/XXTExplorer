//
//  XXTEEditorTextProperties.h
//  XXTExplorer
//
//  Created by Darwin on 8/2/19.
//  Copyright © 2019 Zheng. All rights reserved.
//

#ifndef XXTEEditorTextProperties_h
#define XXTEEditorTextProperties_h

typedef enum : NSUInteger {
    NSStringLineBreakTypeLF = 0,
    NSStringLineBreakTypeCR,
    NSStringLineBreakTypeCRLF,
} NSStringLineBreakType;

#define NSStringLineBreakLF "\n"
#define NSStringLineBreakCRLF "\r\n"
#define NSStringLineBreakCR "\r"

#endif /* XXTEEditorTextProperties_h */
