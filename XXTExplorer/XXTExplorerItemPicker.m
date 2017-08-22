//
//  XXTExplorerItemPicker.m
//  XXTExplorer
//
//  Created by Zheng on 09/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTExplorerItemPicker.h"
#import "XXTESwipeTableCell.h"
#import "XXTExplorerToolbar.h"
#import "XXTExplorerDefaults.h"
#import "UIView+XXTEToast.h"
#import "XXTEUserInterfaceDefines.h"
#import "XXTExplorerViewCell.h"

@interface XXTExplorerItemPicker () <XXTESwipeTableCellDelegate>

@property (nonatomic, strong) UIBarButtonItem *closeButtonItem;

@end

@implementation XXTExplorerItemPicker {
    
}

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItem = nil;
    if (self == self.navigationController.viewControllers[0]) {
        self.navigationItem.leftBarButtonItem = self.closeButtonItem;
    }
    
    [self.toolbar updateStatus:XXTExplorerToolbarStatusReadonly];
}

- (BOOL)showsHomeSeries {
    return NO;
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
                    showUserMessage(self, [accessError localizedDescription]);
                }
                else {
                    XXTExplorerItemPicker *explorerViewController = [[XXTExplorerItemPicker alloc] initWithEntryPath:entryPath];
                    explorerViewController.delegate = self.delegate;
                    explorerViewController.allowedExtensions = self.allowedExtensions;
                    [self.navigationController pushViewController:explorerViewController animated:YES];
                }
            }
            else if (
                     [entryAttributes[XXTExplorerViewEntryAttributeMaskType] isEqualToString:XXTExplorerViewEntryAttributeMaskTypeBundle] ||
                     [entryAttributes[XXTExplorerViewEntryAttributeMaskType] isEqualToString:XXTExplorerViewEntryAttributeTypeRegular]
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
                    if (_delegate && [_delegate respondsToSelector:@selector(itemPicker:didSelectedItemAtPath:)]) {
                        [_delegate itemPicker:self didSelectedItemAtPath:selectedPath];
                    }
                } else {
                    showUserMessage(self, [NSString stringWithFormat:NSLocalizedString(@"Allowed file extensions: %@.", nil), self.allowedExtensions]);
                }
            }
            else if ([entryMaskType isEqualToString:XXTExplorerViewEntryAttributeMaskTypeBrokenSymlink])
            {
                showUserMessage(self, [NSString stringWithFormat:NSLocalizedString(@"The alias \"%@\" can't be opened because the original item can't be found.", nil), entryName]);
            }
            else
            {
                showUserMessage(self, NSLocalizedString(@"Only regular file, directory and symbolic link are supported.", nil));
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
            cell.accessoryType = UITableViewCellAccessoryNone;
            NSDictionary *entryAttributes = self.entryList[indexPath.row];
            NSString *entryPath = entryAttributes[XXTExplorerViewEntryAttributePath];
            if ([entryPath isEqualToString:self.selectedBootScriptPath]) {
                cell.entryTitleLabel.textColor = XXTE_COLOR;
                cell.flagType = XXTExplorerViewCellFlagTypeSelectedBootScript;
            } else {
                cell.entryTitleLabel.textColor = [UIColor blackColor];
                cell.flagType = XXTExplorerViewCellFlagTypeNone;
            }
            return cell;
        }
    }
    return [UITableViewCell new];
}

- (void)setSelectedBootScriptPath:(NSString *)selectedBootScriptPath {
    _selectedBootScriptPath = selectedBootScriptPath;
    [self.tableView reloadData];
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
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
