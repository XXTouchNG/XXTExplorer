//
//  XXTEMoreApplicationCell.m
//  XXTPickerCollection
//
//  Created by Zheng on 03/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEMoreApplicationCell.h"

@interface XXTEMoreApplicationCell ()
@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UILabel *applicationNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *applicationBundleIDLabel;
@end

@implementation XXTEMoreApplicationCell {
    NSString *_applicationName;
    NSString *_applicationBundleID;
    NSString *_searchText;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.applicationNameLabel.textColor = XXTColorPlainTitleText();
    self.applicationBundleIDLabel.textColor = XXTColorForeground();
    self.backgroundColor = XXTColorPlainBackground();
    self.tintColor = XXTColorForeground();
    
    UIView *selectionBackground = [[UIView alloc] init];
    selectionBackground.backgroundColor = XXTColorCellSelected();
    self.selectedBackgroundView = selectionBackground;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setApplicationName:(NSString *)name {
    _applicationName = name;
    [self updateLabels];
}

- (void)setApplicationBundleID:(NSString *)bundleID {
    _applicationBundleID = bundleID;
    [self updateLabels];
}

- (void)setSearchText:(NSString *)searchText {
    _searchText = searchText;
    [self updateLabels];
}

- (void)setApplicationIconImage:(UIImage *)image {
    self.iconImageView.image = image;
}

- (NSString *)applicationName {
    return _applicationName;
}

- (NSString *)applicationBundleID {
    return _applicationBundleID;
}

- (void)updateLabels {
    if (!_searchText.length) {
        self.applicationNameLabel.text = _applicationName;
        self.applicationBundleIDLabel.text = _applicationBundleID;
    } else {
        if (_applicationName.length) {
            NSMutableAttributedString *attrApplicationName = [[NSMutableAttributedString alloc] initWithString:_applicationName attributes:@{NSForegroundColorAttributeName: XXTColorPlainTitleText(), NSFontAttributeName: [UIFont systemFontOfSize:16.0]}];
            NSRange highlightRange = [_applicationName rangeOfString:_searchText options:NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch];
            if (highlightRange.location != NSNotFound) {
                [attrApplicationName addAttributes:@{NSBackgroundColorAttributeName: XXTColorSearchHighlight()} range:highlightRange];
            }
            self.applicationNameLabel.attributedText = attrApplicationName;
        } else {
            self.applicationNameLabel.attributedText = nil;
        }
        if (_applicationBundleID.length) {
            NSMutableAttributedString *attrApplicationBundleID = [[NSMutableAttributedString alloc] initWithString:_applicationBundleID attributes:@{NSForegroundColorAttributeName: XXTColorForeground(), NSFontAttributeName: [UIFont systemFontOfSize:12.0]}];
            NSRange highlightRange = [_applicationBundleID rangeOfString:_searchText options:NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch];
            if (highlightRange.location != NSNotFound) {
                [attrApplicationBundleID addAttributes:@{NSBackgroundColorAttributeName: XXTColorSearchHighlight()} range:highlightRange];
            }
            self.applicationBundleIDLabel.attributedText = attrApplicationBundleID;
        } else {
            self.applicationBundleIDLabel.attributedText = nil;
        }
    }
}

@end
