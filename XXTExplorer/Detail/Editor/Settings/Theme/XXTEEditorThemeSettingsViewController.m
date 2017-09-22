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
    _themes = rawThemes;
    
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([XXTEEditorThemeCell class]) bundle:[NSBundle mainBundle]] forCellReuseIdentifier:XXTEEditorThemeCellReuseIdentifier];
}

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Theme", nil);
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    XXTE_START_IGNORE_PARTIAL
    if (XXTE_SYSTEM_9) {
        self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    }
    XXTE_END_IGNORE_PARTIAL
    
//    self.navigationItem.rightBarButtonItem = self.previewItem;
}

#pragma mark - UITableViewDelegate / DataSource

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 128.f;
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
        if ([theme[@"preview"] isKindOfClass:[UIImage class]]) {
            cell.previewImageView.image = theme[@"preview"];
        } else {
            cell.previewImageView.image = nil;
        }
        if ([themeName isEqualToString:self.selectedThemeName]) {
            cell.titleLabel.textColor = XXTE_COLOR;
        } else {
            cell.titleLabel.textColor = [UIColor blackColor];
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
        }
        XXTEEditorThemeCell *selectCell = [tableView cellForRowAtIndexPath:indexPath];
        selectCell.titleLabel.textColor = XXTE_COLOR;
        
        if (_delegate && [_delegate respondsToSelector:@selector(themeSettingsViewControllerSettingsDidChanged:)]) {
            [_delegate themeSettingsViewControllerSettingsDidChanged:self];
        }
    }
}

#pragma mark - UIView Getters

- (UIBarButtonItem *)previewItem {
    if (!_previewItem) {
        UIBarButtonItem *previewItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Preview", nil) style:UIBarButtonItemStylePlain target:self action:@selector(previewItemTapped:)];
        _previewItem = previewItem;
    }
    return _previewItem;
}

- (void)previewItemTapped:(UIBarButtonItem *)sender {
    
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [XXTEEditorThemeSettingsViewController dealloc]");
#endif
}

@end
