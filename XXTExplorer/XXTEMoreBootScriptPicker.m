//
//  XXTEMoreBootScriptPicker.m
//  XXTExplorer
//
//  Created by Zheng on 09/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEMoreBootScriptPicker.h"
#import "XXTESwipeTableCell.h"
#import "XXTExplorerToolbar.h"
#import "XXTExplorerDefaults.h"
#import "UIView+XXTEToast.h"
#import "XXTEUserInterfaceDefines.h"

typedef enum : NSUInteger {
    XXTExplorerViewSectionIndexHome = 0,
    XXTExplorerViewSectionIndexList,
    XXTExplorerViewSectionIndexMax
} XXTExplorerViewSectionIndex;

@interface XXTEMoreBootScriptPicker () <XXTESwipeTableCellDelegate>

@end

@implementation XXTEMoreBootScriptPicker {
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItem = nil;
    
    UIView *toolbarOverlayView = [[UIView alloc] initWithFrame:self.toolbar.bounds];
    toolbarOverlayView.backgroundColor = [UIColor whiteColor];
    toolbarOverlayView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    toolbarOverlayView.alpha = 0.65f;
    toolbarOverlayView.userInteractionEnabled = NO;
    [self.toolbar addSubview:toolbarOverlayView];
}

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
                    showUserMessage(self.navigationController.view, [accessError localizedDescription]);
                }
                else {
                    XXTEMoreBootScriptPicker *explorerViewController = [[XXTEMoreBootScriptPicker alloc] initWithEntryPath:entryPath];
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
                    if (_delegate && [_delegate respondsToSelector:@selector(bootScriptPicker:didSelectedBootScriptPath:)]) {
                        [_delegate bootScriptPicker:self didSelectedBootScriptPath:selectedPath];
                    }
                } else {
                    showUserMessage(self.navigationController.view, [NSString stringWithFormat:NSLocalizedString(@"Allowed file extensions: %@.", nil), self.allowedExtensions]);
                }
            }
            else if ([entryMaskType isEqualToString:XXTExplorerViewEntryAttributeMaskTypeBrokenSymlink])
            {
                showUserMessage(self.navigationController.view, [NSString stringWithFormat:NSLocalizedString(@"The alias \"%@\" can't be opened because the original item can't be found.", nil), entryName]);
            }
            else
            {
                showUserMessage(self.navigationController.view, NSLocalizedString(@"Only regular file, directory and symbolic link are supported.", nil));
            }
        }
        else if (XXTExplorerViewSectionIndexHome == indexPath.section)
        {
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            if ([tableView isEditing]) {
                
            } else {
                NSDictionary *entryAttributes = self.homeEntryList[indexPath.row];
                NSString *directoryRelativePath = entryAttributes[XXTExplorerViewSectionHomeSeriesDetailPathKey];
                NSString *directoryPath = [[[self class] rootPath] stringByAppendingPathComponent:directoryRelativePath];
                NSError *accessError = nil;
                [self.class.explorerFileManager contentsOfDirectoryAtPath:directoryPath error:&accessError];
                if (accessError) {
                    showUserMessage(self.navigationController.view, [accessError localizedDescription]);
                }
                else {
                    XXTEMoreBootScriptPicker *explorerViewController = [[XXTEMoreBootScriptPicker alloc] initWithEntryPath:directoryPath];
                    explorerViewController.delegate = self.delegate;
                    explorerViewController.allowedExtensions = self.allowedExtensions;
                    [self.navigationController pushViewController:explorerViewController animated:YES];
                }
            }
        }
    }
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    // nothing to do
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryNone;
    return cell;
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

@end
