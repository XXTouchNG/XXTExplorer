//
//  XXTEEditorLineBreakController.m
//  XXTouch
//
//  Created by Darwin on 8/3/19.
//  Copyright © 2019 Zheng. All rights reserved.
//

#import "XXTEEditorLineBreakController.h"
#import "XXTEMoreTitleValueCell.h"
#import <LGAlertView/LGAlertView.h>
#import "XXTEEditorLineBreakHelper.h"

@interface XXTEEditorLineBreakController ()
@property (nonatomic, strong) NSArray <NSNumber *> *arrayOfTypes;

@end

@implementation XXTEEditorLineBreakController

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
    _selectedLineBreakType = NSStringLineBreakTypeLF;
    _arrayOfTypes
    = @[
        @(NSStringLineBreakTypeLF),
        @(NSStringLineBreakTypeCRLF),
        @(NSStringLineBreakTypeCR),
        ];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if (self.tableView.style == UITableViewStylePlain) {
        self.view.backgroundColor = XXTColorPlainBackground();
    } else {
        self.view.backgroundColor = XXTColorGroupedBackground();
    }
    
    if (!self.title.length) {
        self.title = NSLocalizedString(@"Line Endings", nil);
    }
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    XXTE_START_IGNORE_PARTIAL
    self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    XXTE_END_IGNORE_PARTIAL
    
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    [self.tableView registerNib:[UINib nibWithNibName:@"XXTEMoreTitleValueCell" bundle:nil] forCellReuseIdentifier:XXTEMoreTitleValueCellReuseIdentifier];
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.arrayOfTypes.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44.f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    XXTEMoreTitleValueCell *cell = (XXTEMoreTitleValueCell *)[tableView dequeueReusableCellWithIdentifier:XXTEMoreTitleValueCellReuseIdentifier forIndexPath:indexPath];
    NSNumber *type = self.arrayOfTypes[indexPath.row];
    NSStringLineBreakType typeVal = [type intValue];
    if (typeVal == self.selectedLineBreakType) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    cell.titleLabel.text = [XXTEEditorLineBreakHelper lineBreakNameForType:typeVal];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSNumber *type = self.arrayOfTypes[indexPath.row];
    NSStringLineBreakType typeVal = [type intValue];
    if (typeVal != self.selectedLineBreakType) {
        XXTEMoreTitleValueCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        
        BOOL canSave = NO;
        if ([self.delegate respondsToSelector:@selector(linebreakControllerCanSaveDocument:)]) {
            canSave = [self.delegate linebreakControllerCanSaveDocument:self];
        }
        
        if (canSave) {
            @weakify(self);
            LGAlertView *alertView = [LGAlertView alertViewWithTitle:NSLocalizedString(@"Warning", nil) message:[NSString stringWithFormat:NSLocalizedString(@"Will change current line endings to \"%@\", continue?", nil), cell.titleLabel.text] style:LGAlertViewStyleAlert buttonTitles:nil cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:NSLocalizedString(@"Save Document", nil)
                                                       actionHandler:nil
                                                       cancelHandler:^(LGAlertView * _Nonnull alertView) {
                                                           [alertView dismissAnimated];
                                                       } destructiveHandler:^(LGAlertView * _Nonnull alertView) {
                                                           @strongify(self);
                                                           self.selectedLineBreakType = typeVal;
                                                           if ([self.delegate respondsToSelector:@selector(linebreakControllerDidChange:shouldSave:)]) {
                                                               [self.delegate linebreakControllerDidChange:self shouldSave:YES];
                                                           }
                                                           [self.tableView reloadData];
                                                           [alertView dismissAnimated];
                                                       }];
            [alertView showAnimated];
        } else {
            toastMessage(self, NSLocalizedString(@"Cannot change line endings: Document is read-only.", nil));
        }
    }
}

@end
