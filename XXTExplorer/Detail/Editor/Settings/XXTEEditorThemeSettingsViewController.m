//
//  XXTEEditorThemeSettingsViewController.m
//  XXTExplorer
//
//  Created by Zheng Wu on 21/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEEditorThemeSettingsViewController.h"

#import "XXTEEditorThemeCell.h"
#import "UIColor+hexValue.h"
#import "UIColor+SKColor.h"
#import <SOZOChromoplast/SOZOChromoplast.h>
#import <YYCache/YYCache.h>


#define kEditorThemeMainColorCacheKey @"kEditorThemeMainColorCacheKey"

@interface XXTEEditorThemeSettingsViewController ()

@property (nonatomic, strong) UIBarButtonItem *previewItem;
@property (nonatomic, strong) NSArray <NSDictionary *> *themes;
@property (nonatomic, strong) YYCache *sozoCache;

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

- (instancetype)initWithStyle:(UITableViewStyle)style definesPath:(NSString *)path {
    if (self = [super initWithStyle:style]) {
        [self setupWithDefinesPath:path];
    }
    return self;
}

- (void)setup {
    NSString *defaultDefinesPath = [[NSBundle mainBundle] pathForResource:@"SKTheme" ofType:@"plist"];
    [self setupWithDefinesPath:defaultDefinesPath];
}

- (void)setupWithDefinesPath:(NSString *)path {
    NSString *rawThemesPath = path;
    NSArray <NSDictionary *> *rawThemes = [[NSArray alloc] initWithContentsOfFile:rawThemesPath];
    NSMutableArray <NSDictionary *> *availableThemes = [[NSMutableArray alloc] init];
    for (NSDictionary *rawTheme in rawThemes) {
        NSString *themeName = rawTheme[@"name"];
        NSString *themeLocation = rawTheme[@"location"];
        if (![themeName isKindOfClass:[NSString class]] ||
            ![themeLocation isKindOfClass:[NSString class]]
            ) {
            continue;
        }
        if (themeLocation.length > 0) {
            if ([[NSBundle mainBundle] pathForResource:themeLocation ofType:@""])
            {
                [availableThemes addObject:rawTheme];
            }
        }
        else
        {
            if ([[NSBundle mainBundle] pathForResource:themeName ofType:@"tmTheme"])
            {
                [availableThemes addObject:rawTheme];
            }
        }
    }
    _themes = [availableThemes copy];
    _sozoCache = [[YYCache alloc] initWithName:@"kEditorThemeMainColorCacheKey"];
}

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Theme", nil);
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
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
        NSString *themeTitle = theme[@"title"] ?: themeName;
        
        XXTEEditorThemeCell *cell = [tableView dequeueReusableCellWithIdentifier:XXTEEditorThemeCellReuseIdentifier forIndexPath:indexPath];
        cell.titleLabel.text = themeTitle;
        
        NSString *previewValue = theme[@"preview"];
        UIImage *exampleImage = nil;
        if ([previewValue isKindOfClass:[NSString class]]) {
            exampleImage = [UIImage imageNamed:previewValue];
            cell.previewImageView.image = exampleImage;
        }
        
        if ([themeName isEqualToString:self.selectedThemeName]) {
            // cell.titleLabel.textColor = XXTColorDefault();
            cell.selectFlagView.hidden = NO;
        } else {
            // cell.titleLabel.textColor = [UIColor whiteColor];
            cell.selectFlagView.hidden = YES;
        }
        
        if (exampleImage) {
            NSString *mainKey = [NSString stringWithFormat:@"%@", previewValue];
            NSString *dominantKey = [NSString stringWithFormat:@"%@/dominantColor", previewValue];
            NSString *firstKey = [NSString stringWithFormat:@"%@/firstHighlight", previewValue];
            // NSString *secondKey = [NSString stringWithFormat:@"%@/secondHighlight", previewValue];
            
            BOOL cached = [(NSNumber *)[self.sozoCache objectForKey:mainKey] boolValue];
            if (cached) {
                NSString *dominantHex = (NSString *)[self.sozoCache objectForKey:dominantKey];
                NSString *firstHex = (NSString *)[self.sozoCache objectForKey:firstKey];
                // NSString *secondHex = (NSString *)[self.sozoCache objectForKey:secondKey];
                
                cell.backgroundColor = [UIColor colorWithHex:dominantHex];
                cell.titleLabel.textColor = [UIColor colorWithHex:firstHex];
            } else {
                // Instantiate your chromoplast
                SOZOChromoplast *chromoplast = [[SOZOChromoplast alloc] initWithImage:exampleImage];
                
                // Use your colors!
                cell.backgroundColor = chromoplast.dominantColor;
                cell.titleLabel.textColor = chromoplast.firstHighlight;
                
                [self.sozoCache setObject:@(YES) forKey:mainKey];
                [self.sozoCache setObject:[chromoplast.dominantColor hexString] forKey:dominantKey];
                [self.sozoCache setObject:[chromoplast.firstHighlight hexString] forKey:firstKey];
                // [self.sozoCache setObject:[chromoplast.secondHighlight hexString] forKey:secondKey];
            }
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
        
        if (![self.selectedThemeName isEqualToString:themeName]) {
            self.selectedThemeName = themeName;
            self.selectedThemeEntry = theme;
            
            for (XXTEEditorThemeCell *cell in tableView.visibleCells) {
                // cell.titleLabel.textColor = [UIColor whiteColor];
                cell.selectFlagView.hidden = YES;
            }
            XXTEEditorThemeCell *selectCell = [tableView cellForRowAtIndexPath:indexPath];
            // selectCell.titleLabel.textColor = XXTColorDefault();
            selectCell.selectFlagView.hidden = NO;
            
            if (_delegate && [_delegate respondsToSelector:@selector(themeSettingsViewControllerSettingsDidChanged:)]) {
                [_delegate themeSettingsViewControllerSettingsDidChanged:self];
            }
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
    if (!self.selectedThemeName || self.themes.count == 0) {
        toastMessage(self, NSLocalizedString(@"No theme available.", nil));
        return;
    }
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
