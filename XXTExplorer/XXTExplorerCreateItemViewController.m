//
//  XXTExplorerCreateItemViewController.m
//  XXTExplorer
//
//  Created by Zheng on 11/06/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTExplorerCreateItemViewController.h"
#import "XXTExplorerItemNameCell.h"
#import "XXTEMoreTitleDescriptionValueCell.h"
#import "XXTEUserInterfaceDefines.h"
#import "XXTEViewShaker.h"

typedef enum : NSUInteger {
    kXXTExplorerCreateItemViewSectionIndexName = 0,
    kXXTExplorerCreateItemViewSectionIndexType,
    kXXTExplorerCreateItemViewSectionIndexMax
} kXXTExplorerCreateItemViewSectionIndex;

typedef enum : NSUInteger {
    kXXTExplorerCreateItemViewItemTypeLUA = 0,
    kXXTExplorerCreateItemViewItemTypeTXT,
    kXXTExplorerCreateItemViewItemTypeFIL,
    kXXTExplorerCreateItemViewItemTypeDIR
} kXXTExplorerCreateItemViewItemType;

@interface XXTExplorerCreateItemViewController () <UITextFieldDelegate>

@property (nonatomic, copy, readonly) NSString *entryPath;
@property (nonatomic, strong) UIBarButtonItem *closeButtonItem;
@property (nonatomic, strong) UIBarButtonItem *doneButtonItem;
@property (nonatomic, strong) UITextField *nameField;
@property (nonatomic, assign) kXXTExplorerCreateItemViewItemType selectedItemType;
@property (nonatomic, strong) XXTEViewShaker *itemNameShaker;

@end

@implementation XXTExplorerCreateItemViewController {
    BOOL isFirstTimeLoaded;
    NSArray <NSMutableArray <UITableViewCell *> *> *staticCells;
    NSArray <NSString *> *staticSectionTitles;
    NSArray <NSString *> *staticSectionFooters;
    NSArray <NSNumber *> *staticSectionRowNum;
}

- (instancetype)init {
    if (self = [super init]) {
        [self setup];
    }
    return self;
}

- (instancetype) initWithStyle:(UITableViewStyle)style {
    if (self = [super initWithStyle:style]) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithEntryPath:(NSString *)entryPath {
    if (self = [super initWithStyle:UITableViewStyleGrouped]) {
        _entryPath = entryPath;
        [self setup];
    }
    return self;
}

- (void)setup {
    
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.clearsSelectionOnViewWillAppear = self.splitViewController.isCollapsed;
    self.title = NSLocalizedString(@"Create Item", nil);
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    
    self.navigationItem.leftBarButtonItem = self.closeButtonItem;
    self.navigationItem.rightBarButtonItem = self.doneButtonItem;
    
    [self reloadStaticTableViewData];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (![self.nameField isFirstResponder]) {
        [self.nameField becomeFirstResponder];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldDidChangeWithNotificaton:) name:UITextFieldTextDidChangeNotification object:self.nameField];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)reloadStaticTableViewData {
    staticSectionTitles = @[ @"", @"" ];
    staticSectionFooters = @[ @"", @"" ];
    
    XXTExplorerItemNameCell *cell1 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTExplorerItemNameCell class]) owner:nil options:nil] lastObject];
    cell1.nameField.delegate = self;
    self.nameField = cell1.nameField;
    self.itemNameShaker = [[XXTEViewShaker alloc] initWithView:self.nameField];
    
    XXTEMoreTitleDescriptionValueCell *cell2 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleDescriptionValueCell class]) owner:nil options:nil] lastObject];
    cell2.accessoryType = UITableViewCellAccessoryNone;
    cell2.titleLabel.text = NSLocalizedString(@"Regular Lua File", nil);
    cell2.descriptionLabel.text = NSLocalizedString(@"A regular lua file from XXTouch template. (text/lua)", nil);
    cell2.valueLabel.text = @"LUA";
    
    XXTEMoreTitleDescriptionValueCell *cell3 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleDescriptionValueCell class]) owner:nil options:nil] lastObject];
    cell3.accessoryType = UITableViewCellAccessoryNone;
    cell3.titleLabel.text = NSLocalizedString(@"Regular Text File", nil);
    cell3.descriptionLabel.text = NSLocalizedString(@"An empty regular text file. (text/plain)", nil);
    cell3.valueLabel.text = @"TXT";
    
    XXTEMoreTitleDescriptionValueCell *cell4 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleDescriptionValueCell class]) owner:nil options:nil] lastObject];
    cell4.accessoryType = UITableViewCellAccessoryNone;
    cell4.titleLabel.text = NSLocalizedString(@"Regular File", nil);
    cell4.descriptionLabel.text = NSLocalizedString(@"An empty regular file.", nil);
    cell4.valueLabel.text = @"FIL";
    
    XXTEMoreTitleDescriptionValueCell *cell5 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleDescriptionValueCell class]) owner:nil options:nil] lastObject];
    cell5.accessoryType = UITableViewCellAccessoryNone;
    cell5.titleLabel.text = NSLocalizedString(@"Directory", nil);
    cell5.descriptionLabel.text = NSLocalizedString(@"A directory with nothing inside.", nil);
    cell5.valueLabel.text = @"DIR";
    
    staticCells = @[
                    @[ cell1 ],
                    @[ cell2, cell3, cell4, cell5 ]
                    ];
}

#pragma mark - UIView Getters

- (UIBarButtonItem *)closeButtonItem {
    if (!_closeButtonItem) {
        UIBarButtonItem *closeButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismissViewController:)];
        closeButtonItem.tintColor = [UIColor whiteColor];
        _closeButtonItem = closeButtonItem;
    }
    return _closeButtonItem;
}

- (UIBarButtonItem *)doneButtonItem {
    if (!_doneButtonItem) {
        UIBarButtonItem *doneButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(submitViewController:)];
        doneButtonItem.tintColor = [UIColor whiteColor];
        doneButtonItem.enabled = NO;
        _doneButtonItem = doneButtonItem;
    }
    return _doneButtonItem;
}

#pragma mark - UITableViewDelegate & UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return kXXTExplorerCreateItemViewSectionIndexMax;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        return staticCells[(NSUInteger) section].count;
    }
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    return [self tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
        if (indexPath.section == kXXTExplorerCreateItemViewSectionIndexName) {
            if (indexPath.row == 0) {
                return 52.f;
            }
        } else if (indexPath.section == kXXTExplorerCreateItemViewSectionIndexType) {
            return 66.f;
        }
    }
    return 44.f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (tableView == self.tableView) {
        if (indexPath.section == kXXTExplorerCreateItemViewSectionIndexType) {
            self.selectedItemType = (NSUInteger) indexPath.row;
            [tableView reloadData];
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
        UITableViewCell *cell = staticCells[(NSUInteger) indexPath.section][(NSUInteger) indexPath.row];
        if (indexPath.section == kXXTExplorerCreateItemViewSectionIndexType) {
            if (indexPath.row == self.selectedItemType) {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            } else {
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
        }
        return cell;
    }
    return [UITableViewCell new];
}

#pragma mark - UIControl Actions

- (void)dismissViewController:(id)sender {
    if ([self.nameField isFirstResponder]) {
        [self.nameField resignFirstResponder];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)submitViewController:(id)sender {
    if ([self.nameField isFirstResponder]) {
        [self.nameField resignFirstResponder];
    }
    if (self.entryPath.length == 0) {
        return;
    }
    NSString *itemName = self.nameField.text;
    if (itemName.length == 0 || [itemName containsString:@"/"] || [itemName containsString:@"\0"]) {
        [self.itemNameShaker shake];
        return;
    }
    if (self.selectedItemType == kXXTExplorerCreateItemViewItemTypeLUA) {
        itemName = [itemName stringByAppendingPathExtension:@"lua"];
    } else if (self.selectedItemType == kXXTExplorerCreateItemViewItemTypeTXT) {
        itemName = [itemName stringByAppendingPathExtension:@"txt"];
    }
    NSFileManager *createItemManager = [[NSFileManager alloc] init];
    NSString *itemPath = [self.entryPath stringByAppendingPathComponent:itemName];
    if ([createItemManager fileExistsAtPath:itemPath]) {
        showUserMessage(self.navigationController.view, [NSString stringWithFormat:NSLocalizedString(@"File \"%@\" already exists.", nil), itemName]);
        [self.itemNameShaker shake];
        return;
    }
    if (self.selectedItemType == kXXTExplorerCreateItemViewItemTypeDIR) {
        NSError *createError = nil;
        BOOL createResult = [createItemManager createDirectoryAtPath:itemPath withIntermediateDirectories:NO attributes:nil error:&createError];
        if (!createResult) {
            showUserMessage(self.navigationController.view, [NSString stringWithFormat:NSLocalizedString(@"Cannot create file \"%@\": %@.", nil), itemName, [createError localizedDescription]]);
            [self.itemNameShaker shake];
            return;
        }
    } else {
        NSData *templateData = [NSData data];
        BOOL createResult = [createItemManager createFileAtPath:itemPath contents:templateData attributes:nil];
        if (!createResult) {
            showUserMessage(self.navigationController.view, [NSString stringWithFormat:NSLocalizedString(@"Cannot create file \"%@\".", nil), itemName]);
            [self.itemNameShaker shake];
            return;
        }
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITextFieldDelegate

//- (void)textFieldDidBeginEditing:(UITextField *)textField {
//    if (textField == self.nameField) {
//        if (textField.text.length == 0) {
//            if (self.selectedItemType == kXXTExplorerCreateItemViewItemTypeLUA) {
//                textField.text = @".lua";
//                self.doneButtonItem.enabled = YES;
//            }
//            else if (self.selectedItemType == kXXTExplorerCreateItemViewItemTypeTXT) {
//                textField.text = @".txt";
//                self.doneButtonItem.enabled = YES;
//            }
//            NSRange range = NSMakeRange(0, 0);
//            UITextPosition *beginning = textField.beginningOfDocument;
//            UITextPosition *start = [textField positionFromPosition:beginning offset:range.location];
//            UITextPosition *end = [textField positionFromPosition:start offset:range.length];
//            UITextRange *textRange = [textField textRangeFromPosition:start toPosition:end];
//            [textField setSelectedTextRange:textRange];
//        }
//    }
//}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (textField == self.nameField) {
        if ([string containsString:@"/"] || [string containsString:@"\0"]) {
            [self.itemNameShaker shake];
            return NO;
        }
        return YES;
    }
    return NO;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.nameField) {
        if ([textField isFirstResponder]) {
            [textField resignFirstResponder];
        }
        return YES;
    }
    return NO;
}

- (void)textFieldDidChangeWithNotificaton:(NSNotification *)aNotification {
    UITextField *textField = (UITextField *)aNotification.object;
    if (textField.text.length > 0) {
        self.doneButtonItem.enabled = YES;
    } else {
        self.doneButtonItem.enabled = NO;
    }
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"[XXTExplorerCreateItemViewController dealloc]");
#endif
}

@end
