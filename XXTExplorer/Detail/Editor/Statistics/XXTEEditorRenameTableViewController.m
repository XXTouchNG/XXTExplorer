//
//  XXTEEditorRenameTableViewController.m
//  XXTExplorer
//
//  Created by Darwin on 8/30/19.
//  Copyright © 2019 Zheng. All rights reserved.
//

#import "XXTEEditorRenameTableViewController.h"
#import <sys/stat.h>
#import <PromiseKit/PromiseKit.h>

#import "XUIViewShaker.h"
#import "XXTExplorerEntry.h"
#import "XXTExplorerEntryParser.h"
#import "XXTExplorerItemNameCell.h"


@interface XXTEEditorRenameTableViewController () <UITextFieldDelegate>

@property (nonatomic, strong) XXTExplorerEntry *entry;
@property (nonatomic, strong) XXTExplorerEntryParser *entryParser;
@property (nonatomic, strong) XXTExplorerItemNameCell *itemNameCell;
@property (nonatomic, strong) UITextField *nameField;
@property (nonatomic, strong) XUIViewShaker *itemNameShaker;

@property (nonatomic, assign) BOOL needsReload;
@property (nonatomic, assign) BOOL needsSave;

@end

@implementation XXTEEditorRenameTableViewController

- (instancetype)initWithPath:(NSString *)path {
    if (self = [super initWithStyle:UITableViewStyleGrouped]) {
        _path = path;
        XXTExplorerEntryParser *entryParser = [[XXTExplorerEntryParser alloc] init];
        _entryParser = entryParser;
        XXTExplorerEntry *entry = [entryParser entryOfPath:path withError:nil];
        _entry = entry;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if (self.tableView.style == UITableViewStylePlain) {
        self.view.backgroundColor = XXTColorPlainBackground();
    } else {
        self.view.backgroundColor = XXTColorGroupedBackground();
    }
    
    XXTE_START_IGNORE_PARTIAL
    self.clearsSelectionOnViewWillAppear = self.splitViewController.isCollapsed;
    XXTE_END_IGNORE_PARTIAL
    
    self.title = NSLocalizedString(@"Item Rename", nil);
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeNone;
    
    XXTE_START_IGNORE_PARTIAL
    self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    XXTE_END_IGNORE_PARTIAL
    
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    
    [self reloadStaticTableViewData];
}

- (void)viewWillAppear:(BOOL)animated {
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldDidChangeWithNotificaton:) name:UITextFieldTextDidChangeNotification object:self.nameField];
    }
    [super viewWillAppear:animated];
    [self reloadIfNeeded];
}

- (void)viewWillDisappear:(BOOL)animated {
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
    [super viewWillDisappear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (![self.nameField isFirstResponder]) {
        [self.nameField becomeFirstResponder];
    }
}

- (void)reloadStaticTableViewData {
    // Prepare
    XXTExplorerEntry *entry = self.entry;
    if (!entry) return;
    
    NSString *entryPath = entry.entryPath;
    struct stat entryStat;
    if (lstat([entryPath fileSystemRepresentation], &entryStat) != 0) return;
    
    // #1 - Name (Required)
    {
        XXTExplorerItemNameCell *cell1 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTExplorerItemNameCell class]) owner:nil options:nil] lastObject];
        cell1.nameField.delegate = self;
        cell1.nameField.text = entry.entryName;
        self.nameField = cell1.nameField;
        self.itemNameShaker = [[XUIViewShaker alloc] initWithView:self.nameField];
        self.itemNameCell = cell1;
    }
}

#pragma mark - UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        return 1;
    }
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    return 44.f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44.f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        if (section == 0) {
            return NSLocalizedString(@"New Filename", nil);
        }
    }
    return @"";
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        if (section == 0) {
            return NSLocalizedString(@"Tap \"Done\" on keyboard to save changes you just made.", nil);
        }
    }
    return @"";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
        if (indexPath.section == 0 && indexPath.row == 0) {
            return self.itemNameCell;
        }
    }
    return [UITableViewCell new];
}

#pragma mark - UIControl Actions

- (void)dismissViewController:(id)sender {
    if ([self.nameField isFirstResponder]) {
        [self.nameField resignFirstResponder];
    }
    [self.navigationController popViewControllerAnimated:YES];
}

- (BOOL)submitViewController:(id)sender completion:(void (^)(BOOL, NSError *))completion {
    if (!self.needsSave) {
        return NO;
    }
    NSFileManager *renameManager = [[NSFileManager alloc] init];
    XXTExplorerEntry *entry = self.entry;
    NSString *entryPath = entry.entryPath;
    NSString *entryParentPath = [entryPath stringByDeletingLastPathComponent];
    if (entryParentPath.length == 0) {
        if (completion) {
            completion(NO, nil);
        }
        return NO;
    }
    BOOL isDirectory = NO;
    BOOL parentExists = [renameManager fileExistsAtPath:entryParentPath isDirectory:&isDirectory];
    if (!parentExists || !isDirectory) {
        if (completion) {
            completion(NO, nil);
        }
        return NO;
    }
    NSString *itemName = self.nameField.text;
    
    if (itemName.length == 0 || [itemName rangeOfString:@"/"].location != NSNotFound || [itemName rangeOfString:@"\0"].location != NSNotFound) {
        if (completion) {
            completion(NO, nil);
        }
        return NO;
    }
    
    struct stat itemStat;
    NSString *itemPath = [entryParentPath stringByAppendingPathComponent:itemName];
    if (/* [renameManager fileExistsAtPath:itemPath] */ 0 == lstat([itemPath UTF8String], &itemStat)) {
        if (completion) {
            completion(NO, [NSError errorWithDomain:kXXTErrorDomain code:403 userInfo:@{ NSLocalizedDescriptionKey: [NSString stringWithFormat:NSLocalizedString(@"File \"%@\" already exists.", nil), itemName] }]);
        }
        return NO;
    }
    UIViewController *blockVC = blockInteractions(self, YES);
    @weakify(self);
    [PMKPromise new:^(PMKFulfiller fulfill, PMKRejecter reject) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            NSError *renameError = nil;
            BOOL renameResult = [renameManager moveItemAtPath:entryPath toPath:itemPath error:&renameError];
            if (!renameResult) {
                if (renameError) {
                    reject(renameError);
                }
            } else {
                fulfill(@(renameResult));
            }
        });
    }].then(^(NSNumber *renameResult) {
        @strongify(self);
        BOOL result = [renameResult boolValue];
        if (result) {
            if (completion) {
                completion(YES, nil);
            }
            if ([self->_delegate respondsToSelector:@selector(renameTableViewController:itemDidMoveToPath:)]) {
                [self->_delegate renameTableViewController:self itemDidMoveToPath:itemPath];
            }
        } else {
            if (completion) {
                completion(NO, nil);
            }
        }
    }).catch(^(NSError *systemError) {
        if (completion) {
            completion(NO, systemError);
        }
    }).finally(^() {
        blockInteractions(blockVC, NO);
    });
    return YES;
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if (textField == self.nameField) {
        NSString *text = textField.text;
        NSRange range = NSMakeRange(text.length, 0);
        if (self.entry.isRegistered) {
            NSRange dotRange = [text rangeOfString:@"." options:NSBackwardsSearch];
            if (dotRange.location != NSNotFound) {
                range = dotRange;
            }
        }
        UITextRange *prefixRange = [textField textRangeFromPosition:textField.beginningOfDocument toPosition:[textField positionFromPosition:textField.beginningOfDocument offset:range.location]];
        [textField setSelectedTextRange:prefixRange];
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (textField == self.nameField) {
        if ([string rangeOfString:@"/"].location != NSNotFound || [string rangeOfString:@"\0"].location != NSNotFound) {
            [self.itemNameShaker shake];
            return NO;
        }
        return YES;
    }
    return NO;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.nameField) {
        @weakify(self);
        BOOL returnResult = [self submitViewController:textField completion:^(BOOL result, NSError *error) {
            @strongify(self);
            if (result) {
                if ([self.nameField isFirstResponder]) {
                    [self.nameField resignFirstResponder];
                }
                [self dismissViewController:self];
            } else if (error) {
                toastError(self, error);
                [self.itemNameShaker shake];
            } else {
                [self.itemNameShaker shake];
            }
        }];
        return returnResult;
    }
    return NO;
}

- (void)textFieldDidChangeWithNotificaton:(NSNotification *)aNotification {
    UITextField *textField = (UITextField *)aNotification.object;
    if (textField.text.length > 0) {
        if ([textField.text isEqualToString:self.entry.entryName]) {
            self.needsSave = NO;
        } else {
            self.needsSave = YES;
        }
    } else {
        self.needsSave = NO;
    }
}

- (void)reloadIfNeeded {
    if (self.needsReload) {
        self.needsReload = NO;
        NSString *entryPath = self.entry.entryPath;
        self.entry = [self.entryParser entryOfPath:entryPath withError:nil];
        [self reloadStaticTableViewData];
        [self.tableView reloadData];
    }
}

#pragma mark - Dismissal (Override)

- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion {
    if (!XXTE_IS_FULLSCREEN(self)) {
        [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:XXTENotificationEvent object:self userInfo:@{XXTENotificationEventType: XXTENotificationEventTypeFormSheetDismissed}]];
    }
    [super dismissViewControllerAnimated:flag completion:completion];
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [%@ dealloc]", NSStringFromClass([self class]));
#endif
}

@end
