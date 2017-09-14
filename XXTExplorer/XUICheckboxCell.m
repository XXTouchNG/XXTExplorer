//
//  XUICheckboxCell.m
//  XXTExplorer
//
//  Created by Zheng on 09/09/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XUICheckboxCell.h"
#import "XUITextTagCollectionView.h"
#import "XUI.h"
#import "XUILogger.h"

@interface XUICheckboxCell () <XUITextTagCollectionViewDelegate>

@property (weak, nonatomic) IBOutlet XUITextTagCollectionView *tagView;
@property (assign, nonatomic) BOOL shouldUpdateValue;

@end

@implementation XUICheckboxCell

@synthesize xui_value = _xui_value, theme = _theme;

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
      @"options": [NSArray class],
      @"maxCount": [NSNumber class],
      @"minCount": [NSNumber class],
      @"value": [NSArray class]
      };
}

+ (NSDictionary <NSString *, Class> *)optionValueTypes {
    return
    @{
      XUIOptionCellTitleKey: [NSString class],
      XUIOptionCellShortTitleKey: [NSString class],
      XUIOptionCellIconKey: [NSString class],
      };
}

+ (BOOL)checkEntry:(NSDictionary *)cellEntry withError:(NSError **)error {
    BOOL superResult = [super checkEntry:cellEntry withError:error];
    return superResult;
}

- (void)setupCell {
    [super setupCell];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    self.tagView.scrollView.scrollEnabled = NO;
    self.tagView.defaultConfig.tagCornerRadius = 8.f;
    self.tagView.defaultConfig.tagSelectedCornerRadius = 8.f;
    self.tagView.defaultConfig.tagShadowColor = UIColor.clearColor;
    
    // Alignment
    self.tagView.alignment = XUITagCollectionAlignmentLeft;
    
    // Use manual calculate height
    self.tagView.manualCalculateHeight = YES;
    self.tagView.delegate = self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.tagView.preferredMaxLayoutWidth = CGRectGetWidth(self.bounds) - 16.f;
}

- (void)setXui_options:(NSArray<NSDictionary *> *)xui_options {
    for (NSDictionary *pair in xui_options) {
        for (NSString *pairKey in pair.allKeys) {
            Class pairClass = [[self class] optionValueTypes][pairKey];
            if (pairClass) {
                if (![pair[pairKey] isKindOfClass:pairClass]) {
                    return; // invalid option, ignore
                }
            }
        }
    }
    _xui_options = xui_options;
    NSMutableArray <NSString *> *xui_validTitles = [[NSMutableArray alloc] init];
    [xui_options enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj[XUIOptionCellTitleKey]) {
            [xui_validTitles addObject:obj[XUIOptionCellTitleKey]];
        }
    }];
    [self.tagView removeAllTags];
    [self.tagView addTags:xui_validTitles];
    [self.tagView reload];
    
    [self updateValueIfNeeded];
}

- (void)setXui_value:(id)xui_value {
    _xui_value = xui_value;
    [self setNeedsUpdateValue];
    [self updateValueIfNeeded];
}

- (void)setNeedsUpdateValue {
    self.shouldUpdateValue = YES;
}

- (void)updateValueIfNeeded {
    if (self.shouldUpdateValue && self.tagView.allTags.count > 0) {
        self.shouldUpdateValue = NO;
        NSArray *selectedValues = self.xui_value;
        NSUInteger minCount = [self.xui_minCount unsignedIntegerValue];
        NSUInteger maxCount = [self.xui_maxCount unsignedIntegerValue];
        if (selectedValues.count > maxCount || selectedValues.count < minCount) {
            return; // Invalid value, ignore
        }
        for (id selectedValue in selectedValues) {
            NSUInteger selectedIndex = [self.xui_options indexOfObjectPassingTest:^BOOL(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([selectedValue isEqual:obj[XUIOptionCellValueKey]]) {
                    return YES;
                }
                return NO;
            }];
            if (selectedIndex != NSNotFound) {
                [self.tagView setTagAtIndex:selectedIndex selected:YES];
            }
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
    NSMutableArray *validValues = [[NSMutableArray alloc] init];
    [self.xui_options enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj[XUIOptionCellValueKey]) {
            [validValues addObject:obj[XUIOptionCellValueKey]];
        }
    }];
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

- (void)setXui_alignment:(NSString *)xui_alignment {
    _xui_alignment = xui_alignment;
    if ([xui_alignment isEqualToString:@"left"]) {
        self.tagView.alignment = XUITagCollectionAlignmentLeft;
    }
    else if ([xui_alignment isEqualToString:@"center"]) {
        self.tagView.alignment = XUITagCollectionAlignmentCenter;
    }
    else if ([xui_alignment isEqualToString:@"right"]) {
        self.tagView.alignment = XUITagCollectionAlignmentRight;
    }
    else if ([xui_alignment isEqualToString:@"natural"]) {
        self.tagView.alignment = XUITagCollectionAlignmentFillByExpandingSpace;
    }
    else if ([xui_alignment isEqualToString:@"justified"]) {
        self.tagView.alignment = XUITagCollectionAlignmentFillByExpandingWidth;
    }
    else {
        self.tagView.alignment = XUITagCollectionAlignmentLeft;
    }
}

- (void)setXui_enabled:(NSNumber *)xui_enabled {
    [super setXui_enabled:xui_enabled];
    BOOL enabled = [xui_enabled boolValue];
    self.tagView.enableTagSelection = enabled;
}

- (void)setTheme:(XUITheme *)theme {
    _theme = theme;
    self.tagView.defaultConfig.tagBackgroundColor = theme.successColor;
    self.tagView.defaultConfig.tagSelectedBackgroundColor = theme.highlightColor;
    [self.tagView reload];
}

@end
