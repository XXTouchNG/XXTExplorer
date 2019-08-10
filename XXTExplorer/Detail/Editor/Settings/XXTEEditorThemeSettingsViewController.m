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


@interface XXTEEditorThemeSettingsViewController ()

@property (nonatomic, strong) UIBarButtonItem *previewItem;
@property (nonatomic, strong) NSArray <NSDictionary *> *themes;

@end

@implementation XXTEEditorThemeSettingsViewController

+ (YYCache *)sozoCache {
    static YYCache *sozoCache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sozoCache = [[YYCache alloc] initWithName:@"kEditorThemeMainColorCacheKey"];
    });
    return sozoCache;
}

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
    [self loadThemeColorCache];
}

#pragma mark - Cache

- (void)loadThemeColorCache {
    Class myClass = [XXTEEditorThemeSettingsViewController class];
    NSArray <NSDictionary *> *themes = self.themes;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        for (NSDictionary *theme in themes) {
            NSString *themePreview = theme[@"preview"];
            if (![themePreview isKindOfClass:[NSString class]]) {
                continue;
            }
            UIImage *exampleImage = [UIImage imageNamed:themePreview];
            if (!exampleImage) {
                continue;
            }
            NSString *mainKey = [NSString stringWithFormat:@"%@", themePreview];
            BOOL cached = [(NSNumber *)[myClass.sozoCache objectForKey:mainKey] boolValue];
            if (cached) {
                continue;
            }
            
            NSString *dominantKey = [NSString stringWithFormat:@"%@/dominantColor", themePreview];
            NSString *firstKey = [NSString stringWithFormat:@"%@/firstHighlight", themePreview];
            NSString *secondKey = [NSString stringWithFormat:@"%@/secondHighlight", themePreview];
            
            SOZOChromoplast *chromoplast = [[SOZOChromoplast alloc] initWithImage:exampleImage];
            [myClass.sozoCache setObject:@(YES) forKey:mainKey];
            [myClass.sozoCache setObject:[chromoplast.dominantColor hexString] forKey:dominantKey];
            [myClass.sozoCache setObject:[chromoplast.firstHighlight hexString] forKey:firstKey];
            [myClass.sozoCache setObject:[chromoplast.secondHighlight hexString] forKey:secondKey];
            
#ifdef DEBUG
            dispatch_async_on_main_queue(^{
                NSLog(@"SOZOChromoplast cached: %@", themePreview);
            });
#endif
        }
    });
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
        
        NSString *themePreview = theme[@"preview"];
        UIImage *exampleImage = nil;
        if ([themePreview isKindOfClass:[NSString class]]) {
            exampleImage = [UIImage imageNamed:themePreview];
            cell.previewImageView.image = exampleImage;
        }
        
        UIColor *highlightColor = [UIColor whiteColor];
        if (exampleImage) {
            NSString *mainKey = [NSString stringWithFormat:@"%@", themePreview];
            NSString *dominantKey = [NSString stringWithFormat:@"%@/dominantColor", themePreview];
            NSString *firstKey = [NSString stringWithFormat:@"%@/firstHighlight", themePreview];
            // NSString *secondKey = [NSString stringWithFormat:@"%@/secondHighlight", themePreview];
            
            BOOL cached = [(NSNumber *)[self.class.sozoCache objectForKey:mainKey] boolValue];
            if (cached) {
                NSString *dominantHex = (NSString *)[self.class.sozoCache objectForKey:dominantKey];
                NSString *firstHex = (NSString *)[self.class.sozoCache objectForKey:firstKey];
                // NSString *secondHex = (NSString *)[self.class.sozoCache objectForKey:secondKey];
                
                highlightColor = [UIColor colorWithHex:firstHex];
                cell.backgroundColor = [UIColor colorWithHex:dominantHex];
                cell.titleLabel.textColor = highlightColor;
            } else {
                // Instantiate your chromoplast
                SOZOChromoplast *chromoplast = [[SOZOChromoplast alloc] initWithImage:exampleImage];
                
                // Use your colors!
                highlightColor = chromoplast.firstHighlight;
                cell.backgroundColor = chromoplast.dominantColor;
                cell.titleLabel.textColor = highlightColor;
                
                [self.class.sozoCache setObject:@(YES) forKey:mainKey];
                [self.class.sozoCache setObject:[chromoplast.dominantColor hexString] forKey:dominantKey];
                [self.class.sozoCache setObject:[chromoplast.firstHighlight hexString] forKey:firstKey];
                // [self.class.sozoCache setObject:[chromoplast.secondHighlight hexString] forKey:secondKey];
            }
        }
        cell.titleBaseView.backgroundColor = [highlightColor colorWithAlphaComponent:0.1];
        
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
                // cell.titleBaseView.backgroundColor = [UIColor clearColor];
            }
            XXTEEditorThemeCell *selectCell = [tableView cellForRowAtIndexPath:indexPath];
            // selectCell.titleBaseView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.1];
            
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
