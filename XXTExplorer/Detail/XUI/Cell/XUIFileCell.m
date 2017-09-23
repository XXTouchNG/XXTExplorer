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
#import "XXTExplorerEntryReader.h"

@interface XUIFileCell ()
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
      @"value": [NSString class]
      };
}

+ (BOOL)checkEntry:(NSDictionary *)cellEntry withError:(NSError **)error {
    BOOL superResult = [super checkEntry:cellEntry withError:error];
    return superResult;
}

- (void)setupCell {
    [super setupCell];
    self.selectionStyle = UITableViewCellSelectionStyleDefault;
    
    _xui_height = @(72.f); // standard height for date time picker
    _xui_allowedExtensions = @[ @"lua", @"xxt", @"xpp" ];
    
    [self resetCellState];
}

- (void)setXui_value:(id)xui_value {
    if (!xui_value) {
        _xui_value = xui_value;
        [self resetCellState];
        return;
    }
    NSString *filePath = xui_value;
    if (filePath) {
        NSDictionary *entryDetail = [XXTExplorerViewController.explorerEntryParser entryOfPath:filePath withError:nil];
        if (entryDetail)
        {
            NSString *entryDisplayName = entryDetail[XXTExplorerViewEntryAttributeDisplayName];
            NSString *entryDescription = entryDetail[XXTExplorerViewEntryAttributeDescription];
            UIImage *entryIconImage = entryDetail[XXTExplorerViewEntryAttributeIconImage];
            if (entryDetail[XXTExplorerViewEntryAttributeEntryReader]) {
                id <XXTExplorerEntryReader> entryReader = entryDetail[XXTExplorerViewEntryAttributeEntryReader];
                if (entryReader.entryDisplayName) {
                    entryDisplayName = entryReader.entryDisplayName;
                }
                if (entryReader.entryDescription) {
                    entryDescription = entryReader.entryDescription;
                }
                if (entryReader.entryIconImage) {
                    entryIconImage = entryReader.entryIconImage;
                }
            }
            self.nameLabel.text = entryDisplayName;
            self.descriptionLabel.text = entryDescription;
            self.iconImageView.image = entryIconImage;
            _xui_value = xui_value;
            return;
        }
    }
}

- (void)resetCellState {
    self.nameLabel.text = NSLocalizedString(@"Tap here to add a file.", nil);
    self.descriptionLabel.text = [self openWithCellDescriptionFromExtensions:self.xui_allowedExtensions];
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

- (BOOL)canEdit {
    return YES;
}

@end
