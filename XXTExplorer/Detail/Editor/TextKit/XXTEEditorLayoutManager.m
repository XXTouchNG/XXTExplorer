//
//  XXTEEditorLayoutManager.m
//  XXTExplorer
//
//  Created by Zheng Wu on 15/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEEditorLayoutManager.h"

static CGFloat kMinimumGutterWidth = 42.f;

@interface XXTEEditorLayoutManager ()

@property (nonatomic, assign) CGFloat gutterWidth;
@property (nonatomic, assign) UIEdgeInsets lineAreaInset;

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
    _gutterWidth = kMinimumGutterWidth;
    
    _lineAreaInset = UIEdgeInsetsMake(0.0, 8.0, 0.0, 8.0);
    _lineNumberColor = [UIColor grayColor];
    _lineNumberFont = [UIFont systemFontOfSize:14.0];
    _invisibleColor = [UIColor lightGrayColor];
    _invisibleFont = [UIFont systemFontOfSize:14.f];
    
    unichar crlf = 0x00B6;
    char_CRLF = [[NSString alloc] initWithCharacters:&crlf length:1];
    unichar space = 0x00B7;
    char_SPACE = [[NSString alloc] initWithCharacters:&space length:1];
    unichar tab = 0x25B8;
    char_TAB = [[NSString alloc] initWithCharacters:&tab length:1];
}

- (void)setLineNumberFont:(UIFont *)lineNumberFont {
    _lineNumberFont = lineNumberFont;
    [self reloadGutterWidth];
}

- (void)reloadGutterWidth {
    CGFloat gutterWidth = _lineAreaInset.left + _lineAreaInset.right + [@"00000" sizeWithAttributes:@{ NSFontAttributeName: self.lineNumberFont }].width;
    _gutterWidth = gutterWidth;
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

@end
