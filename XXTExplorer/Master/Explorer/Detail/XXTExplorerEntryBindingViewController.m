//
//  XXTExplorerEntryBindingViewController.m
//  XXTExplorer
//
//  Created by Zheng on 15/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTExplorerEntryBindingViewController.h"
#import "XXTExplorerDefaults.h"
#import "XXTExplorerEntryService.h"
#import "XXTExplorerViewCell.h"
#import "XXTExplorerHeaderView.h"
#import "XXTEViewer.h"
#import "XXTExplorerEntryReader.h"

typedef enum : NSUInteger {
    kXXTEBindingSectionIndexNone = 0,
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

#pragma mark - Setup

- (instancetype)initWithEntry:(XXTExplorerEntry *)entry {
    if (self = [super initWithStyle:UITableViewStylePlain]) {
        _entry = entry;
        [self setup];
    }
    return self;
}

- (void)setup {
    NSString *entryBaseExtension = self.entry.entryExtension;
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
    if (selectedIndexPath == nil)
        _selectedIndexPath = [NSIndexPath indexPathForRow:0 inSection:kXXTEBindingSectionIndexNone];
    else
        _selectedIndexPath = selectedIndexPath;
    _suggestedViewers = suggestedViewers;
    _otherViewers = otherViewers;
    _bindingDictionary = bindingDictionary;
}

#pragma mark - View

- (void)viewDidLoad {
    [super viewDidLoad];
    if (self.tableView.style == UITableViewStylePlain) {
        self.view.backgroundColor = XXTColorPlainBackground();
    } else {
        self.view.backgroundColor = XXTColorGroupedBackground();
    }
    
    XXTE_START_IGNORE_PARTIAL
    if (@available(iOS 8.0, *)) {
        self.clearsSelectionOnViewWillAppear = self.splitViewController.isCollapsed;
    }
    XXTE_END_IGNORE_PARTIAL
    
    self.title = NSLocalizedString(@"Open with...", nil);
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    
    XXTE_START_IGNORE_PARTIAL
    if (@available(iOS 9.0, *)) {
        self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    }
    XXTE_END_IGNORE_PARTIAL
    
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([XXTExplorerViewCell class]) bundle:[NSBundle mainBundle]] forCellReuseIdentifier:XXTExplorerViewCellReuseIdentifier];
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }
    
    staticSectionTitles = @[ @"",
                             NSLocalizedString(@"Suggested", nil),
                             NSLocalizedString(@"Other", nil)];
    staticSectionFooters = @[ @"", @"", @"" ];
}

#pragma mark - UITableViewDelegate & UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return kXXTEBindingSectionIndexMax;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        if (section == kXXTEBindingSectionIndexNone)
            return 1;
        else if (section == kXXTEBindingSectionIndexSuggested)
            return self.suggestedViewers.count;
        else if (section == kXXTEBindingSectionIndexOther)
            return self.otherViewers.count;
    }
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    return [self tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
        return XXTExplorerViewCellHeight;
    }
    return 44.f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (tableView == self.tableView) {
        NSString *entryBaseExtension = self.entry.entryExtension;
        NSString *bindToViewerName = nil;
        if (indexPath.section == kXXTEBindingSectionIndexSuggested) {
            bindToViewerName = NSStringFromClass(self.suggestedViewers[indexPath.row]);
        } else if (indexPath.section == kXXTEBindingSectionIndexOther) {
            bindToViewerName = NSStringFromClass(self.otherViewers[indexPath.row]);
        } else if (indexPath.section == kXXTEBindingSectionIndexNone) {
            bindToViewerName = nil;
        } else {
            return; // nothing will be done if internal
        }
        {
            [[XXTExplorerEntryService sharedInstance] bindExtension:entryBaseExtension toViewer:bindToViewerName];
            self.selectedIndexPath = indexPath;
            for (UITableViewCell *cell in tableView.visibleCells) {
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
            UITableViewCell *selectCell = [tableView cellForRowAtIndexPath:indexPath];
            selectCell.accessoryType = UITableViewCellAccessoryCheckmark;
            if (_delegate && [_delegate respondsToSelector:@selector(bindingViewController:bindingDidChanged:)]) {
                [_delegate bindingViewController:self bindingDidChanged:bindToViewerName];
            }
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        if (section == 0) {
            return 0;
        }
        return 24.f;
    }
    return 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        NSString *title = staticSectionTitles[(NSUInteger) section];
        XXTExplorerHeaderView *entryHeaderView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:XXTExplorerEntryHeaderViewReuseIdentifier];
        if (!entryHeaderView)
        {
            entryHeaderView = [[XXTExplorerHeaderView alloc] initWithReuseIdentifier:XXTExplorerEntryHeaderViewReuseIdentifier];
        }
        [entryHeaderView.headerLabel setText:title];
        return entryHeaderView;
    }
    return nil;
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
        if ([viewerClass respondsToSelector:@selector(viewerName)]) {
            cell.entryTitleLabel.text = [viewerClass viewerName];
            cell.entrySubtitleLabel.text = [self openWithCellDescriptionFromExtensions:[viewerClass suggestedExtensions]];
            if ([viewerClass respondsToSelector:@selector(relatedReader)]) {
                Class readerClass = [viewerClass relatedReader];
                cell.entryIconImageView.image = [readerClass defaultImage];
            }
        } else {
            if (indexPath.section == kXXTEBindingSectionIndexNone) {
                cell.entryTitleLabel.text = NSLocalizedString(@"None", nil);
                cell.entrySubtitleLabel.text = NSLocalizedString(@"Restore to default.", nil);
                cell.entryIconImageView.image = [UIImage imageNamed:EntryMaskTypeRegular];
            }
        }
        if ([indexPath isEqual:self.selectedIndexPath])
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        else
            cell.accessoryType = UITableViewCellAccessoryNone;
        return cell;
    }
    return [UITableViewCell new];
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
