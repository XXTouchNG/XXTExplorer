//
//  XXTESymbolViewController.m
//  XXTExplorer
//
//  Created by Zheng on 05/11/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTESymbolViewController.h"

#import "XXTEAppDefines.h"
#import "XXTEUserInterfaceDefines.h"
#import "XXTEDispatchDefines.h"
#import "XXTEEditorDefaults.h"

// Parent
#import "XXTEEditorController.h"
#import "XXTEEditorController+NavigationBar.h"
#import "XXTEEditorTheme.h"
#import "XXTEEditorLanguage.h"
#import "UIColor+SKColor.h"

#import "XXTEMoreLinkCell.h"
#import "XXTEEditorTextView.h"
#import "SKParser.h"

@interface XXTESymbolViewController ()

//@property (nonatomic, strong) UIFont *font;
@property (nonatomic, strong) NSMutableArray <NSDictionary *> *symbolsTable;

@end

@implementation XXTESymbolViewController

+ (BOOL)hasSymbolPatternsForLanguage:(XXTEEditorLanguage *)language {
    return (language.symbolScopes.count > 0);
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

- (void)setup {
//    NSString *fontName = XXTEDefaultsObject(XXTEEditorFontName, @"CourierNewPSMT");
//    _font = [UIFont fontWithName:fontName size:17.0];
    _symbolsTable = [[NSMutableArray alloc] init];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.clearsSelectionOnViewWillAppear = YES;
    self.title = NSLocalizedString(@"Symbols", nil);
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([XXTEMoreLinkCell class]) bundle:[NSBundle mainBundle]] forCellReuseIdentifier:XXTEMoreLinkCellReuseIdentifier];
    
    XXTE_START_IGNORE_PARTIAL
    if (@available(iOS 9.0, *)) {
        self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    }
    XXTE_END_IGNORE_PARTIAL
    
    NSError *error = nil;
    BOOL result = [self loadFileSymbolsWithError:&error];
    if (!result) {
        toastMessage(self, [error localizedDescription]);
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [self.editor renderNavigationBarTheme:YES];
    [super viewWillAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (void)willMoveToParentViewController:(UIViewController *)parent {
    if (parent == nil) {
        [self.editor renderNavigationBarTheme:NO];
    } else {
        [self.editor renderNavigationBarTheme:YES];
    }
    [super willMoveToParentViewController:parent];
}

- (BOOL)loadFileSymbolsWithError:(NSError **)error {
    [self.symbolsTable removeAllObjects];
    
    NSArray <NSString *> *symbols = self.editor.language.symbolScopes;
    if (!symbols) {
        return NO;
    }
    NSString *string = self.editor.textView.text;
    if (!string) {
        return NO;
    }
    SKLanguage *language = self.editor.language.rawLanguage;
    if (!language) {
        return NO;
    }
    SKParser *parser = [[SKParser alloc] initWithLanguage:language];
    if (!parser) {
        return NO;
    }
    
    blockInteractions(self, YES);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [parser parseString:string matchCallback:^(NSString *scopeName, NSRange range) {
            NSArray <NSString *> *scopes = [scopeName componentsSeparatedByString:@"."];
            if ([scopes containsObject:@"entity"]) {
                NSValue *rangeVal = [NSValue valueWithRange:range];
                NSString *title = [string substringWithRange:range];
                NSDictionary *cache =
                @{
                  @"range": rangeVal,
                  @"title": title,
                  @"scopeName": scopeName,
                  };
                [self.symbolsTable addObject:cache];
            }
        }];
        dispatch_async_on_main_queue(^{
            blockInteractions(self, NO);
            [self.tableView reloadData];
        });
    });
    return YES;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44.f;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (0 == section) {
        return self.symbolsTable.count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0)
    {
        XXTEMoreLinkCell *cell =
        [tableView dequeueReusableCellWithIdentifier:XXTEMoreLinkCellReuseIdentifier];
        if (nil == cell)
        {
            cell = [[XXTEMoreLinkCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                 reuseIdentifier:XXTEMoreLinkCellReuseIdentifier];
        }
        [self configureCell:cell forRowAtIndexPath:indexPath];
        
        return cell;
    }
    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

- (void)configureCell:(XXTEMoreLinkCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger idx = indexPath.row;
    if (idx < self.symbolsTable.count) {
        NSDictionary *detail = self.symbolsTable[idx];
        cell.titleLabel.text = detail[@"title"];
//        cell.titleLabel.font = self.font;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSUInteger idx = indexPath.row;
    if (idx < self.symbolsTable.count) {
        NSDictionary *detail = self.symbolsTable[idx];
        NSRange toRange = [detail[@"range"] rangeValue];
        // scroll to range if exists
    }
}

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [XXTESymbolViewController dealloc]");
#endif
}

@end
