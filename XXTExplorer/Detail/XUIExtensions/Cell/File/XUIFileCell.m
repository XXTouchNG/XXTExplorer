//
//  XUIFileCell.m
//  XXTExplorer
//
//  Created by Zheng on 17/09/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XUIFileCell.h"

#import "XXTExplorerDefaults.h"
#import "XXTExplorerEntryParser.h"
#import "XXTExplorerViewController+SharedInstance.h"

@interface XUIFileCell ()

@property (assign, nonatomic) BOOL shouldReloadCellState;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;

@end

@implementation XUIFileCell

@synthesize xui_value = _xui_value, xui_height = _xui_height;

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
      @"allowedExtensions": [NSArray class],
      @"initialPath": [NSString class],
      @"isFile": [NSNumber class],
      @"value": [NSString class],
      @"footerText": [NSString class],
      };
}

- (void)setupCell {
    [super setupCell];
    self.selectionStyle = UITableViewCellSelectionStyleDefault;
    self.accessoryType = UITableViewCellAccessoryNone;
    
    _xui_isFile = @(YES);
    _xui_height = @(XUIFileCellHeight); // standard height for file cell
    _xui_allowedExtensions = @[ @"lua", @"xxt", @"xpp" ];
    
    [self setNeedsReloadCellState];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self reloadCellStateIfNeeded];
}

#pragma mark - Setters

- (void)setInternalTheme:(XUITheme *)theme {
    [super setInternalTheme:theme];
    self.nameLabel.textColor = theme.labelColor;
    self.descriptionLabel.textColor = theme.valueColor;
}

- (void)setXui_isFile:(NSNumber *)xui_isFile {
    _xui_isFile = xui_isFile;
    [self setNeedsReloadCellState];
}

- (void)setXui_value:(id)xui_value {
    _xui_value = xui_value;
    [self setNeedsReloadCellState];
}

- (void)setXui_label:(NSString *)xui_label {
    [super setXui_label:xui_label];
    [self setNeedsReloadCellState];
}

- (void)setXui_footerText:(NSString *)xui_footerText {
    _xui_footerText = xui_footerText;
    [self setNeedsReloadCellState];
}

#pragma mark - Getters

- (BOOL)canDelete {
    return YES;
}

#pragma mark - Reload

- (void)setNeedsReloadCellState {
    self.shouldReloadCellState = YES;
}

- (void)reloadCellStateIfNeeded {
    
    if (!self.shouldReloadCellState) return;
    self.shouldReloadCellState = NO;
    
    NSString *filePath = self.xui_value;
    if (filePath) {
        XXTExplorerEntry *entryDetail = [XXTExplorerViewController.explorerEntryParser entryOfPath:filePath withError:nil];
        if (entryDetail)
        {
            NSString *entryDisplayName = [entryDetail localizedDisplayName];
            NSString *entryDescription = [entryDetail localizedDescription];
            UIImage *entryIconImage = [entryDetail localizedDisplayIconImage];
            self.nameLabel.text = entryDisplayName;
            self.descriptionLabel.text = entryDescription;
            self.iconImageView.image = entryIconImage;
            return;
        }
    }
    NSString *labelText = [self.adapter localizedString:self.xui_label];
    NSString *detailText = [self.adapter localizedString:self.xui_footerText];
    BOOL isFile = [self.xui_isFile boolValue];
    if (isFile) {
        if (labelText.length == 0) {
            labelText = NSLocalizedString(@"Tap here to add a file.", nil);
        }
        if (detailText.length == 0) {
            detailText = [self openWithCellDescriptionFromExtensions:self.xui_allowedExtensions];
        }
    } else {
        if (labelText.length == 0) {
            labelText = NSLocalizedString(@"Tap here to add a directory.", nil);
        }
        if (detailText.length == 0) {
            detailText = NSLocalizedString(@"Enter a directory, and tap the \"Select\" button.", nil);
        }
    }
    self.nameLabel.text = labelText;
    self.descriptionLabel.text = detailText;
    self.iconImageView.image = [UIImage imageNamed:@"XUIFileCellIcon"];
    
}

- (NSString *)openWithCellDescriptionFromExtensions:(NSArray <NSString *> *)extensions {
    NSMutableString *mutableDescription = [@"" mutableCopy];
    [extensions enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (idx < extensions.count - 1)
            [mutableDescription appendFormat:@"%@, ", obj];
        else
            [mutableDescription appendFormat:@"%@. ", obj];
    }];
    return [[NSString alloc] initWithString:mutableDescription];
}

@end
