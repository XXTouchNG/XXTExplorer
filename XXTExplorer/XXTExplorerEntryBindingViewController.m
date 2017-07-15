//
//  XXTExplorerEntryBindingViewController.m
//  XXTExplorer
//
//  Created by Zheng on 15/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTExplorerEntryBindingViewController.h"
#import "XXTEAppDefines.h"
#import "XXTExplorerDefaults.h"
#import "XXTExplorerEntryService.h"
//#import "XXTEMoreTitleDescriptionCell.h"
#import "XXTExplorerViewCell.h"
#import "XXTEViewer.h"
#import "XXTEUserInterfaceDefines.h"
#import "XXTExplorerEntryLauncher.h"
#import "XXTExplorerEntryArchiver.h"
#import "XXTExplorerEntryReader.h"

typedef enum : NSUInteger {
    kXXTEBindingSectionIndexNone = 0,
    kXXTEBindingSectionIndexInternal,
    kXXTEBindingSectionIndexSuggested,
    kXXTEBindingSectionIndexOther,
    kXXTEBindingSectionIndexMax
} kXXTEBindingSectionIndex;

@interface XXTExplorerEntryBindingViewController ()

@property (nonatomic, copy, readonly) NSArray <Class> *suggestedViewers;
@property (nonatomic, copy, readonly) NSArray <Class> *otherViewers;
@property (nonatomic, copy, readonly) NSDictionary *bindingDictionary;
@property (nonatomic, strong) NSIndexPath *selectedIndexPath;

@end

@implementation XXTExplorerEntryBindingViewController {
    NSArray <NSString *> *staticSectionTitles;
    NSArray <NSString *> *staticSectionFooters;
}

#pragma mark - Default Style

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

#pragma mark - Setup

- (instancetype)initWithEntry:(NSDictionary *)entry {
    if (self = [super initWithStyle:UITableViewStylePlain]) {
        _entry = entry;
        [self setup];
    }
    return self;
}

- (void)setup {
    NSString *entryBaseExtension = [self.entry[XXTExplorerViewEntryAttributeExtension] lowercaseString];
    NSDictionary *bindingDictionary = [[XXTExplorerEntryService sharedInstance] bindingDictionary];
    NSString *bindedViewerName = bindingDictionary[entryBaseExtension];
    NSArray <Class> *registeredViewers = [[XXTExplorerEntryService sharedInstance] registeredViewers];
    NSMutableArray <Class> *suggestedViewers = [[NSMutableArray alloc] init];
    NSMutableArray <Class> *otherViewers = [[NSMutableArray alloc] init];
    NSInteger suggestedIndex = 0;
    NSInteger otherIndex = 0;
    NSIndexPath *selectedIndexPath = nil;
    for (Class viewerClass in registeredViewers) {
        Class <XXTEViewer> viewer = viewerClass;
        NSString *viewerName = NSStringFromClass(viewer);
        NSArray <NSString *> *suggestedExtensions = [viewer suggestedExtensions];
        BOOL suggest = NO;
        for (NSString *suggestedExtension in suggestedExtensions) {
            if ([suggestedExtension isEqualToString:entryBaseExtension]) {
                suggest = YES;
                break;
            }
        }
        BOOL binded = (bindedViewerName && [bindedViewerName isEqualToString:viewerName]);
        if (suggest) {
            [suggestedViewers addObject:viewer];
            if (binded && !selectedIndexPath) {
                selectedIndexPath = [NSIndexPath indexPathForRow:suggestedIndex inSection:kXXTEBindingSectionIndexSuggested];
            }
            suggestedIndex++;
        } else {
            [otherViewers addObject:viewer];
            if (binded && !selectedIndexPath) {
                selectedIndexPath = [NSIndexPath indexPathForRow:otherIndex inSection:kXXTEBindingSectionIndexOther];
            }
            otherIndex++;
        }
    }
    // Internal Types
    id <XXTExplorerEntryReader> reader = self.entry[XXTExplorerViewEntryAttributeEntryReader];
    if (reader) {
        if ([reader isKindOfClass:[XXTExplorerEntryLauncher class]]) {
            selectedIndexPath = [NSIndexPath indexPathForRow:0 inSection:kXXTEBindingSectionIndexInternal];
        }
        else if ([reader isKindOfClass:[XXTExplorerEntryArchiver class]]) {
            selectedIndexPath = [NSIndexPath indexPathForRow:1 inSection:kXXTEBindingSectionIndexInternal];
        }
    }
    if (selectedIndexPath == nil) {
        _selectedIndexPath = [NSIndexPath indexPathForRow:0 inSection:kXXTEBindingSectionIndexNone];
    } else {
        _selectedIndexPath = selectedIndexPath;
    }
    _suggestedViewers = suggestedViewers;
    _otherViewers = otherViewers;
    _bindingDictionary = bindingDictionary;
}

#pragma mark - View

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.clearsSelectionOnViewWillAppear = self.splitViewController.isCollapsed;
    self.title = NSLocalizedString(@"Open with...", nil);
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    
    XXTE_START_IGNORE_PARTIAL
    if (XXTE_SYSTEM_9) {
        self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    }
    XXTE_END_IGNORE_PARTIAL
    
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([XXTExplorerViewCell class]) bundle:[NSBundle mainBundle]] forCellReuseIdentifier:XXTExplorerViewCellReuseIdentifier];
    
    staticSectionTitles = @[ @"",
                             NSLocalizedString(@"Internal", nil),
                             NSLocalizedString(@"Suggested", nil),
                             NSLocalizedString(@"Other", nil)];
    staticSectionFooters = @[ @"", @"", @"", @"" ];
}

#pragma mark - UITableViewDelegate & UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return kXXTEBindingSectionIndexMax;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        if (section == kXXTEBindingSectionIndexSuggested) {
            return self.suggestedViewers.count;
        } else if (section == kXXTEBindingSectionIndexOther) {
            return self.otherViewers.count;
        } else if (section == kXXTEBindingSectionIndexNone) {
            return 1;
        } else if (section == kXXTEBindingSectionIndexInternal) {
            return 2;
        }
    }
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    return [self tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
        return 66.f;
    }
    return 44.f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (tableView == self.tableView) {
        NSString *entryBaseExtension = [self.entry[XXTExplorerViewEntryAttributeExtension] lowercaseString];
        NSString *bindToViewerName = nil;
        if (self.selectedIndexPath.section == kXXTEBindingSectionIndexInternal ||
            indexPath.section == kXXTEBindingSectionIndexInternal) {
            showUserMessage(self, NSLocalizedString(@"You cannot switch from/to internal viewers by default.", nil));
            return;
        } else if (indexPath.section == kXXTEBindingSectionIndexSuggested) {
            bindToViewerName = NSStringFromClass(self.suggestedViewers[indexPath.row]);
        } else if (indexPath.section == kXXTEBindingSectionIndexOther) {
            bindToViewerName = NSStringFromClass(self.otherViewers[indexPath.row]);
        } else if (indexPath.section == kXXTEBindingSectionIndexNone) {
            bindToViewerName = nil;
        } else {
            return; // nothing will be done if internal
        }
        [[XXTExplorerEntryService sharedInstance] bindExtension:entryBaseExtension toViewer:bindToViewerName];
        self.selectedIndexPath = indexPath;
        if (_delegate && [_delegate respondsToSelector:@selector(bindingViewController:bindingDidChanged:)]) {
            [_delegate bindingViewController:self bindingDidChanged:bindToViewerName];
        }
        [self.tableView reloadData];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        return staticSectionTitles[(NSUInteger) section];
    }
    return @"";
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        return staticSectionFooters[(NSUInteger) section];
    }
    return @"";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
        XXTExplorerViewCell *cell = [tableView dequeueReusableCellWithIdentifier:XXTExplorerViewCellReuseIdentifier];
        Class <XXTEViewer> viewerClass = nil;
        if (indexPath.section == kXXTEBindingSectionIndexSuggested) {
            viewerClass = self.suggestedViewers[indexPath.row];
        } else if (indexPath.section == kXXTEBindingSectionIndexOther) {
            viewerClass = self.otherViewers[indexPath.row];
        } else {
            viewerClass = nil;
        }
        if (viewerClass) {
            cell.entryTitleLabel.text = [viewerClass viewerName];
            cell.entrySubtitleLabel.text = [self openWithCellDescriptionFromExtensions:[viewerClass suggestedExtensions]];
            Class <XXTExplorerEntryReader> readerClass = [viewerClass relatedReader];
            cell.entryIconImageView.image = [readerClass defaultImage];
        } else {
            if (indexPath.section == kXXTEBindingSectionIndexNone) {
                cell.entryTitleLabel.text = NSLocalizedString(@"None", nil);
                cell.entrySubtitleLabel.text = NSLocalizedString(@"Restore to default.", nil);
                cell.entryIconImageView.image = [UIImage imageNamed:XXTExplorerViewEntryAttributeTypeRegular];
            }
            else if (indexPath.section == kXXTEBindingSectionIndexInternal) {
                if (indexPath.row == 0) {
                    cell.entryTitleLabel.text = NSLocalizedString(@"Launcher", nil);
                    cell.entrySubtitleLabel.text = [self openWithCellDescriptionFromExtensions:[XXTExplorerEntryLauncher supportedExtensions]];
                    cell.entryIconImageView.image = [XXTExplorerEntryLauncher defaultImage];
                } else if (indexPath.row == 1) {
                    cell.entryTitleLabel.text = NSLocalizedString(@"Archiver", nil);
                    cell.entrySubtitleLabel.text = [self openWithCellDescriptionFromExtensions:[XXTExplorerEntryArchiver supportedExtensions]];
                    cell.entryIconImageView.image = [XXTExplorerEntryArchiver defaultImage];
                }
            }
        }
        if ([indexPath isEqual:self.selectedIndexPath]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        return cell;
    }
    return [UITableViewCell new];
}

- (NSString *)openWithCellDescriptionFromExtensions:(NSArray <NSString *> *)extensions {
    NSMutableString *mutableDescription = [@"" mutableCopy];
    [extensions enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (idx < extensions.count - 1) {
            [mutableDescription appendFormat:@"%@, ", obj];
        } else {
            [mutableDescription appendFormat:@"%@. ", obj];
        }
    }];
    return [[NSString alloc] initWithString:mutableDescription];
}

@end
