//
//  XXTEEditorThemeSettingsViewController.m
//  XXTExplorer
//
//  Created by Zheng Wu on 21/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEEditorThemeSettingsViewController.h"

#import "XXTEEditorThemeCell.h"

@interface XXTEEditorThemeSettingsViewController ()

@property (nonatomic, strong) UIBarButtonItem *previewItem;
@property (nonatomic, strong) NSArray <NSDictionary *> *themes;

@end

@implementation XXTEEditorThemeSettingsViewController

- (instancetype)init {
    if (self = [super init]) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithStyle:(UITableViewStyle)style {
    if (self = [super initWithStyle:style]) {
        [self setup];
    }
    return self;
}

- (void)setup {
    NSString *rawThemesPath = [[NSBundle mainBundle] pathForResource:@"SKTheme" ofType:@"plist"];
    NSArray <NSDictionary *> *rawThemes = [[NSArray alloc] initWithContentsOfFile:rawThemesPath];
    NSMutableArray <NSDictionary *> *availableThemes = [[NSMutableArray alloc] init];
    for (NSDictionary *rawTheme in rawThemes) {
        NSString *themeName = rawTheme[@"name"];
        if ([themeName isKindOfClass:[NSString class]]) {
            if ([[NSBundle mainBundle] pathForResource:themeName ofType:@"tmTheme"])
            {
                [availableThemes addObject:rawTheme];
            }
        }
    }
    _themes = [availableThemes copy];
}

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Theme", nil);
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([XXTEEditorThemeCell class]) bundle:[NSBundle mainBundle]] forCellReuseIdentifier:XXTEEditorThemeCellReuseIdentifier];
    
    XXTE_START_IGNORE_PARTIAL
    if (@available(iOS 9.0, *)) {
        self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    }
    XXTE_END_IGNORE_PARTIAL
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }
    
    self.navigationItem.rightBarButtonItem = self.previewItem;
}

#pragma mark - UITableViewDelegate / DataSource

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return XXTEEditorThemeCellHeight;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.themes.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        NSDictionary *theme = self.themes[indexPath.row];
        NSString *themeName = theme[@"name"];
        XXTEEditorThemeCell *cell = [tableView dequeueReusableCellWithIdentifier:XXTEEditorThemeCellReuseIdentifier forIndexPath:indexPath];
        cell.titleLabel.text = themeName;
        id previewValue = theme[@"preview"];
        if ([previewValue isKindOfClass:[UIImage class]]) {
            cell.previewImageView.image = previewValue;
        } else if ([previewValue isKindOfClass:[NSString class]]) {
            cell.previewImageView.image = [UIImage imageNamed:previewValue];
        }
        if ([themeName isEqualToString:self.selectedThemeName]) {
            cell.titleLabel.textColor = XXTColorDefault();
            cell.selectFlagView.hidden = NO;
        } else {
            cell.titleLabel.textColor = [UIColor blackColor];
            cell.selectFlagView.hidden = YES;
        }
        return cell;
    }
    return [UITableViewCell new];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 0) {
        NSDictionary *theme = self.themes[indexPath.row];
        NSString *themeName = theme[@"name"];
        self.selectedThemeName = themeName;
        
        for (XXTEEditorThemeCell *cell in tableView.visibleCells) {
            cell.titleLabel.textColor = [UIColor blackColor];
            cell.selectFlagView.hidden = YES;
        }
        XXTEEditorThemeCell *selectCell = [tableView cellForRowAtIndexPath:indexPath];
        selectCell.titleLabel.textColor = XXTColorDefault();
        selectCell.selectFlagView.hidden = NO;
        
        if (_delegate && [_delegate respondsToSelector:@selector(themeSettingsViewControllerSettingsDidChanged:)]) {
            [_delegate themeSettingsViewControllerSettingsDidChanged:self];
        }
    }
}

#pragma mark - UIView Getters

- (UIBarButtonItem *)previewItem {
    if (!_previewItem) {
        UIBarButtonItem *previewItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"XXTEEditorThemeTarget"] style:UIBarButtonItemStylePlain target:self action:@selector(previewItemTapped:)];
        _previewItem = previewItem;
    }
    return _previewItem;
}

- (void)previewItemTapped:(UIBarButtonItem *)sender {
    if (!self.selectedThemeName) return;
    NSUInteger idx = 0;
    for (NSDictionary *theme in self.themes) {
        NSString *themeName = theme[@"name"];
        if ([self.selectedThemeName isEqualToString:themeName]) {
            break;
        }
        idx++;
    }
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:idx inSection:0];
    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [%@ dealloc]", NSStringFromClass([self class]));
#endif
}

@end
