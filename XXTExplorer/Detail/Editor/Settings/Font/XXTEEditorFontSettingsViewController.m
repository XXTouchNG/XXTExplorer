//
//  XXTEEditorFontSettingsViewController.m
//  XXTExplorer
//
//  Created by Zheng Wu on 21/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEEditorFontSettingsViewController.h"

#import "XXTEMoreLinkNoIconCell.h"

@interface XXTEEditorFontSettingsViewController ()

@property (nonatomic, strong) NSArray <UIFont *> *fonts;

@end

@implementation XXTEEditorFontSettingsViewController

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
    NSString *fontNamesPath = [[NSBundle mainBundle] pathForResource:@"SKFont" ofType:@"plist"];
    NSArray <NSString *> *fontNames = [[NSArray alloc] initWithContentsOfFile:fontNamesPath];
    NSMutableArray <UIFont *> *fonts = [[NSMutableArray alloc] init];
    for (NSString *fontName in fontNames) {
        UIFont *font = [UIFont fontWithName:fontName size:17.f];
        if (font) {
            [fonts addObject:font];
        }
    }
    _fonts = fonts;
}

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Font Family", nil);
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([XXTEMoreLinkNoIconCell class]) bundle:[NSBundle mainBundle]] forCellReuseIdentifier:XXTEMoreLinkNoIconCellReuseIdentifier];
    
    XXTE_START_IGNORE_PARTIAL
    if (@available(iOS 9.0, *)) {
        self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    }
    XXTE_END_IGNORE_PARTIAL
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }
}

#pragma mark - UITableViewDelegate / DataSource

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44.f;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return self.fonts.count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        XXTEMoreLinkNoIconCell *cell = [tableView dequeueReusableCellWithIdentifier:XXTEMoreLinkNoIconCellReuseIdentifier forIndexPath:indexPath];
        UIFont *font = self.fonts[indexPath.row];
        cell.titleLabel.text = font.familyName;
        cell.titleLabel.font = font;
        if ([[font fontName] isEqualToString:self.selectedFontName]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        return cell;
    }
    return [UITableViewCell new];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 0) {
        UIFont *font = self.fonts[indexPath.row];
        NSString *fontName = [font fontName];
        self.selectedFontName = fontName;
        
        for (UITableViewCell *cell in tableView.visibleCells) {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        UITableViewCell *selectCell = [tableView cellForRowAtIndexPath:indexPath];
        selectCell.accessoryType = UITableViewCellAccessoryCheckmark;
        
        if (_delegate && [_delegate respondsToSelector:@selector(fontSettingsViewControllerSettingsDidChanged:)]) {
            [_delegate fontSettingsViewControllerSettingsDidChanged:self];
        }
    }
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [XXTEEditorFontSettingsViewController dealloc]");
#endif
}

@end
