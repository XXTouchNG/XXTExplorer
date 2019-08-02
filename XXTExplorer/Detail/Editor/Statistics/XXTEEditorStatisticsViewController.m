//
//  XXTEEditorStatisticsViewController.m
//  XXTExplorer
//
//  Created by Zheng on 2017/10/31.
//  Copyright © 2017年 Zheng. All rights reserved.
//

#import "XXTEEditorStatisticsViewController.h"
#import "XXTEEditorTextView.h"
#import <PromiseKit/PromiseKit.h>
#import "XXTEEditorEncodingController.h"
#import "XXTEEditorEncodingHelper.h"

// Pre-Defines
#import "XXTEEditorDefaults.h"

// Parent
#import "XXTEEditorController.h"
#import "XXTEEditorController+NavigationBar.h"
#import "XXTEEditorTheme.h"
#import "XXTEEditorLanguage.h"

// Cells
#import "XXTEMoreAddressCell.h"
#import "XXTEMoreTitleValueCell.h"

#ifdef APPSTORE
@interface XXTEEditorStatisticsViewController () <XXTEEditorEncodingControllerDelegate>
#else
@interface XXTEEditorStatisticsViewController ()
#endif

@property (strong, nonatomic) UILabel *filenameLabel;
@property (strong, nonatomic) UILabel *filesizeLabel;
@property (strong, nonatomic) UILabel *modificationLabel;

@property (strong, nonatomic) UILabel *encodingLabel;
@property (strong, nonatomic) UILabel *lineEndingsLabel;
@property (strong, nonatomic) UILabel *syntaxDefinitionLabel;

@property (strong, nonatomic) UILabel *lineCountLabel;
@property (strong, nonatomic) UILabel *characterCountLabel;
@property (strong, nonatomic) UILabel *wordCountLabel;

@end

@implementation XXTEEditorStatisticsViewController {
    NSArray <NSArray <UITableViewCell *> *> *staticCells;
    NSArray <NSString *> *staticSectionTitles;
    NSArray <NSString *> *staticSectionFooters;
    BOOL stopCounting;
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
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.clearsSelectionOnViewWillAppear = YES;
    self.title = NSLocalizedString(@"Statistics", nil);
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    XXTE_START_IGNORE_PARTIAL
    if (@available(iOS 9.0, *)) {
        self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    }
    XXTE_END_IGNORE_PARTIAL
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }
    
    [self reloadStaticTableViewData];
    
    NSError *error = nil;
    BOOL result = [self loadFilePropertiesWithError:&error];
    if (!result) {
        toastError(self, error);
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [self.editor renderNavigationBarTheme:YES];
    [super viewWillAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    stopCounting = YES;
}

- (void)willMoveToParentViewController:(UIViewController *)parent {
    if (parent == nil) {
        [self.editor renderNavigationBarTheme:NO];
    } else {
        [self.editor renderNavigationBarTheme:YES];
    }
    [super willMoveToParentViewController:parent];
}

- (void)reloadStaticTableViewData {
    staticSectionTitles = @[ NSLocalizedString(@"Basic", nil), NSLocalizedString(@"Format", nil), NSLocalizedString(@"Counting", nil) ];
    staticSectionFooters = @[ @"", @"", @"" ];
    
    XXTEMoreTitleValueCell *cell1 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
    cell1.titleLabel.text = NSLocalizedString(@"Filename", nil);
    self.filenameLabel = cell1.valueLabel;
    
    XXTEMoreTitleValueCell *cell2 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
    cell2.titleLabel.text = NSLocalizedString(@"Size", nil);
    self.filesizeLabel = cell2.valueLabel;
    
    XXTEMoreTitleValueCell *cell3 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
    cell3.titleLabel.text = NSLocalizedString(@"Modified At", nil);
    cell3.valueLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.modificationLabel = cell3.valueLabel;
    
    XXTEMoreTitleValueCell *cell4 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
    cell4.titleLabel.text = NSLocalizedString(@"Encoding", nil);
#ifdef APPSTORE
    cell4.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
#endif
    self.encodingLabel = cell4.valueLabel;
    
    XXTEMoreTitleValueCell *cell5 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
    cell5.titleLabel.text = NSLocalizedString(@"Line Endings", nil);
#ifdef APPSTORE
    cell5.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
#endif
    self.lineEndingsLabel = cell5.valueLabel;
    
    XXTEMoreTitleValueCell *cell6 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
    cell6.titleLabel.text = NSLocalizedString(@"Syntax Definition", nil);
    self.syntaxDefinitionLabel = cell6.valueLabel;
    
    XXTEMoreTitleValueCell *cell7 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
    cell7.titleLabel.text = NSLocalizedString(@"Line Count", nil);
    self.lineCountLabel = cell7.valueLabel;
    
    XXTEMoreTitleValueCell *cell8 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
    cell8.titleLabel.text = NSLocalizedString(@"Character Count", nil);
    self.characterCountLabel = cell8.valueLabel;
    
    XXTEMoreTitleValueCell *cell9 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
    cell9.titleLabel.text = NSLocalizedString(@"Word Count", nil);
    self.wordCountLabel = cell9.valueLabel;
    
    staticCells = @[
                    @[ cell1, cell2, cell3 ],
                    @[ cell4, cell5, cell6 ],
                    @[ cell7, cell8, cell9 ]
                    ];
}

#pragma mark - Statistics

- (BOOL)loadFilePropertiesWithError:(NSError **)err {
    NSString *filePath = self.editor.entryPath;
    {
        self.filenameLabel.text = [filePath lastPathComponent];
    }
    {
        NSNumber *size = [[[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:err] objectForKey:NSFileSize];
        self.filesizeLabel.text = [NSByteCountFormatter stringFromByteCount:[size intValue] countStyle:NSByteCountFormatterCountStyleFile];
        if (*err) return NO;
    }
    {
        NSDate *modifiedAt = [[[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:err] objectForKey:NSFileModificationDate];
        if (*err) return NO;
        NSDateFormatter *previewFormatter = [[NSDateFormatter alloc] init];
        [previewFormatter setTimeStyle:NSDateFormatterLongStyle];
        [previewFormatter setDateStyle:NSDateFormatterFullStyle];
        self.modificationLabel.text = [previewFormatter stringFromDate:modifiedAt];
    }
    {
        self.encodingLabel.text = [XXTEEditorEncodingHelper encodingNameForEncoding:self.editor.currentEncoding];
    }
    {
        if (self.editor.isLockedState) {
            self.encodingLabel.textColor = XXTColorDanger();
            self.lineEndingsLabel.textColor = XXTColorDanger();
        } else {
            self.encodingLabel.textColor = [XXTEMoreTitleValueCell detailTextColor];
            self.lineEndingsLabel.textColor = [XXTEMoreTitleValueCell detailTextColor];
        }
    }
    {
        NSString *lineEnding = @"";
        if (self.editor.currentLineBreak == NSStringLineBreakTypeCRLF) {
            lineEnding = NSLocalizedString(@"Windows (CRLF)", nil);
        } else if (self.editor.currentLineBreak == NSStringLineBreakTypeLF) {
            lineEnding = NSLocalizedString(@"Unix (LF)", nil);
        } else {
            lineEnding = NSLocalizedString(@"Mac (CR)", nil);
        }
        self.lineEndingsLabel.text = lineEnding;
    }
    {
        if (self.editor.language) {
            self.syntaxDefinitionLabel.text = self.editor.language.displayName;
        } else {
            self.syntaxDefinitionLabel.text = NSLocalizedString(@"Undefined", nil);
        }
    }
    {
        NSString *fileContent = self.editor.textView.text;
        stopCounting = NO;
        self.lineCountLabel.text = NSLocalizedString(@"...", nil);
        self.characterCountLabel.text = NSLocalizedString(@"...", nil);
        self.wordCountLabel.text = NSLocalizedString(@"...", nil);
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
            formatter.numberStyle = NSNumberFormatterDecimalStyle;
            formatter.groupingSize = 3;
            NSUInteger lineCount = [self countChar:fileContent cchar:'\n'] + 1;
            dispatch_async_on_main_queue(^{
                self.lineCountLabel.text = [formatter stringFromNumber:@(lineCount)];
            });
            NSUInteger charCount = [self countCharacters:fileContent];
            dispatch_async_on_main_queue(^{
                self.characterCountLabel.text = [formatter stringFromNumber:@(charCount)];
            });
            NSUInteger wordCount = [self wordCount:fileContent];
            dispatch_async_on_main_queue(^{
                self.wordCountLabel.text = [formatter stringFromNumber:@(wordCount)];
            });
        });
    }
    return YES;
}

- (NSUInteger)countChar:(NSString *)s cchar:(char)c
{
    int count = 0;
    NSUInteger l = [s length];
    for (int i = 0; i < l; i++) {
        char cc = [s characterAtIndex:i];
        if (cc == c) {
            count++;
        }
        if (stopCounting) break;
    }
    return count;
}

- (NSUInteger)wordCount:(NSString *)str {
    NSUInteger words = 0;
    NSScanner *scanner = [NSScanner scannerWithString:str];
    NSCharacterSet *whiteSpace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    while ([scanner scanUpToCharactersFromSet:whiteSpace intoString:nil]) {
        words++;
        if (stopCounting) break;
    }
    return words;
}

- (NSUInteger)countCharacters:(NSString *)s {
    int count = 0;
    NSUInteger l = [s length];
    for (int i = 0; i < l; i++) {
        char cc = [s characterAtIndex:i];
        if (![[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember:cc]) {
            count++;
        }
        if (stopCounting) break;
    }
    return count;
}

#pragma mark - UITableViewDelegate & UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (tableView == self.tableView) {
        return staticCells.count;
    }
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        return [staticCells[section] count];
    }
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    return [self tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
        if (indexPath.section == 0 && indexPath.row == 2)
        {
            if (@available(iOS 8.0, *)) {
                return UITableViewAutomaticDimension;
            } else {
                UITableViewCell *cell = staticCells[indexPath.section][indexPath.row];
                [cell setNeedsUpdateConstraints];
                [cell updateConstraintsIfNeeded];
                
                cell.bounds = CGRectMake(0.0f, 0.0f, CGRectGetWidth(tableView.bounds), CGRectGetHeight(cell.bounds));
                [cell setNeedsLayout];
                [cell layoutIfNeeded];
                
                CGFloat height = [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
                return (height > 0) ? (height + 1.0) : 44.f;
            }
        }
    }
    return 44.f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (tableView == self.tableView) {
        if (indexPath.section == 0) {
            UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            if ([cell isKindOfClass:[XXTEMoreTitleValueCell class]]) {
                NSString *detailText = ((XXTEMoreTitleValueCell *)cell).valueLabel.text;
                if (detailText && detailText.length > 0) {
                    UIViewController *blockVC = blockInteractions(self, YES);
                    [PMKPromise new:^(PMKFulfiller fulfill, PMKRejecter reject) {
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                            [[UIPasteboard generalPasteboard] setString:detailText];
                            fulfill(nil);
                        });
                    }].finally(^() {
                        toastMessage(self, NSLocalizedString(@"Copied to the pasteboard.", nil));
                        blockInteractions(blockVC, NO);
                    });
                }
            }
        } else if (indexPath.section == 1) {
#ifdef APPSTORE
            if (self.editor.isLockedState == NO) {
                if (indexPath.row == 0) {
                    XXTEEditorEncodingController *controller = [[XXTEEditorEncodingController alloc] initWithStyle:UITableViewStylePlain];
                    controller.delegate = self;
                    controller.selectedEncoding = self.editor.currentEncoding;
                    [self.navigationController pushViewController:controller animated:YES];
                }
            }
#endif
        }
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
        return staticCells[indexPath.section][indexPath.row];
    }
    return [UITableViewCell new];
}

#pragma mark - XXTEEditorEncodingControllerDelegate

#ifdef APPSTORE
- (void)encodingControllerDidChange:(XXTEEditorEncodingController *)controller {
    [self.editor setCurrentEncoding:controller.selectedEncoding];
    self.encodingLabel.text = [XXTEEditorEncodingHelper encodingNameForEncoding:self.editor.currentEncoding];
    self.encodingLabel.textColor = [XXTEMoreTitleValueCell detailTextColor];
    [self.editor setNeedsSaveDocument];
    [self.editor setNeedsReload];
}
#endif

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [%@ dealloc]", NSStringFromClass([self class]));
#endif
}

@end
