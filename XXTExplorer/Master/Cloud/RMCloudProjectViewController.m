//
//  RMCloudProjectViewController.m
//  XXTExplorer
//
//  Created by Zheng on 13/01/2018.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import "RMCloudProjectViewController.h"
#import "RMCloudProjectDetailCell.h"
#import "RMCloudProjectDescriptionCell.h"
#import "RMProject.h"
#import "RMCloudLoadingView.h"

#import "XXTEUserInterfaceDefines.h"
#import "RMCloudExpandableCell.h"
#import "RMCloudExpandedCell.h"
#import "RMCloudLinkCell.h"

typedef enum : NSUInteger {
    RMCloudDetailSectionHeader = 0,
    RMCloudDetailSectionDescription,
    RMCloudDetailSectionInformation,
    RMCloudDetailSectionMax
} RMCloudDetailSection;

typedef enum : NSUInteger {
    RMCloudInformationRowAuthor = 0,
    RMCloudInformationRowVersion,
    RMCloudInformationRowDownloadTimes,
    RMCloudInformationRowTrail,
    RMCloudInformationRowContact,
    RMCloudInformationRowBuy,
    RMCloudInformationRowMax
} RMCloudInformationRow;

@interface RMCloudProjectViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) RMProject *project;
@property (nonatomic, strong) RMCloudLoadingView *pawAnimation;

@end

@implementation RMCloudProjectViewController

- (instancetype)initWithProjectID:(NSUInteger)projectID {
    if (self = [super init]) {
        _projectID = projectID;
        [self setup];
    }
    return self;
}

- (void)setup {
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([RMCloudProjectDetailCell class]) bundle:[NSBundle mainBundle]] forCellReuseIdentifier:RMCloudProjectDetailCellReuseIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([RMCloudProjectDescriptionCell class]) bundle:[NSBundle mainBundle]] forCellReuseIdentifier:RMCloudProjectDescriptionCellReuseIdentifier];
    
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([RMCloudExpandableCell class]) bundle:[NSBundle mainBundle]] forCellReuseIdentifier:RMCloudExpandableCellReuseIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([RMCloudExpandedCell class]) bundle:[NSBundle mainBundle]] forCellReuseIdentifier:RMCloudExpandedCellReuseIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([RMCloudLinkCell class]) bundle:[NSBundle mainBundle]] forCellReuseIdentifier:RMCloudLinkCellReuseIdentifier];
    
    [self.view addSubview:self.tableView];
    [self.view addSubview:self.pawAnimation];
    
    [self loadProjectDetail];
}

XXTE_START_IGNORE_PARTIAL
- (void)viewSafeAreaInsetsDidChange {
    [super viewSafeAreaInsetsDidChange];
    if (@available(iOS 11.0, *)) {
        self.tableView.contentInset =
        self.tableView.scrollIndicatorInsets =
        self.view.safeAreaInsets;
    }
}
XXTE_END_IGNORE_PARTIAL

#pragma mark - Request

- (void)loadProjectDetail {
    [RMProject projectWithID:self.projectID]
    .then(^ (RMProject *model) {
        self.project = model;
        [self.tableView reloadData];
    })
    .catch(^ (NSError *error) {
        toastMessage(self, error.localizedDescription);
    })
    .finally(^ () {
        self.pawAnimation.hidden = YES;
    });
}

#pragma mark - UIView Getters

- (UITableView *)tableView {
    if (!_tableView) {
        UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        tableView.delegate = self;
        tableView.dataSource = self;
        XXTE_START_IGNORE_PARTIAL
        if (@available(iOS 9.0, *)) {
            tableView.cellLayoutMarginsFollowReadableWidth = NO;
        }
        if (@available(iOS 11.0, *)) {
            tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        XXTE_END_IGNORE_PARTIAL
        _tableView = tableView;
    }
    return _tableView;
}

- (RMCloudLoadingView *)pawAnimation {
    if (!_pawAnimation) {
        RMCloudLoadingView *pawAnimation = [[RMCloudLoadingView alloc] initWithFrame:CGRectMake(0, 0, 41.0, 45.0)];
        pawAnimation.center = CGPointMake(CGRectGetWidth(self.view.bounds) / 2.0, CGRectGetHeight(self.view.bounds) / 2.0);
        pawAnimation.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        _pawAnimation = pawAnimation;
    }
    return _pawAnimation;
}

#pragma mark - UITableViewDelegate & UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return RMCloudDetailSectionMax;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.project) {
        if (section == RMCloudDetailSectionHeader) {
            return 1;
        } else if (section == RMCloudDetailSectionDescription) {
            return 1;
        } else if (section == RMCloudDetailSectionInformation) {
            return RMCloudInformationRowMax;
        }
    }
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (@available(iOS 8.0, *)) {
        return 44.f;
    } else {
        return [self tableView:tableView heightForRowAtIndexPath:indexPath];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
        if (indexPath.section == RMCloudDetailSectionHeader || indexPath.section == RMCloudDetailSectionDescription)
        {
            if (@available(iOS 8.0, *)) {
                return UITableViewAutomaticDimension;
            } else {
                return [self tableView:tableView heightForAutoResizingCell:[tableView cellForRowAtIndexPath:indexPath]];
            }
        }
        else if (indexPath.section == RMCloudDetailSectionInformation) {
            return 44.f;
        }
    }
    return 0;
}

// work around for iOS 7
- (CGFloat)tableView:(UITableView *)tableView heightForAutoResizingCell:(UITableViewCell *)cell {
    [cell setNeedsUpdateConstraints];
    [cell updateConstraintsIfNeeded];
    
    cell.bounds = CGRectMake(0.0f, 0.0f, CGRectGetWidth(tableView.bounds), CGRectGetHeight(cell.bounds));
    [cell setNeedsLayout];
    [cell layoutIfNeeded];
    
    // UITextViews cannot autosize well with systemLayoutSizeFittingSize: on iOS 7...
    BOOL textViewInside = NO;
    CGFloat additionalUITextViewsHeight = 0.f;
    UIEdgeInsets textViewContainerInsets = UIEdgeInsetsZero;
    for (UIView *subview in cell.contentView.subviews) {
        if ([subview isKindOfClass:[UITextView class]]) {
            textViewInside = YES;
            UITextView *subTextView = (UITextView *)subview;
            CGSize textViewSize = [subTextView sizeThatFits:CGSizeMake(CGRectGetWidth(subTextView.bounds), CGFLOAT_MAX)];
            textViewContainerInsets = subTextView.textContainerInset;
            additionalUITextViewsHeight = textViewSize.height;
            break;
        }
    }
    
    if (textViewInside) {
        return
        additionalUITextViewsHeight +
        textViewContainerInsets.top +
        textViewContainerInsets.bottom +
        1.f;
    }
    
    CGFloat height = [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
    CGFloat fixedHeight = (height > 0) ? (height + 1.f) : 44.f;
    return fixedHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == RMCloudDetailSectionHeader) {
        RMCloudProjectDetailCell *cell = [tableView dequeueReusableCellWithIdentifier:RMCloudProjectDetailCellReuseIdentifier];
        if (cell == nil) {
            cell = [[RMCloudProjectDetailCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:RMCloudProjectDetailCellReuseIdentifier];
        }
        RMProject *project = self.project;
        if (project) {
            [cell setProject:project];
        }
        return cell;
    } else if (indexPath.section == RMCloudDetailSectionDescription) {
        RMCloudProjectDescriptionCell *cell = [tableView dequeueReusableCellWithIdentifier:RMCloudProjectDescriptionCellReuseIdentifier];
        if (cell == nil) {
            cell = [[RMCloudProjectDescriptionCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:RMCloudProjectDescriptionCellReuseIdentifier];
        }
        RMProject *project = self.project;
        if (project) {
            [cell setProject:project];
        }
        return cell;
    } else if (indexPath.section == RMCloudDetailSectionInformation) {
        RMProject *project = self.project;
        if (project) {
            if (indexPath.row == RMCloudInformationRowAuthor ||
                indexPath.row == RMCloudInformationRowVersion ||
                indexPath.row == RMCloudInformationRowDownloadTimes ||
                indexPath.row == RMCloudInformationRowTrail ||
                indexPath.row == RMCloudInformationRowContact) {
                RMCloudExpandableCell *cell = [tableView dequeueReusableCellWithIdentifier:RMCloudExpandableCellReuseIdentifier];
                if (cell == nil) {
                    cell = [[RMCloudExpandableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:RMCloudExpandableCellReuseIdentifier];
                }
                if (indexPath.row == RMCloudInformationRowAuthor)
                {
                    cell.titleTextLabel.text = NSLocalizedString(@"Author", nil);
                    NSString *authorName = self.project.authorName;
                    if (authorName.length) {
                        cell.valueTextLabel.text = authorName;
                    }
                }
                else if (indexPath.row == RMCloudInformationRowVersion)
                {
                    cell.titleTextLabel.text = NSLocalizedString(@"Version", nil);
                    cell.valueTextLabel.text = [NSString stringWithFormat:@"v%.2f", project.projectVersion];
                }
                else if (indexPath.row == RMCloudInformationRowDownloadTimes)
                {
                    cell.titleTextLabel.text = NSLocalizedString(@"Download Times", nil);
                    cell.valueTextLabel.text = [NSString stringWithFormat:@"%lu", project.downloadTimes];
                }
                else if (indexPath.row == RMCloudInformationRowTrail)
                {
                    cell.titleTextLabel.text = NSLocalizedString(@"Trail", nil);
                    NSString *trailString = [self.project localizedTrailDescription];
                    if (trailString.length) {
                        cell.valueTextLabel.text = trailString;
                    }
                }
                else if (indexPath.row == RMCloudInformationRowContact)
                {
                    cell.titleTextLabel.text = NSLocalizedString(@"Contact", nil);
                    NSString *contactString = self.project.contactString;
                    if (contactString.length) {
                        cell.valueTextLabel.text = contactString;
                    }
                }
                return cell;
            }
            else if (indexPath.row == RMCloudInformationRowBuy) {
                RMCloudLinkCell *cell = [tableView dequeueReusableCellWithIdentifier:RMCloudLinkCellReuseIdentifier];
                if (cell == nil) {
                    cell = [[RMCloudLinkCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:RMCloudLinkCellReuseIdentifier];
                }
                if (indexPath.row == RMCloudInformationRowBuy) {
                    cell.titleTextLabel.text = NSLocalizedString(@"Purchase Now", nil);
                    cell.linkIconImageView.image = [[UIImage imageNamed:@"RMCloudLinkPurchase"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                }
                return cell;
            }
        }
    }
    return [UITableViewCell new];
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return [UITableViewHeaderFooterView new];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 32.f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == RMCloudDetailSectionHeader) {
        return 16.f;
    }
    return 16.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    header.textLabel.font = [UIFont boldSystemFontOfSize:20.0];
    UIView *bgView = [[UIView alloc] init];
    header.backgroundView = bgView;
    bgView.backgroundColor = [UIColor clearColor];
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(nonnull UIView *)view forSection:(NSInteger)section {
    UITableViewHeaderFooterView *footer = (UITableViewHeaderFooterView *)view;
    UIView *bgView = [[UIView alloc] init];
    footer.backgroundView = bgView;
    bgView.backgroundColor = [UIColor clearColor];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (self.project) {
        if (tableView == self.tableView) {
            if (section == RMCloudDetailSectionDescription) {
                return NSLocalizedString(@"Item Detail", nil);
            }
            else if (section == RMCloudDetailSectionInformation) {
                return NSLocalizedString(@"Information", nil);
            }
        }
    }
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return nil;
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [RMCloudProjectViewController dealloc]");
#endif
}

@end
