//
//  XUIRadioCell.m
//  XXTExplorer
//
//  Created by Zheng on 09/09/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XUIRadioCell.h"
#import "XUITextTagCollectionView.h"
#import "XUI.h"
#import "XUILogger.h"

@interface XUIRadioCell () <XUITextTagCollectionViewDelegate>

@property (weak, nonatomic) IBOutlet XUITextTagCollectionView *tagView;
@property (assign, nonatomic) BOOL shouldUpdateValue;

@end

@implementation XUIRadioCell

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
      @"options": [NSArray class]
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
    
//    self.isRadio = ([self.xui_minCount unsignedIntegerValue] == 1 && [self.xui_maxCount unsignedIntegerValue] == 1);
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
        id selectedValue = self.xui_value;
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

- (NSNumber *)xui_height {
    return @(self.tagView.contentSize.height + 16.f);
}

- (BOOL)textTagCollectionView:(XUITextTagCollectionView *)textTagCollectionView canTapTag:(NSString *)tagText atIndex:(NSUInteger)index currentSelected:(BOOL)currentSelected {
    return YES;
}

- (void)textTagCollectionView:(XUITextTagCollectionView *)textTagCollectionView
                    didTapTag:(NSString *)tagText
                      atIndex:(NSUInteger)index
                     selected:(BOOL)selected
{
    NSUInteger selectedIndexValue = index;
    NSMutableArray *validValues = [[NSMutableArray alloc] init];
    [self.xui_options enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj[XUIOptionCellValueKey]) {
            [validValues addObject:obj[XUIOptionCellValueKey]];
        }
    }];
    if (index < validValues.count) {
        for (NSUInteger tagIndex = 0; tagIndex < textTagCollectionView.allTags.count; tagIndex++) {
            if (tagIndex == index) {
                [textTagCollectionView setTagAtIndex:tagIndex selected:YES];
            } else {
                [textTagCollectionView setTagAtIndex:tagIndex selected:NO];
            }
        }
        id selectedValue = validValues[selectedIndexValue];
        self.xui_value = selectedValue;
        [self.defaultsService saveDefaultsFromCell:self];
    }
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
