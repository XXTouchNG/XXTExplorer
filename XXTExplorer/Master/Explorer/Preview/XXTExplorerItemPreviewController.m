//
//  XXTExplorerItemPreviewController.m
//  XXTExplorer
//
//  Created by Zheng Wu on 2018/2/26.
//  Copyright © 2018年 Zheng. All rights reserved.
//

#import "XXTExplorerItemPreviewController.h"

#import "XXTExplorerDefaults.h"

#import "XXTExplorerEntryReader.h"
#import "XXTExplorerEntryParser.h"

@interface XXTExplorerItemPreviewController ()

@property (weak, nonatomic) IBOutlet UIImageView *entryIconImageView;
@property (weak, nonatomic) IBOutlet UILabel *entryTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *entrySubtitleLabel;

@property (nonatomic, strong) XXTExplorerEntryParser *entryParser;

@end

@implementation XXTExplorerItemPreviewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    if (@available(iOS 13.0, *)) {
        self.entryTitleLabel.textColor = [UIColor labelColor];
        self.entrySubtitleLabel.textColor = [UIColor secondaryLabelColor];
    } else {
        self.entryTitleLabel.textColor = [UIColor blackColor];
        self.entrySubtitleLabel.textColor = [UIColor darkGrayColor];
    }
    
    XXTExplorerEntryParser *entryParser = [[XXTExplorerEntryParser alloc] init];
    _entryParser = entryParser;
}

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = XXTColorPlainBackground();
    self.view.tintColor = XXTColorForeground();
    
    self.preferredContentSize = CGSizeMake(300.0, 160.0);
    [self reloadEntryIfNeeded];
}

- (void)reloadEntryIfNeeded {
    NSString *entryPath = self.entryPath;
    if (entryPath)
    {
        XXTExplorerEntry *entry = [self.entryParser entryOfPath:entryPath withError:nil];
        [self configureWithEntry:entry];
        _entry = entry;
    }
}

#pragma mark - Getters

- (NSArray <id <UIPreviewActionItem>> *)previewActionItems {
    if ([_previewActionDelegate respondsToSelector:@selector(itemPreviewController:previewActionsForEntry:)]) {
        return [_previewActionDelegate itemPreviewController:self previewActionsForEntry:self.entry];
    }
    return @[];
}

#pragma mark - Setters

- (void)setEntryPath:(NSString *)entryPath {
    _entryPath = entryPath;
    [self reloadEntryIfNeeded];
}

- (void)configureWithEntry:(XXTExplorerEntry *)entryDetail {
    if (entryDetail.isBrokenSymlink) {
        // broken symlink
        self.entryTitleLabel.textColor = XXTColorDanger();
        self.entrySubtitleLabel.textColor = XXTColorDanger();
    } else if (entryDetail.isSymlink) {
        // symlink
        self.entryTitleLabel.textColor = XXTColorForeground();
        self.entrySubtitleLabel.textColor = XXTColorForeground();
    } else {
        self.entryTitleLabel.textColor = XXTColorPlainTitleText();
        self.entrySubtitleLabel.textColor = XXTColorPlainSubtitleText();
    }
    NSString *entryDisplayName = [entryDetail localizedDisplayName];
    NSString *readableSize = [entryDetail localizedStringOfEntrySize];
    NSString *creationDateString = [entryDetail localizedStringOfCreationDate];
    NSString *modificationDateString = [entryDetail localizedStringOfModificationDate];
    NSString *entryDescriptionFormat = NSLocalizedString(@"%@\n\nCreated at: %@\nModified at: %@", nil);
    NSString *entryDescription = [NSString stringWithFormat:entryDescriptionFormat, readableSize, creationDateString, modificationDateString];
    UIImage *entryIconImage = [entryDetail localizedDisplayIconImage];
    if (entryDetail.isRegistered) {
        XXTExplorerEntryReader *entryReader = entryDetail.entryReader;
        if (entryReader.entryDescription) {
            entryDescription = [NSString stringWithFormat:entryDescriptionFormat, entryReader.entryDescription, creationDateString, modificationDateString];
        }
    }
    self.entryTitleLabel.text = entryDisplayName;
    self.entrySubtitleLabel.text = entryDescription;
    self.entryIconImageView.image = entryIconImage;
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [%@ dealloc]", NSStringFromClass([self class]));
#endif
}

@end
