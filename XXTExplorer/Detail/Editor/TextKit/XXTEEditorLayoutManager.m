//
//  XXTEEditorLayoutManager.m
//  XXTExplorer
//
//  Created by Zheng Wu on 15/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEEditorLayoutManager.h"

// static CGFloat kMinimumGutterWidth = 42.f;

@interface XXTEEditorLayoutManager ()

@property (nonatomic) NSUInteger lastParaLocation;
@property (nonatomic) NSUInteger lastParaNumber;

@end

@interface XXTEEditorLayoutManager ()

@end


@implementation XXTEEditorLayoutManager {
    NSString *char_CRLF;
    NSString *char_SPACE;
    NSString *char_TAB;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        [self setup];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        [self setup];
    }
    return self;
}

- (void)setup
{
    self.allowsNonContiguousLayout = NO;
    
    _lineNumberColor = [UIColor grayColor];
    _lineNumberFont = [UIFont systemFontOfSize:14.0];
    _invisibleColor = [UIColor lightGrayColor];
    _invisibleFont = [UIFont systemFontOfSize:14.f];
    _lineAreaInset = UIEdgeInsetsMake(0.0, 8.0, 0.0, 8.0);
    _lineHeightScale = 1.05;
    
    [self reloadGutterWidth];
    
    unichar crlf = 0x00B6;
    char_CRLF = [[NSString alloc] initWithCharacters:&crlf length:1];
    unichar space = 0x00B7;
    char_SPACE = [[NSString alloc] initWithCharacters:&space length:1];
    unichar tab = 0x25B8;
    char_TAB = [[NSString alloc] initWithCharacters:&tab length:1];
}

#pragma mark - Getters & Setters

- (void)setLineNumberFont:(UIFont *)lineNumberFont {
    _lineNumberFont = lineNumberFont;
    _fontPointSize = lineNumberFont.pointSize;
    [self reloadGutterWidth];
    [self invalidateLayoutForCharacterRange:NSMakeRange(0, self.textStorage.length) actualCharacterRange:NULL];
}

- (void)setLineHeightScale:(CGFloat)lineHeightScale {
    _lineHeightScale = lineHeightScale;
    [self invalidateLayoutForCharacterRange:NSMakeRange(0, self.textStorage.length) actualCharacterRange:NULL];
}

- (void)reloadGutterWidth {
    CGFloat gutterWidth = _lineAreaInset.left + _lineAreaInset.right + [@"00000" sizeWithAttributes:@{ NSFontAttributeName: self.lineNumberFont }].width;
    _gutterWidth = gutterWidth;
}

- (BOOL)indentWrappedLines {
    return NO;
    // this method has some bugs so we had to disable it temporarily
}

#pragma mark - Convenience

//- (CGRect)paragraphRectForRange:(NSRange)range
//{
//    range = [self.textStorage.string paragraphRangeForRange:range];
//    range = [self glyphRangeForCharacterRange:range actualCharacterRange:NULL];
//    
//    CGRect startRect = [self lineFragmentRectForGlyphAtIndex:range.location effectiveRange:NULL];
//    CGRect endRect = [self lineFragmentRectForGlyphAtIndex:range.location + range.length - 1 effectiveRange:NULL];
//    
//    CGRect paragraphRectForRange = CGRectUnion(startRect, endRect);
//    paragraphRectForRange = CGRectOffset(paragraphRectForRange, _gutterWidth, 8.0);
//    
//    return paragraphRectForRange;
//}

- (NSUInteger) _paraNumberForRange:(NSRange) charRange {
    //  NSString does not provide a means of efficiently determining the paragraph number of a range of text.  This code
    //  attempts to optimize what would normally be a series linear searches by keeping track of the last paragraph number
    //  found and uses that as the starting point for next paragraph number search.  This works (mostly) because we
    //  are generally asked for continguous increasing sequences of paragraph numbers.  Also, this code is called in the
    //  course of drawing a pagefull of text, and so even when moving back, the number of paragraphs to search for is
    //  relativly low, even in really long bodies of text.
    //
    //  This all falls down when the user edits the text, and can potentially invalidate the cached paragraph number which
    //  causes a (potentially lengthy) search from the beginning of the string.
    
    if (charRange.location == self.lastParaLocation)
        return self.lastParaNumber;
    else if (charRange.location < self.lastParaLocation) {
        //  We need to look backwards from the last known paragraph for the new paragraph range.  This generally happens
        //  when the text in the UITextView scrolls downward, revaling paragraphs before/above the ones previously drawn.
        
        NSString* s = self.textStorage.string;
        __block NSUInteger paraNumber = self.lastParaNumber;
        
        [s enumerateSubstringsInRange:NSMakeRange(charRange.location, self.lastParaLocation - charRange.location)
                              options:NSStringEnumerationByParagraphs |
         NSStringEnumerationSubstringNotRequired |
         NSStringEnumerationReverse
                           usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop){
                               if (enclosingRange.location <= charRange.location) {
                                   *stop = YES;
                               }
                               --paraNumber;
                           }];
        
        self.lastParaLocation = charRange.location;
        self.lastParaNumber = paraNumber;
        return paraNumber;
    }
    else {
        //  We need to look forward from the last known paragraph for the new paragraph range.  This generally happens
        //  when the text in the UITextView scrolls upwards, revealing paragraphs that follow the ones previously drawn.
        
        NSString* s = self.textStorage.string;
        __block NSUInteger paraNumber = self.lastParaNumber;
        
        [s enumerateSubstringsInRange:NSMakeRange(self.lastParaLocation, charRange.location - self.lastParaLocation)
                              options:NSStringEnumerationByParagraphs | NSStringEnumerationSubstringNotRequired
                           usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop){
                               if (enclosingRange.location >= charRange.location) {
                                   *stop = YES;
                               }
                               ++paraNumber;
                           }];
        
        self.lastParaLocation = charRange.location;
        self.lastParaNumber = paraNumber;
        return paraNumber;
    }
}

#pragma mark - Layouting

- (void)processEditingForTextStorage:(NSTextStorage *)textStorage edited:(NSTextStorageEditActions)editMask range:(NSRange)newCharRange changeInLength:(NSInteger)delta invalidatedRange:(NSRange)invalidatedCharRange {
    [super processEditingForTextStorage:textStorage edited:editMask range:newCharRange changeInLength:delta invalidatedRange:invalidatedCharRange];
    
    if (invalidatedCharRange.location < self.lastParaLocation) {
        //  When the backing store is edited ahead the cached paragraph location, invalidate the cache and force a complete
        //  recalculation.  We cannot be much smarter than this because we don't know how many paragraphs have been deleted
        //  since the text has already been removed from the backing store.
        
        self.lastParaLocation = 0;
        self.lastParaNumber = 0;
    }
}

#pragma mark - Drawing

- (void)drawBackgroundForGlyphRange:(NSRange)glyphsToShow atPoint:(CGPoint)origin
{
    [super drawBackgroundForGlyphRange:glyphsToShow atPoint:origin];
    if (self.showLineNumbers == NO) return;
    
    //  Draw line numbers.  Note that the background for line number gutter is drawn by the LineNumberTextView class.
    NSDictionary* attrs = @{NSFontAttributeName: self.lineNumberFont, NSForegroundColorAttributeName: self.lineNumberColor};
    
    __block CGRect gutterRect = CGRectZero;
    __block NSUInteger paraNumber;
    
    @weakify(self);
    [self enumerateLineFragmentsForGlyphRange:glyphsToShow
                                   usingBlock:^
     (CGRect rect, CGRect usedRect, NSTextContainer *textContainer, NSRange glyphRange, BOOL *stop)
     {
         @strongify(self);
         NSRange charRange = [self characterRangeForGlyphRange:glyphRange actualGlyphRange:nil];
         NSRange paraRange = [self.textStorage.string paragraphRangeForRange:charRange];
         
         //   Only draw line numbers for the paragraph's first line fragment. Subsequent fragments are wrapped portions of the paragraph and don't get the line number.
         if (charRange.location == paraRange.location) {
             gutterRect = CGRectOffset(CGRectMake(0, rect.origin.y, self.gutterWidth, rect.size.height), origin.x, origin.y);
             paraNumber = [self _paraNumberForRange:charRange];
             NSString *lineNumber = [NSString stringWithFormat:@"%ld", (unsigned long) paraNumber + 1];
             CGSize size = [lineNumber sizeWithAttributes:attrs];
             
             [lineNumber drawInRect:CGRectOffset(gutterRect, CGRectGetWidth(gutterRect) - self.lineAreaInset.right - size.width - self.gutterWidth, (CGRectGetHeight(gutterRect) - size.height) / 2.0)
             withAttributes:attrs];
         }
         
     }];
    
    //  Deal with the special case of an empty last line where enumerateLineFragmentsForGlyphRange has no line
    //  fragments to draw.
//    if (NSMaxRange(glyphsToShow) >= self.numberOfGlyphs) {
//        NSString *lineNumber = [NSString stringWithFormat:@"%ld", (unsigned long) paraNumber + 2];
//        CGSize size = [lineNumber sizeWithAttributes:attrs];
//        
//        gutterRect = CGRectOffset(gutterRect, 0.0, CGRectGetHeight(gutterRect));
//        [lineNumber drawInRect:CGRectOffset(gutterRect, CGRectGetWidth(gutterRect) - self->_lineAreaInset.right - size.width - self->_gutterWidth, (CGRectGetHeight(gutterRect) - size.height) / 2.0)
//                withAttributes:attrs];
//    }
}

- (void)drawGlyphsForGlyphRange:(NSRange)glyphsToShow atPoint:(CGPoint)origin {
    if (self.showInvisibleCharacters) {
        NSString *docContents = [[self textStorage] string];
        NSDictionary *attrs = @{ NSForegroundColorAttributeName: self.invisibleColor, NSFontAttributeName: self.invisibleFont };
        for (NSUInteger i = glyphsToShow.location; i < NSMaxRange(glyphsToShow); i++)
        {
            NSString *glyph = nil;
            switch ([docContents characterAtIndex:i])
            {
                case 0x20:
                    glyph = char_SPACE;
                    break;
                case '\t':
                    glyph = char_TAB;
                    break;
                case 0x2028:
                case 0x2029:
                case '\n':
                case '\r':
                    glyph = char_CRLF;
                    break;
                default:
                    glyph = nil;
                    break;
            }
            if (glyph)
            {
                CGRect glyphRect = [self lineFragmentRectForGlyphAtIndex:i effectiveRange:NULL];
                CGPoint glyphPoint = [self locationForGlyphAtIndex:i];
                CGPoint drawPoint = CGPointMake(glyphPoint.x + glyphRect.origin.x + origin.x, glyphRect.origin.y + origin.y);
                
                [glyph drawAtPoint:drawPoint withAttributes:attrs];
            }
        }
    }
    [super drawGlyphsForGlyphRange:glyphsToShow atPoint:origin];
}

#pragma mark - Layout Computation

- (UIEdgeInsets)insetsForLineStartingAtCharacterIndex:(NSUInteger)characterIndex
{
    CGFloat leftInset = 0;
    
    // Base inset when showing paragraph numbers (here we just ignore this)
//    if (self.showLineNumbers)
//        leftInset += _gutterWidth;
    
    // For wrapped lines, determine where line is supposed to start
    NSRange paragraphRange = [self.textStorage.string paragraphRangeForRange:NSMakeRange(characterIndex, 0)];
    if (paragraphRange.location < characterIndex) {
        // Get the first glyph index in the paragraph
        NSUInteger firstGlyphIndex = [self glyphIndexForCharacterAtIndex:paragraphRange.location];
        
        // Get the first line of the paragraph
        NSRange firstLineGlyphRange;
        [self lineFragmentRectForGlyphAtIndex:firstGlyphIndex effectiveRange:&firstLineGlyphRange];
        NSRange firstLineCharRange = [self characterRangeForGlyphRange:firstLineGlyphRange actualGlyphRange:NULL];
        
        // Find the first wrapping char (here we use brackets), and wrap one char behind
        NSUInteger wrappingCharIndex = NSNotFound;
        wrappingCharIndex = [self.textStorage.string rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString: @"({["] options:0 range:firstLineCharRange].location;
        if (wrappingCharIndex != NSNotFound)
            wrappingCharIndex += 1;
        
        // Alternatively, fall back to the first text (ie. non-whitespace) char
        if (wrappingCharIndex == NSNotFound) {
            wrappingCharIndex = [self.textStorage.string rangeOfCharacterFromSet:[NSCharacterSet.whitespaceCharacterSet invertedSet] options:0 range:firstLineCharRange].location;
            if (wrappingCharIndex != NSNotFound)
                wrappingCharIndex += 4;
        }
        
        // Wrapping char found, determine indent
        if (wrappingCharIndex != NSNotFound) {
            NSUInteger firstTextGlyphIndex = [self glyphIndexForCharacterAtIndex:wrappingCharIndex];
            
            // The additional indent is the distance from the first to the last character
            leftInset += [self locationForGlyphAtIndex:firstTextGlyphIndex].x - [self locationForGlyphAtIndex:firstGlyphIndex].x;
        }
    }
    
    // For now we compute left insets only, but rigth inset is also possible
    return UIEdgeInsetsMake(0, leftInset, 0, 0);
}

- (void)setLineFragmentRect:(CGRect)fragmentRect forGlyphRange:(NSRange)glyphRange usedRect:(CGRect)usedRect
{
    // IMPORTANT: Perform the shift of the X-coordinate that cannot be done in NSTextContainer's -lineFragmentRectForProposedRect:atIndex:writingDirection:remainingRect:
    if ([self indentWrappedLines]) {
        UIEdgeInsets insets = [self insetsForLineStartingAtCharacterIndex: [self characterIndexForGlyphAtIndex: glyphRange.location]];
        
        fragmentRect.origin.x += insets.left;
        usedRect.origin.x += insets.left;
    }

    [super setLineFragmentRect:fragmentRect forGlyphRange:glyphRange usedRect:usedRect];
}

- (void)setExtraLineFragmentRect:(CGRect)fragmentRect usedRect:(CGRect)usedRect textContainer:(NSTextContainer *)container
{
    // Etxra line fragment rect must be indented just like every other line fragment rect
    if ([self indentWrappedLines]) {
        UIEdgeInsets insets = [self insetsForLineStartingAtCharacterIndex: self.textStorage.length];
        
        fragmentRect.origin.x += insets.left;
        usedRect.origin.x += insets.left;
    }

    [super setExtraLineFragmentRect:fragmentRect usedRect:usedRect textContainer:container];
}

@end
