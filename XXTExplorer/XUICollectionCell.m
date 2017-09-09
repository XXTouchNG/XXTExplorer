//
//  XUICollectionCell.m
//  XXTExplorer
//
//  Created by Zheng on 09/09/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XUICollectionCell.h"
#import "XUITextTagCollectionView.h"
#import "XUI.h"
#import "XUILogger.h"

@interface XUICollectionCell () <XUITextTagCollectionViewDelegate>

@property (weak, nonatomic) IBOutlet XUITextTagCollectionView *tagView;

@end

@implementation XUICollectionCell

@synthesize xui_value = _xui_value;

+ (BOOL)xibBasedLayout {
    return YES;
}

+ (BOOL)layoutNeedsTextLabel {
    return NO;
}

+ (BOOL)layoutNeedsImageView {
    return NO;
}

+ (BOOL)layoutRequiresDynamicRowHeight {
    return NO;
}

+ (NSDictionary <NSString *, Class> *)entryValueTypes {
    return
    @{
      @"validTitles": [NSArray class],
      @"validValues": [NSArray class],
      @"maxCount": [NSNumber class],
      @"minCount": [NSNumber class],
      @"value": [NSArray class]
      };
}

+ (BOOL)checkEntry:(NSDictionary *)cellEntry withError:(NSError **)error {
    BOOL superResult = [super checkEntry:cellEntry withError:error];
    NSString *checkType = kXUICellFactoryErrorDomain;
    @try {
        NSArray *validTitles = cellEntry[@"validTitles"];
        NSArray *validValues = cellEntry[@"validValues"];
        if (validTitles && validValues) {
            if (validTitles.count != validValues.count) {
                superResult = NO;
                checkType = kXUICellFactoryErrorSizeDismatchDomain;
                @throw [NSString stringWithFormat:NSLocalizedString(@"The size of \"%@\" and \"%@\" does not match.", nil), @"validTitles", @"validValues"];
            }
        }
        for (NSString *validTitle in validTitles) {
            if (![validTitle isKindOfClass:[NSString class]]) {
                superResult = NO;
                checkType = kXUICellFactoryErrorInvalidTypeDomain;
                @throw [NSString stringWithFormat:NSLocalizedString(@"The member type of \"%@\" should be \"%@\".", nil), @"validTitles", @"NSString"];
            }
        }
    } @catch (NSString *exceptionReason) {
        NSError *exceptionError = [NSError errorWithDomain:checkType code:400 userInfo:@{ NSLocalizedDescriptionKey: exceptionReason }];
        if (error) {
            *error = exceptionError;
        }
    } @finally {
        
    }
    return superResult;
}

- (void)setupCell {
    [super setupCell];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    self.tagView.scrollView.scrollEnabled = NO;
    self.tagView.defaultConfig.tagCornerRadius = 8.f;
    self.tagView.defaultConfig.tagSelectedCornerRadius = 8.f;
    self.tagView.defaultConfig.tagBackgroundColor = XXTE_COLOR_SUCCESS;
    self.tagView.defaultConfig.tagShadowColor = UIColor.clearColor;
    
    // Alignment
    self.tagView.alignment = XUITagCollectionAlignmentLeft;
    
    // Use manual calculate height
    self.tagView.manualCalculateHeight = YES;
    self.tagView.delegate = self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.tagView.preferredMaxLayoutWidth = self.tagView.bounds.size.width;
}

- (void)setXui_validTitles:(NSArray<NSString *> *)xui_validTitles {
    _xui_validTitles = xui_validTitles;
    
    [self.tagView removeAllTags];
    [self.tagView addTags:xui_validTitles];
    [self.tagView reload];
}

- (void)setXui_value:(id)xui_value {
    _xui_value = xui_value;
    
//     Random selected
//    for (NSInteger i = 0; i < 3; i++) {
//        [self.tagView setTagAtIndex:arc4random_uniform((uint32_t)tags.count) selected:YES];
//    }
    
    NSArray *selectedValues = xui_value;
    for (id selectedValue in selectedValues) {
        NSUInteger selectedIndex = [self.xui_validValues indexOfObject:selectedValue];
        if (selectedIndex != NSNotFound) {
            [self.tagView setTagAtIndex:selectedIndex selected:YES];
        }
    }
    
}

- (NSNumber *)xui_height {
    return @(self.tagView.contentSize.height + 16.f);
}

- (BOOL)textTagCollectionView:(XUITextTagCollectionView *)textTagCollectionView canTapTag:(NSString *)tagText atIndex:(NSUInteger)index currentSelected:(BOOL)currentSelected {
    NSArray *selectedValues = self.xui_value;
    NSUInteger maxCount = [self.xui_maxCount unsignedIntegerValue];
    NSUInteger minCount = [self.xui_minCount unsignedIntegerValue];
    if (selectedValues.count >= maxCount && currentSelected == NO) {
        return NO;
    }
    else if (selectedValues.count <= minCount && currentSelected == YES) {
        return NO;
    }
    return YES;
}

- (void)textTagCollectionView:(XUITextTagCollectionView *)textTagCollectionView
                    didTapTag:(NSString *)tagText
                      atIndex:(NSUInteger)index
                     selected:(BOOL)selected
{
    NSArray *validValues = self.xui_validValues;
    NSMutableArray *selectedValues = [[NSMutableArray alloc] init];
    NSArray <NSNumber *> *selectedIndexes = textTagCollectionView.allSelectedIndexes;
    for (NSNumber *selectedIndex in selectedIndexes) {
        NSUInteger selectedIndexValue = [selectedIndex unsignedIntegerValue];
        id selectedValue = validValues[selectedIndexValue];
        if (selectedValue) [selectedValues addObject:selectedValue];
    }
    self.xui_value = [selectedValues copy];
    [self.defaultsService saveDefaultsFromCell:self];
}

@end
