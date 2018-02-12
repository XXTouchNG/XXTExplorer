//
//  XXTExplorerItemPicker.m
//  XXTExplorer
//
//  Created by Zheng on 09/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTExplorerItemPicker.h"

#import "XXTExplorerDefaults.h"
#import "XXTEAppDefines.h"
#import "XXTEUserInterfaceDefines.h"

#import "XXTExplorerToolbar.h"
#import "XXTESwipeTableCell.h"
#import "XXTExplorerViewCell.h"
#import "XXTExplorerFooterView.h"

@interface XXTExplorerItemPicker () <XXTESwipeTableCellDelegate>

@property (nonatomic, strong) UIBarButtonItem *closeButtonItem;

@end

@implementation XXTExplorerItemPicker {
    
}

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.title.length == 0) {
        if (self == self.navigationController.viewControllers[0]) {
            
        } else {
            NSString *entryPath = self.entryPath;
            if (entryPath) {
                NSString *entryName = [entryPath lastPathComponent];
                self.title = entryName;
            }
        }
    }
    
    self.navigationItem.rightBarButtonItem = nil;
    if ([self.navigationController.viewControllers firstObject] == self) {
        self.navigationItem.leftBarButtonItem = self.closeButtonItem;
    }
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }
    
    [self.toolbar updateStatus:XXTExplorerToolbarStatusReadonly];
    [self.footerView setEmptyMode:NO];
}

- (BOOL)showsHomeSeries {
    return NO;
}

- (BOOL)shouldDisplayEntry:(NSDictionary *)entryAttributes {
    NSString *entryMaskType = entryAttributes[XXTExplorerViewEntryAttributeMaskType];
    NSString *entryBaseExtension = [entryAttributes[XXTExplorerViewEntryAttributeExtension] lowercaseString];
    if ([entryMaskType isEqualToString:XXTExplorerViewEntryAttributeMaskTypeBundle] ||
        [entryMaskType isEqualToString:XXTExplorerViewEntryAttributeTypeRegular]) {
        if ([self.allowedExtensions containsObject:entryBaseExtension] == NO) {
            return NO;
        }
    }
    return YES;
}

#pragma mark - UITableViewDelegate & UITableViewDataSource

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (tableView == self.tableView) {
        if (XXTExplorerViewSectionIndexList == indexPath.section)
        {
            NSDictionary *entryAttributes = self.entryList[indexPath.row];
            NSString *entryMaskType = entryAttributes[XXTExplorerViewEntryAttributeMaskType];
            NSString *entryName = entryAttributes[XXTExplorerViewEntryAttributeName];
            NSString *entryPath = entryAttributes[XXTExplorerViewEntryAttributePath];
            if ([entryMaskType isEqualToString:XXTExplorerViewEntryAttributeTypeDirectory])
            { // Directory or Symbolic Link Directory
                // We'd better try to access it before we enter it.
                NSError *accessError = nil;
                [self.class.explorerFileManager contentsOfDirectoryAtPath:entryPath error:&accessError];
                if (accessError) {
                    toastMessage(self, [accessError localizedDescription]);
                }
                else {
                    XXTExplorerItemPicker *explorerViewController = [[XXTExplorerItemPicker alloc] initWithEntryPath:entryPath];
                    explorerViewController.delegate = self.delegate;
                    explorerViewController.allowedExtensions = self.allowedExtensions;
                    explorerViewController.selectedBootScriptPath = self.selectedBootScriptPath;
                    [self.navigationController pushViewController:explorerViewController animated:YES];
                }
            }
            else if (
                     [entryMaskType isEqualToString:XXTExplorerViewEntryAttributeMaskTypeBundle] ||
                     [entryMaskType isEqualToString:XXTExplorerViewEntryAttributeTypeRegular]
                     )
            { // Bundle or Regular
                NSString *entryBaseExtension = [entryAttributes[XXTExplorerViewEntryAttributeExtension] lowercaseString];
                BOOL extensionPermitted = NO;
                for (NSString *obj in self.allowedExtensions) {
                    if ([entryBaseExtension isEqualToString:obj]) {
                        extensionPermitted = YES;
                        break;
                    }
                }
                if (extensionPermitted) {
                    NSString *selectedPath = entryAttributes[XXTExplorerViewEntryAttributePath];
                    if (_delegate && [_delegate respondsToSelector:@selector(itemPicker:didSelectItemAtPath:)]) {
                        [_delegate itemPicker:self didSelectItemAtPath:selectedPath];
                    }
                } else {
                    toastMessage(self, ([NSString stringWithFormat:NSLocalizedString(@"Allowed file extensions: %@.", nil), self.allowedExtensions]));
                }
            }
            else if ([entryMaskType isEqualToString:XXTExplorerViewEntryAttributeMaskTypeBrokenSymlink])
            {
                toastMessage(self, ([NSString stringWithFormat:NSLocalizedString(@"The alias \"%@\" can't be opened because the original item can't be found.", nil), entryName]));
            }
            else
            {
                toastMessage(self, NSLocalizedString(@"Only regular file, directory and symbolic link are supported.", nil));
            }
        }
        else if (XXTExplorerViewSectionIndexHome == indexPath.section)
        {
            // impossible
        }
    }
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    // nothing to do
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
        if (indexPath.section == XXTExplorerViewSectionIndexList) {
            XXTExplorerViewCell *cell = (XXTExplorerViewCell *)[super tableView:tableView cellForRowAtIndexPath:indexPath];
            NSDictionary *entryAttributes = self.entryList[indexPath.row];
            NSString *entryPath = entryAttributes[XXTExplorerViewEntryAttributePath];
            if ([entryPath isEqualToString:self.selectedBootScriptPath]) {
                cell.entryTitleLabel.textColor = XXTE_COLOR;
                cell.entrySubtitleLabel.textColor = XXTE_COLOR;
                cell.flagType = XXTExplorerViewCellFlagTypeSelectedBootScript;
            }
            else if ([self.selectedBootScriptPath hasPrefix:entryPath]) {
                cell.entryTitleLabel.textColor = XXTE_COLOR;
                cell.entrySubtitleLabel.textColor = XXTE_COLOR;
                cell.flagType = XXTExplorerViewCellFlagTypeSelectedBootScriptInside;
            }
            else {
                cell.entryTitleLabel.textColor = [UIColor blackColor];
                cell.entrySubtitleLabel.textColor = [UIColor darkGrayColor];
                cell.flagType = XXTExplorerViewCellFlagTypeNone;
            }
            cell.accessoryType = UITableViewCellAccessoryNone;
            return cell;
        }
    }
    return [UITableViewCell new];
}

- (void)setSelectedBootScriptPath:(NSString *)selectedBootScriptPath {
    _selectedBootScriptPath = selectedBootScriptPath;
    if ([self isViewLoaded]) {
        [self.tableView reloadData];
    }
}

#pragma mark - Prevent editing methods

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    return NO;
}

- (BOOL)swipeTableCell:(XXTESwipeTableCell *) cell canSwipe:(XXTESwipeDirection) direction fromPoint:(CGPoint) point {
    return NO;
}

#pragma mark - UIViewController (UIViewControllerEditing)

- (BOOL)isEditing {
    return NO;
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    // nothing to do
}

#pragma mark - UIView Getters

- (UIBarButtonItem *)closeButtonItem {
    if (!_closeButtonItem) {
        UIBarButtonItem *closeButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(closeButtonItemTapped:)];
        _closeButtonItem = closeButtonItem;
    }
    return _closeButtonItem;
}

#pragma mark - UIControl Actions

- (void)closeButtonItemTapped:(UIBarButtonItem *)sender {
    if (_delegate && [_delegate respondsToSelector:@selector(itemPickerDidCancelSelectingItem:)]) {
        [_delegate itemPickerDidCancelSelectingItem:self];
    }
}

#pragma mark - Item Picker Inherit

- (void)reloadFooterView {
    [self updateFooterView];
}

- (void)refreshEntryListView:(UIRefreshControl *)refreshControl {
    [refreshControl endRefreshing];
}

- (XXTExplorerViewEntryListSortField)explorerSortField {
    return XXTEDefaultsEnum(XXTExplorerViewItemPickerSortFieldKey, XXTExplorerViewEntryListSortFieldDisplayName);
}

- (XXTExplorerViewEntryListSortOrder)explorerSortOrder {
    return XXTEDefaultsEnum(XXTExplorerViewItemPickerSortOrderKey, XXTExplorerViewEntryListSortOrderAsc);
}

- (void)setExplorerSortField:(XXTExplorerViewEntryListSortField)explorerSortField {
    XXTEDefaultsSetBasic(XXTExplorerViewItemPickerSortFieldKey, explorerSortField);
}

- (void)setExplorerSortOrder:(XXTExplorerViewEntryListSortOrder)explorerSortOrder {
    XXTEDefaultsSetBasic(XXTExplorerViewItemPickerSortOrderKey, explorerSortOrder);
}

@end
