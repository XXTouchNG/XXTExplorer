//
//  XXTExplorerItemPicker.m
//  XXTExplorer
//
//  Created by Zheng on 09/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTExplorerItemPicker.h"
#import "XXTExplorerSearchResultsViewController.h"
#import "XXTExplorerDefaults.h"

#import "XXTExplorerToolbar.h"
#import "XXTESwipeTableCell.h"
#import "XXTExplorerViewCell.h"
#import "XXTExplorerFooterView.h"

@interface XXTExplorerItemPicker () <XXTESwipeTableCellDelegate>

@property (nonatomic, strong) UIBarButtonItem *closeButtonItem;
@property (nonatomic, strong) UIBarButtonItem *selectButtonItem;

@end

@implementation XXTExplorerItemPicker {
    
}

#pragma mark - Life Cycle

- (instancetype)initWithEntryPath:(NSString *)path {
    self = [super initWithEntryPath:path];
    if (self) {
        _isFile = YES;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.title.length == 0) {
        if (self == [self.navigationController.viewControllers firstObject] && !self.isPreviewed) {
            
        } else {
            NSString *entryPath = self.entryPath;
            if (entryPath) {
                NSString *entryName = [entryPath lastPathComponent];
                self.title = entryName;
            }
        }
    }
    
    NSMutableArray <UIBarButtonItem *> *rightItems = [NSMutableArray array];
    if (!self.isFile) {
        [rightItems addObject:self.selectButtonItem];
    }
    if (!self.isPreviewed)
    {
        [rightItems addObject:self.closeButtonItem];
    }
    [self.navigationItem setRightBarButtonItems:rightItems];
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }
    
    [self.toolbar updateStatus:XXTExplorerToolbarStatusReadonly];
    [self.footerView setEmptyMode:NO];
}

#pragma mark - Getters

- (BOOL)showsHomeSeries {
    return NO;
}

- (BOOL)allowsPreviewing {
    return NO;
}

- (BOOL)allowDragAndDrop {
    return NO;
}

- (BOOL)shouldDisplayEntry:(XXTExplorerEntry *)entryDetail {
    NSString *entryBaseExtension = entryDetail.entryExtension;
    if (entryDetail.isBundle ||
        entryDetail.isMaskedRegular) {
        if ([self.allowedExtensions containsObject:entryBaseExtension] == NO) {
            return NO;
        }
    }
    return YES;
}

#pragma mark - Actions

- (void)performPickerActionWithEntry:(XXTExplorerEntry *)entryDetail
{
    NSString *entryPath = entryDetail.entryPath;
    if (entryDetail.isMaskedDirectory)
    { // Directory or Symbolic Link Directory
        // We'd better try to access it before we enter it.
        NSError *accessError = nil;
        [self.class.explorerFileManager contentsOfDirectoryAtPath:entryPath error:&accessError];
        if (accessError) {
            toastError(self, accessError);
        }
        else {
            XXTExplorerItemPicker *explorerViewController = [[XXTExplorerItemPicker alloc] initWithEntryPath:entryPath];
            explorerViewController.delegate = self.delegate;
            explorerViewController.allowedExtensions = self.allowedExtensions;
            explorerViewController.selectedBootScriptPath = self.selectedBootScriptPath;
            explorerViewController.isFile = self.isFile;
            [self.navigationController pushViewController:explorerViewController animated:YES];
        }
    }
    else if (
             entryDetail.isBundle ||
             entryDetail.isMaskedRegular
             )
    { // Bundle or Regular
        if (self.isFile) {
            NSString *entryBaseExtension = entryDetail.entryExtension;
            BOOL extensionPermitted = NO;
            for (NSString *obj in self.allowedExtensions) {
                if ([entryBaseExtension isEqualToString:obj]) {
                    extensionPermitted = YES;
                    break;
                }
            }
            if (extensionPermitted) {
                NSString *selectedPath = entryDetail.entryPath;
                if (_delegate && [_delegate respondsToSelector:@selector(itemPicker:didSelectItemAtPath:)]) {
                    [_delegate itemPicker:self didSelectItemAtPath:selectedPath];
                }
            } else {
                toastMessage(self, ([NSString stringWithFormat:NSLocalizedString(@"Allowed file extensions: %@.", nil), self.allowedExtensions]));
            }
        } else {
            toastMessage(self, NSLocalizedString(@"Please select a directory.", nil));
        }
    }
    else if (entryDetail.isBrokenSymlink)
    {
        toastMessage(self, ([NSString stringWithFormat:NSLocalizedString(@"The alias \"%@\" can't be opened because the original item can't be found.", nil), entryDetail.localizedDisplayName]));
    }
    else
    {
        toastMessage(self, NSLocalizedString(@"Only regular file, directory and symbolic link are supported.", nil));
    }
}

#pragma mark - UITableViewDelegate & UITableViewDataSource

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (tableView == self.tableView) {
        if (XXTExplorerViewSectionIndexList == indexPath.section)
        {
            XXTExplorerEntry *entryDetail = self.entryList[indexPath.row];
            [self performPickerActionWithEntry:entryDetail];
        }
        else if (XXTExplorerViewSectionIndexHome == indexPath.section)
        {
            // impossible
        }
    } else if (tableView == self.searchResultsController.tableView) {
        if (indexPath.section == 0) {
            XXTExplorerEntry *entryDetail = self.searchResultsController.filteredEntryList[indexPath.row];
            [self.searchController setActive:NO];
            UIViewController *blockVC = blockInteractions(self, YES);
            @weakify(self);
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                @strongify(self);
                blockInteractions(blockVC, NO);
                [self performPickerActionWithEntry:entryDetail];
            });
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
            return cell;
        }
    }
    return [UITableViewCell new];
}

- (void)configureCell:(XXTExplorerViewCell *)entryCell fromTableView:(UITableView *)tableView withEntry:(XXTExplorerEntry *)entry {
    [super configureCell:entryCell fromTableView:tableView withEntry:entry];
    
    UIColor *titleColor = nil;
    UIColor *subtitleColor = nil;
    XXTExplorerViewCellFlagType flagType = XXTExplorerViewCellFlagTypeNone;
    BOOL needsOverride = NO;
    
    if (!entry.isMaskedDirectory &&
        [entry.entryPath isEqualToString:self.selectedBootScriptPath]) {
        titleColor = XXTColorForeground();
        subtitleColor = XXTColorForeground();
        flagType = XXTExplorerViewCellFlagTypeSelectedBootScript;
        needsOverride = YES;
    }
    else if ((entry.isMaskedDirectory ||
              entry.isBundle) &&
             [self.selectedBootScriptPath hasPrefix:entry.entryPath] &&
             [[self.selectedBootScriptPath substringFromIndex:entry.entryPath.length] rangeOfString:@"/"].location != NSNotFound) {
        titleColor = XXTColorForeground();
        subtitleColor = XXTColorForeground();
        flagType = XXTExplorerViewCellFlagTypeSelectedBootScriptInside;
        needsOverride = YES;
    }
    
    if (needsOverride) {
        entryCell.entryTitleLabel.textColor = titleColor;
        entryCell.entrySubtitleLabel.textColor = subtitleColor;
        entryCell.flagType = flagType;
    }
    
    entryCell.accessoryType = UITableViewCellAccessoryNone;
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

- (UIBarButtonItem *)selectButtonItem {
    if (!_selectButtonItem) {
        _selectButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Select", nil) style:UIBarButtonItemStylePlain target:self action:@selector(selectButtonItemTapped:)];
    }
    return _selectButtonItem;
}

#pragma mark - UIControl Actions

- (void)closeButtonItemTapped:(UIBarButtonItem *)sender {
    if (_delegate && [_delegate respondsToSelector:@selector(itemPickerDidCancelSelectingItem:)]) {
        [_delegate itemPickerDidCancelSelectingItem:self];
    }
}

- (void)selectButtonItemTapped:(UIBarButtonItem *)sender {
    if ([_delegate respondsToSelector:@selector(itemPicker:didSelectItemAtPath:)]) {
        [_delegate itemPicker:self didSelectItemAtPath:self.entryPath];
    }
}

#pragma mark - Item Picker Inherit

- (void)reloadFooterView {
    [self updateFooterView];
}

- (void)refreshControlTriggered:(UIRefreshControl *)refreshControl {
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
