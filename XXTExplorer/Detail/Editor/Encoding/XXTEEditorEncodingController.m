//
//  XXTEEditorEncodingController.m
//  XXTExplorer
//
//  Created by Darwin on 8/2/19.
//  Copyright © 2019 Zheng. All rights reserved.
//

#import "XXTEEditorEncodingController.h"
#import "XXTEMoreTitleValueCell.h"
#import "XXTEEditorEncodingHelper.h"
#import <LGAlertView/LGAlertView.h>


@interface XXTEEditorEncodingController ()
@property (nonatomic, strong) UIBarButtonItem *previewItem;
@property (nonatomic, strong) UIBarButtonItem *cancelItem;
@property (nonatomic, strong) UIBarButtonItem *confirmItem;
@property (nonatomic, strong) NSArray <NSNumber *> *arrayOfEncodings;

@end

@implementation XXTEEditorEncodingController

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
    _selectedEncoding = kCFStringEncodingInvalidId;
    _arrayOfEncodings
    = @[
        @(kCFStringEncodingUTF8),
        @(kCFStringEncodingASCII),
        @(kCFStringEncodingISOLatin1),
        @(kCFStringEncodingMacRoman),
        @(kCFStringEncodingWindowsLatin1),
        @(kCFStringEncodingDOSLatin1),
        @(kCFStringEncodingISOLatin3),
        @(kCFStringEncodingISOLatin9),
        @(kCFStringEncodingDOSLatinUS),
        @(kCFStringEncodingISOLatin7),
        @(kCFStringEncodingWindowsBalticRim),
        @(kCFStringEncodingDOSBalticRim),
        @(kCFStringEncodingISOLatin2),
        @(kCFStringEncodingISOLatin4),
        @(kCFStringEncodingMacCentralEurRoman),
        @(kCFStringEncodingWindowsLatin2),
        @(kCFStringEncodingDOSLatin2),
        @(kCFStringEncodingKOI8_R),
        @(kCFStringEncodingISOLatinCyrillic),
        @(kCFStringEncodingMacCyrillic),
        @(kCFStringEncodingWindowsCyrillic),
        @(kCFStringEncodingDOSCyrillic),
        @(kCFStringEncodingISOLatinGreek),
        @(kCFStringEncodingMacGreek),
        @(kCFStringEncodingWindowsGreek),
        @(kCFStringEncodingDOSGreek),
        @(kCFStringEncodingDOSGreek1),
        @(kCFStringEncodingDOSGreek2),
        @(kCFStringEncodingISOLatin6),
        @(kCFStringEncodingDOSNordic),
        @(kCFStringEncodingISOLatin8),
        @(kCFStringEncodingMacCeltic),
        @(kCFStringEncodingISOLatin10),
        @(kCFStringEncodingMacRomanian),
        @(kCFStringEncodingISOLatin5),
        @(kCFStringEncodingMacTurkish),
        @(kCFStringEncodingWindowsLatin5),
        @(kCFStringEncodingDOSTurkish),
        @(kCFStringEncodingShiftJIS),
        @(kCFStringEncodingISO_2022_JP),
        @(kCFStringEncodingISO_2022_JP_1),
        @(kCFStringEncodingISO_2022_JP_2),
        @(kCFStringEncodingISO_2022_JP_3),
        @(kCFStringEncodingEUC_JP),
        @(kCFStringEncodingMacJapanese),
        @(kCFStringEncodingDOSJapanese),
        @(kCFStringEncodingGB_18030_2000),
        @(kCFStringEncodingISO_2022_CN),
        @(kCFStringEncodingISO_2022_CN_EXT),
        @(kCFStringEncodingGB_2312_80),
        @(kCFStringEncodingMacChineseSimp),
        @(kCFStringEncodingDOSChineseSimplif),
        @(kCFStringEncodingBig5),
        @(kCFStringEncodingBig5_HKSCS_1999),
        @(kCFStringEncodingEUC_TW),
        @(kCFStringEncodingMacChineseTrad),
        @(kCFStringEncodingDOSChineseTrad),
        @(kCFStringEncodingEUC_KR),
        @(kCFStringEncodingMacKorean),
        @(kCFStringEncodingWindowsKoreanJohab),
        @(kCFStringEncodingDOSKorean),
        @(kCFStringEncodingMacVietnamese),
        @(kCFStringEncodingWindowsVietnamese),
        @(kCFStringEncodingISOLatinThai),
        @(kCFStringEncodingMacThai),
        @(kCFStringEncodingDOSThai),
        @(kCFStringEncodingISOLatinHebrew),
        @(kCFStringEncodingMacHebrew),
        @(kCFStringEncodingWindowsHebrew),
        @(kCFStringEncodingDOSHebrew),
        @(kCFStringEncodingISOLatinArabic),
        @(kCFStringEncodingMacArabic),
        @(kCFStringEncodingWindowsArabic),
        @(kCFStringEncodingDOSArabic),
        @(kCFStringEncodingUTF16),
        @(kCFStringEncodingUTF16BE),
        @(kCFStringEncodingUTF16LE),
        @(kCFStringEncodingUTF32),
        @(kCFStringEncodingUTF32BE),
        @(kCFStringEncodingUTF32LE),
        @(kCFStringEncodingEBCDIC_US),
        @(kCFStringEncodingEBCDIC_CP037),
        @(kCFStringEncodingNonLossyASCII),
        ];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (!self.title.length) {
        self.title = NSLocalizedString(@"Encoding", nil);
    }
    
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
    if ([self.navigationController.viewControllers firstObject] == self) {
        self.navigationItem.leftBarButtonItem = self.cancelItem;
    }
    if (!self.reopenMode) {
        self.navigationItem.rightBarButtonItem = self.previewItem;
    } else {
        self.navigationItem.rightBarButtonItem = self.confirmItem;
    }
    
    [self.tableView registerNib:[UINib nibWithNibName:@"XXTEMoreTitleValueCell" bundle:nil] forCellReuseIdentifier:XXTEMoreTitleValueCellReuseIdentifier];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.arrayOfEncodings.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44.f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    XXTEMoreTitleValueCell *cell = (XXTEMoreTitleValueCell *)[tableView dequeueReusableCellWithIdentifier:XXTEMoreTitleValueCellReuseIdentifier forIndexPath:indexPath];
    int encoding = [[self.arrayOfEncodings objectAtIndex:indexPath.row] intValue];
    if (encoding == self.selectedEncoding) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    cell.titleLabel.text = [XXTEEditorEncodingHelper encodingNameForEncoding:encoding];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    int encoding = [[self.arrayOfEncodings objectAtIndex:indexPath.row] intValue];
    if (encoding != self.selectedEncoding) {
        XXTEMoreTitleValueCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        if (self.reopenMode) {
            self.selectedEncoding = encoding;
            if ([self.delegate respondsToSelector:@selector(encodingControllerDidChange:)]) {
                [self.delegate encodingControllerDidChange:self];
            }
            [self.tableView reloadData];
        } else {
            @weakify(self);
            LGAlertView *alertView = [LGAlertView alertViewWithTitle:NSLocalizedString(@"Warning", nil) message:[NSString stringWithFormat:NSLocalizedString(@"Will change current text encoding to \"%@\", continue?", nil), cell.titleLabel.text] style:LGAlertViewStyleAlert buttonTitles:nil cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:[NSString stringWithFormat:NSLocalizedString(@"Use \"%@\"", nil), cell.titleLabel.text]
                                                       actionHandler:nil
                                                       cancelHandler:^(LGAlertView * _Nonnull alertView) {
                                                           [alertView dismissAnimated];
                                                       } destructiveHandler:^(LGAlertView * _Nonnull alertView) {
                                                           @strongify(self);
                                                           self.selectedEncoding = encoding;
                                                           if ([self.delegate respondsToSelector:@selector(encodingControllerDidChange:)]) {
                                                               [self.delegate encodingControllerDidChange:self];
                                                           }
                                                           [self.tableView reloadData];
                                                           [alertView dismissAnimated];
                                                       }];
            [alertView showAnimated];
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

- (UIBarButtonItem *)cancelItem {
    if (!_cancelItem) {
        UIBarButtonItem *cancelItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelItemTapped:)];
        _cancelItem = cancelItem;
    }
    return _cancelItem;
}

- (UIBarButtonItem *)confirmItem {
    if (!_confirmItem) {
        UIBarButtonItem *confirmItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(confirmItemTapped:)];
        _confirmItem = confirmItem;
    }
    return _confirmItem;
}

- (void)previewItemTapped:(UIBarButtonItem *)sender {
    if (self.arrayOfEncodings.count == 0) {
        toastMessage(self, NSLocalizedString(@"No encoding available.", nil));
        return;
    }
    NSUInteger idx = 0;
    for (NSNumber *encoding in self.arrayOfEncodings) {
        if (self.selectedEncoding == [encoding intValue]) {
            break;
        }
        idx++;
    }
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:idx inSection:0];
    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
}

- (void)cancelItemTapped:(UIBarButtonItem *)sender {
    if ([_delegate respondsToSelector:@selector(encodingControllerDidCancel:)]) {
        [_delegate encodingControllerDidCancel:self];
    }
}

- (void)confirmItemTapped:(UIBarButtonItem *)sender {
    if ([_delegate respondsToSelector:@selector(encodingControllerDidConfirm:)]) {
        [_delegate encodingControllerDidConfirm:self];
    }
}

@end
