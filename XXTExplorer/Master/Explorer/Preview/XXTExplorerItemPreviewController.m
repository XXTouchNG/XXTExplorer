//
//  XXTExplorerItemPreviewController.m
//  XXTExplorer
//
//  Created by Zheng Wu on 2018/2/26.
//  Copyright © 2018年 Zheng. All rights reserved.
//

#import "XXTExplorerItemPreviewController.h"

#import "XXTEAppDefines.h"
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
    XXTExplorerEntryParser *entryParser = [[XXTExplorerEntryParser alloc] init];
    _entryParser = entryParser;
}

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.preferredContentSize = CGSizeMake(300.0, 160.0);
    [self reloadEntryIfNeeded];
}

- (void)reloadEntryIfNeeded {
    NSString *entryPath = self.entryPath;
    if (entryPath)
    {
        NSDictionary *entry = [self.entryParser entryOfPath:entryPath withError:nil];
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

+ (NSDateFormatter *)entryDateFormatter {
    static NSDateFormatter *entryDateFormatter = nil;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        if (!entryDateFormatter) {
            entryDateFormatter = ({
                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
                [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
                dateFormatter;
            });
        }
    });
    return entryDateFormatter;
}

#pragma mark - Setters

- (void)setEntryPath:(NSString *)entryPath {
    _entryPath = entryPath;
    [self reloadEntryIfNeeded];
}

- (void)configureWithEntry:(NSDictionary *)entryDetail {
    if ([entryDetail[XXTExplorerViewEntryAttributeType] isEqualToString:XXTExplorerViewEntryAttributeTypeSymlink] &&
        [entryDetail[XXTExplorerViewEntryAttributeMaskType] isEqualToString:XXTExplorerViewEntryAttributeMaskTypeBrokenSymlink]) {
        // broken symlink
        self.entryTitleLabel.textColor = XXTE_COLOR_DANGER;
        self.entrySubtitleLabel.textColor = XXTE_COLOR_DANGER;
    } else if ([entryDetail[XXTExplorerViewEntryAttributeType] isEqualToString:XXTExplorerViewEntryAttributeTypeSymlink] &&
               ![entryDetail[XXTExplorerViewEntryAttributeMaskType] isEqualToString:XXTExplorerViewEntryAttributeMaskTypeBrokenSymlink]) {
        // symlink
        self.entryTitleLabel.textColor = XXTE_COLOR;
        self.entrySubtitleLabel.textColor = XXTE_COLOR;
    } else {
        self.entryTitleLabel.textColor = [UIColor blackColor];
        self.entrySubtitleLabel.textColor = [UIColor darkGrayColor];
    }
    NSString *entryDisplayName = entryDetail[XXTExplorerViewEntryAttributeDisplayName];
    NSString *readableSize = [NSByteCountFormatter stringFromByteCount:[entryDetail[XXTExplorerViewEntryAttributeSize] longLongValue] countStyle:NSByteCountFormatterCountStyleFile];
    NSString *creationDateString = [self.class.entryDateFormatter stringFromDate:entryDetail[XXTExplorerViewEntryAttributeCreationDate]];
    NSString *modificationDateString = [self.class.entryDateFormatter stringFromDate:entryDetail[XXTExplorerViewEntryAttributeModificationDate]];
    NSString *entryDescriptionFormat = NSLocalizedString(@"%@\n\nCreated at: %@\nModified at: %@", nil);
    NSString *entryDescription = [NSString stringWithFormat:entryDescriptionFormat, readableSize, creationDateString, modificationDateString];
    UIImage *entryIconImage = entryDetail[XXTExplorerViewEntryAttributeIconImage];
    if (entryDetail[XXTExplorerViewEntryAttributeEntryReader]) {
        XXTExplorerEntryReader *entryReader = entryDetail[XXTExplorerViewEntryAttributeEntryReader];
        if (entryReader.entryDisplayName) {
            entryDisplayName = entryReader.entryDisplayName;
        } else {
            if (XXTEDefaultsBool(XXTExplorerViewEntryHideCommonFileExtensionsEnabledKey, YES))
            {
                entryDisplayName = [entryDisplayName stringByDeletingPathExtension];
            }
        }
        if (entryReader.entryDescription) {
            entryDescription = [NSString stringWithFormat:entryDescriptionFormat, entryReader.entryDescription, creationDateString, modificationDateString];
        }
        if (entryReader.entryIconImage) {
            entryIconImage = entryReader.entryIconImage;
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
