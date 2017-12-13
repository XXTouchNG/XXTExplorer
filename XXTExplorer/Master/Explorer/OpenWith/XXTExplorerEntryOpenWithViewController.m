//
//  XXTExplorerEntryOpenWithViewController.m
//  XXTExplorer
//
//  Created by Zheng on 2017/8/6.
//  Copyright © 2017年 Zheng. All rights reserved.
//

#import "XXTExplorerEntryOpenWithViewController.h"
#import "XXTEAppDefines.h"
#import "XXTExplorerDefaults.h"
#import "XXTExplorerEntryService.h"
#import "XXTExplorerViewCell.h"
#import "XXTEViewer.h"
#import "XXTEUserInterfaceDefines.h"
#import "XXTExplorerEntryReader.h"

typedef enum : NSUInteger {
    kXXTEOpenWithSectionIndexSuggested = 0,
    kXXTEOpenWithSectionIndexOther,
    kXXTEOpenWithSectionIndexMax
} kXXTEOpenWithSectionIndex;

@interface XXTExplorerEntryOpenWithViewController ()

@property (nonatomic, copy, readonly) NSArray <Class> *suggestedViewers;
@property (nonatomic, copy, readonly) NSArray <Class> *otherViewers;
@property (nonatomic, strong) UIBarButtonItem *closeButtonItem;

@end

@implementation XXTExplorerEntryOpenWithViewController {
    NSArray <NSString *> *staticSectionTitles;
    NSArray <NSString *> *staticSectionFooters;
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
    NSArray <Class> *registeredViewers = [[XXTExplorerEntryService sharedInstance] registeredViewers];
    NSMutableArray <Class> *suggestedViewers = [[NSMutableArray alloc] init];
    NSMutableArray <Class> *otherViewers = [[NSMutableArray alloc] init];
    NSInteger suggestedIndex = 0;
    NSInteger otherIndex = 0;
    for (Class viewerClass in registeredViewers) {
        Class <XXTEViewer> viewer = viewerClass;
        NSArray <NSString *> *suggestedExtensions = [viewer suggestedExtensions];
        BOOL suggest = NO;
        for (NSString *suggestedExtension in suggestedExtensions) {
            if ([suggestedExtension isEqualToString:entryBaseExtension]) {
                suggest = YES;
                break;
            }
        }
        if (suggest) {
            [suggestedViewers addObject:viewer];
            suggestedIndex++;
        } else {
            [otherViewers addObject:viewer];
            otherIndex++;
        }
    }
    _suggestedViewers = suggestedViewers;
    _otherViewers = otherViewers;
}

#pragma mark - View

- (void)viewDidLoad {
    [super viewDidLoad];
    
    XXTE_START_IGNORE_PARTIAL
    if (@available(iOS 8.0, *)) {
        self.clearsSelectionOnViewWillAppear = self.splitViewController.isCollapsed;
    }
    XXTE_END_IGNORE_PARTIAL
    
    self.title = NSLocalizedString(@"Open with...", nil);
    
    if ([self.navigationController.viewControllers firstObject] == self) {
        self.navigationItem.leftBarButtonItem = self.closeButtonItem;
    }
    
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
    
    staticSectionTitles = @[ NSLocalizedString(@"Suggested", nil),
                             NSLocalizedString(@"Other", nil)];
    staticSectionFooters = @[ @"", @"" ];
}

#pragma mark - UIView Getters

- (UIBarButtonItem *)closeButtonItem {
    if (!_closeButtonItem) {
        UIBarButtonItem *closeButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(closeButtonItemTapped:)];
        closeButtonItem.tintColor = [UIColor whiteColor];
        _closeButtonItem = closeButtonItem;
    }
    return _closeButtonItem;
}

#pragma mark - UITableViewDelegate & UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return kXXTEOpenWithSectionIndexMax;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        if (section == kXXTEOpenWithSectionIndexSuggested)
            return self.suggestedViewers.count;
        else if (section == kXXTEOpenWithSectionIndexOther)
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
        NSString *openWithViewerName = nil;
        if (indexPath.section == kXXTEOpenWithSectionIndexSuggested) {
            openWithViewerName = NSStringFromClass(self.suggestedViewers[indexPath.row]);
        } else if (indexPath.section == kXXTEOpenWithSectionIndexOther) {
            openWithViewerName = NSStringFromClass(self.otherViewers[indexPath.row]);
        } else {
            return; // nothing will be done if internal
        }
        {
            if (_delegate && [_delegate respondsToSelector:@selector(openWithViewController:viewerDidSelected:)]) {
                [_delegate openWithViewController:self viewerDidSelected:openWithViewerName];
            }
        }
    }
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    header.textLabel.font = [UIFont systemFontOfSize:14.0];
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(nonnull UIView *)view forSection:(NSInteger)section {
    if (tableView.style == UITableViewStylePlain) {
        UITableViewHeaderFooterView *footer = (UITableViewHeaderFooterView *)view;
        footer.textLabel.font = [UIFont systemFontOfSize:12.0];
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
        if (indexPath.section == kXXTEOpenWithSectionIndexSuggested) {
            viewerClass = self.suggestedViewers[indexPath.row];
        } else if (indexPath.section == kXXTEOpenWithSectionIndexOther) {
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
        }
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
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

#pragma mark - UIControl Actions

- (void)closeButtonItemTapped:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
