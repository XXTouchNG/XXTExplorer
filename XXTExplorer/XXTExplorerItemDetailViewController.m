//
//  XXTExplorerItemDetailViewController.m
//  XXTExplorer
//
//  Created by Zheng on 10/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <pwd.h>
#import <grp.h>
#import <sys/stat.h>
#import "XXTExplorerItemDetailViewController.h"
#import "XXTExplorerItemNameCell.h"
#import "XXTEMoreTitleDescriptionValueCell.h"
#import "XXTEUserInterfaceDefines.h"
#import "XXTEViewShaker.h"
#import "XXTEAppDefines.h"
#import "XXTEDispatchDefines.h"

#import "XXTExplorerDefaults.h"
#import "XXTEMoreTitleValueCell.h"
#import "XXTEMoreAddressCell.h"
#import "XXTEMoreLinkNoIconCell.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <PromiseKit/PromiseKit.h>
#import "XXTExplorerEntryParser.h"
#import "XXTENotificationCenterDefines.h"
#import "XXTExplorerEntryReader.h"
#import "XXTExplorerEntryBindingViewController.h"
#import "XXTExplorerViewController.h"

#import "XXTEBaseObjectViewController.h"
#import "NSObject+StringValue.h"

static int sizingCancelFlag = 0;

@interface NSFileManager (DeepSize)
- (NSArray *)listItemsInDirectoryAtPath:(NSString *)path deep:(BOOL)deep cancelFlag:(int *)cancelFlag;
- (NSNumber *)sizeOfDirectoryAtPath:(NSString *)path error:(NSError **)error cancelFlag:(int *)cancelFlag;
- (NSNumber *)sizeOfItemAtPath:(NSString *)path error:(NSError **)error;

@end

@implementation NSFileManager (DeepSize)

- (NSArray *)listItemsInDirectoryAtPath:(NSString *)path deep:(BOOL)deep cancelFlag:(int *)cancelFlag
{
    NSString *absolutePath = path;
    NSArray *relativeSubpaths = (deep ? [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:absolutePath error:nil] : [[NSFileManager defaultManager] contentsOfDirectoryAtPath:absolutePath error:nil]);
    
    NSMutableArray *absoluteSubpaths = [[NSMutableArray alloc] init];
    
    for (NSString *relativeSubpath in relativeSubpaths)
    {
        NSString *absoluteSubpath = [absolutePath stringByAppendingPathComponent:relativeSubpath];
        [absoluteSubpaths addObject:absoluteSubpath];
        if (cancelFlag && *cancelFlag != 0) {
            break;
        }
    }
    
    return [NSArray arrayWithArray:absoluteSubpaths];
}

- (NSNumber *)sizeOfDirectoryAtPath:(NSString *)path error:(NSError **)error cancelFlag:(int *)cancelFlag
{
    struct stat fileStat;
    if (0 == lstat([path UTF8String], &fileStat) && S_ISDIR(fileStat.st_mode))
    {
        if ((error == nil) || ((*error) == nil))
        {
            NSNumber *size = [self sizeOfItemAtPath:path error:error];
            double sizeValue = [size doubleValue];
            
            if ((error == nil) || ((*error) == nil))
            {
                NSArray *subpaths = [self listItemsInDirectoryAtPath:path deep:YES cancelFlag:cancelFlag];
                NSUInteger subpathsCount = [subpaths count];
                
                for (NSUInteger i = 0; i < subpathsCount; i++)
                {
                    NSString *subpath = [subpaths objectAtIndex:i];
                    NSNumber *subpathSize = [self sizeOfItemAtPath:subpath error:error];
                    
                    if ((error == nil) || ((*error) == nil))
                    {
                        sizeValue += [subpathSize doubleValue];
                    }
                    else {
                        return nil;
                    }
                    
                    if (cancelFlag && *cancelFlag != 0) {
                        break;
                    }
                }
                
                return [NSNumber numberWithDouble:sizeValue];
            }
        }
    }
    return nil;
}

- (NSNumber *)sizeOfItemAtPath:(NSString *)path error:(NSError **)error
{
    return (NSNumber *)[[self attributesOfItemAtPath:path error:error] objectForKey:NSFileSize];
}

@end

static NSString * const kXXTEDynamicSectionIdentifierSectionName = @"SectionName";
static NSString * const kXXTEDynamicSectionIdentifierSectionWhere = @"SectionWhere";
static NSString * const kXXTEDynamicSectionIdentifierSectionOriginal = @"SectionOriginal";
static NSString * const kXXTEDynamicSectionIdentifierSectionGeneral = @"SectionGeneral";
static NSString * const kXXTEDynamicSectionIdentifierSectionExtended = @"SectionExtended";
static NSString * const kXXTEDynamicSectionIdentifierSectionOwner = @"SectionOwner";
static NSString * const kXXTEDynamicSectionIdentifierSectionPermission = @"SectionPermission";
static NSString * const kXXTEDynamicSectionIdentifierSectionOpenWith = @"SectionOpenWith";

@interface XXTExplorerDynamicSection : NSObject
@property (nonatomic, strong) NSString *identifier;
@property (nonatomic, strong) NSArray <UITableViewCell *> *cells;
@property (nonatomic, strong) NSArray <NSNumber *> *cellHeights;
@property (nonatomic, strong) NSArray *relatedObjects;
@property (nonatomic, strong) NSString *sectionTitle;
@property (nonatomic, strong) NSString *sectionFooter;
@end

@implementation XXTExplorerDynamicSection
@end

@interface XXTExplorerItemDetailViewController () <UITextFieldDelegate, XXTExplorerEntryBindingViewControllerDelegate>

@property (nonatomic, strong) NSDictionary *entry;
@property (nonatomic, strong) NSBundle *entryBundle;

@property (nonatomic, strong) UITextField *nameField;
@property (nonatomic, strong) UIBarButtonItem *closeButtonItem;
@property (nonatomic, strong) UIBarButtonItem *doneButtonItem;
@property (nonatomic, strong) XXTEViewShaker *itemNameShaker;

@property (nonatomic, strong) XXTExplorerEntryParser *entryParser;
@property (nonatomic, strong) NSArray <XXTExplorerDynamicSection *> *dynamicSections;

@end

@implementation XXTExplorerItemDetailViewController {
    BOOL isFirstTimeLoaded;
}

#pragma mark - Default Style

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

#pragma mark - Setup

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

- (instancetype)initWithPath:(NSString *)path {
    if (self = [super initWithStyle:UITableViewStyleGrouped]) {
        XXTExplorerEntryParser *entryParser = [[XXTExplorerEntryParser alloc] init];
        _entryParser = entryParser;
        _entry = [entryParser entryOfPath:path withError:nil];
        [self setup];
    }
    return self;
}

- (void)setup {
    sizingCancelFlag = 0;
}

#pragma mark - View Methods

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.clearsSelectionOnViewWillAppear = self.splitViewController.isCollapsed;
    self.title = NSLocalizedString(@"Item Detail", nil);
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    
    XXTE_START_IGNORE_PARTIAL
    if (XXTE_SYSTEM_9) {
        self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    }
    XXTE_END_IGNORE_PARTIAL
    
    self.navigationItem.leftBarButtonItem = self.closeButtonItem;
    self.navigationItem.rightBarButtonItem = self.doneButtonItem;
    
    [self reloadStaticTableViewData];
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
    // Prepare
    NSDictionary *entry = self.entry;
    if (!entry) return;
    
    NSFileManager *previewManager = [[NSFileManager alloc] init];
    NSMutableArray <XXTExplorerDynamicSection *> *mutableDynamicSections = [[NSMutableArray alloc] init];
    
    id <XXTExplorerEntryReader> entryReader = entry[XXTExplorerViewEntryAttributeEntryReader];
    NSString *entryPath = entry[XXTExplorerViewEntryAttributePath];
    NSString *entryBaseType = entry[XXTExplorerViewEntryAttributeType];
    BOOL entryReadable = [previewManager isReadableFileAtPath:entryPath];
    BOOL entryRegular = [entryBaseType isEqualToString:XXTExplorerViewEntryAttributeTypeRegular];
    BOOL entryDirectory = [entryBaseType isEqualToString:XXTExplorerViewEntryAttributeTypeDirectory];
    BOOL entrySymlink = [entryBaseType isEqualToString:XXTExplorerViewEntryAttributeTypeSymlink];
    NSString *entryMaskType = entry[XXTExplorerViewEntryAttributeMaskType];
    BOOL entryMaskBundle = [entryMaskType isEqualToString:XXTExplorerViewEntryAttributeMaskTypeBundle];
    BOOL entryMaskBrokenSymlink = [entryMaskType isEqualToString:XXTExplorerViewEntryAttributeMaskTypeBrokenSymlink];
    
    NSBundle *entryBundle = nil;
    if (entryMaskBundle)
        entryBundle = [NSBundle bundleWithPath:entryPath];
    entryBundle = (entryBundle != nil) ? entryBundle : [NSBundle mainBundle];
    self.entryBundle = entryBundle;
    
    struct stat entryStat;
    if (lstat([entryPath UTF8String], &entryStat) != 0) return;
    
    // #1 - Name (Required)
    {
        XXTExplorerItemNameCell *cell1 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTExplorerItemNameCell class]) owner:nil options:nil] lastObject];
        cell1.nameField.delegate = self;
        cell1.nameField.text = entry[XXTExplorerViewEntryAttributeName];
        self.nameField = cell1.nameField;
        self.itemNameShaker = [[XXTEViewShaker alloc] initWithView:self.nameField];
        
        XXTExplorerDynamicSection *section1 = [[XXTExplorerDynamicSection alloc] init];
        section1.identifier = kXXTEDynamicSectionIdentifierSectionName;
        section1.cells = @[ cell1 ];
        section1.cellHeights = @[ @(50.f) ];
        section1.sectionTitle = NSLocalizedString(@"Filename", nil);
        section1.sectionFooter = NSLocalizedString(@"Tap to edit filename.", nil);
        
        [mutableDynamicSections addObject:section1];
    }
    
    // #2.1 - Where (Required)
    
    {
        XXTEMoreAddressCell *cell2 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreAddressCell class]) owner:nil options:nil] lastObject];
        cell2.addressLabel.text = entryPath;
        
        XXTExplorerDynamicSection *section2 = [[XXTExplorerDynamicSection alloc] init];
        section2.identifier = kXXTEDynamicSectionIdentifierSectionWhere;
        section2.cells = @[ cell2 ];
        section2.cellHeights = @[ @(-1) ];
        section2.sectionTitle = NSLocalizedString(@"Where", nil);
        section2.sectionFooter = @"";
        
        [mutableDynamicSections addObject:section2];
    }
    
    // #3 - Original (Correct Symbolic Link)
    
    if (entrySymlink && !entryMaskBrokenSymlink)
    {
        NSError *originalError = nil;
        NSString *originalPath = [previewManager destinationOfSymbolicLinkAtPath:entryPath error:&originalError];
        
        if (originalPath) {
            XXTEMoreAddressCell *cell3 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreAddressCell class]) owner:nil options:nil] lastObject];
            cell3.addressLabel.text = originalPath;
            
            XXTExplorerDynamicSection *section3 = [[XXTExplorerDynamicSection alloc] init];
            section3.identifier = kXXTEDynamicSectionIdentifierSectionOriginal;
            section3.cells = @[ cell3 ];
            section3.cellHeights = @[ @(-1) ];
            section3.sectionTitle = NSLocalizedString(@"Original", nil);
            section3.sectionFooter = @"";
            
            [mutableDynamicSections addObject:section3];
        }
        
    }
    
    // #4 - General (Required)
    
    {
        NSDateFormatter *previewFormatter = [[NSDateFormatter alloc] init];
        [previewFormatter setTimeStyle:NSDateFormatterLongStyle];
        [previewFormatter setDateStyle:NSDateFormatterFullStyle];
        
        NSMutableArray <UITableViewCell *> *sectionCells1 = [[NSMutableArray alloc] init];
        NSMutableArray <NSNumber *> *sectionHeights1 = [[NSMutableArray alloc] init];
        
        {
            XXTEMoreTitleValueCell *cell4 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
            cell4.titleLabel.text = NSLocalizedString(@"Kind", nil);
            cell4.valueLabel.lineBreakMode = NSLineBreakByWordWrapping;
            
            NSString *entryExtensionDescription = nil;
            if (entryRegular)
                entryExtensionDescription = NSLocalizedString(@"Regular File", nil);
            else if (entryDirectory)
                entryExtensionDescription = NSLocalizedString(@"Directory", nil);
            else if (entrySymlink)
                entryExtensionDescription = NSLocalizedString(@"Symbolic Link", nil);
            else
                entryExtensionDescription = NSLocalizedString(@"Unknown", nil);
            if (!entrySymlink && (entryRegular || entryMaskBundle) && [entryReader entryExtensionDescription])
                entryExtensionDescription = NSLocalizedString(entryReader.entryExtensionDescription, nil);
            
            if (entryRegular && entryReadable)
            {
                NSString *MIMEString = @"application/octet-stream";
                CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)entry[XXTExplorerViewEntryAttributeExtension], NULL);
                CFStringRef MIMEType = UTTypeCopyPreferredTagWithClass(UTI, kUTTagClassMIMEType);
                if (UTI) CFRelease(UTI);
                if (MIMEType != NULL) {
                    MIMEString = (__bridge NSString *)(MIMEType);
                    CFRelease(MIMEType);
                }
                cell4.valueLabel.text = [NSString stringWithFormat:@"%@\n(%@)", entryExtensionDescription, MIMEString];
            } else {
                cell4.valueLabel.text = entryExtensionDescription;
            }
            
            [sectionCells1 addObject:cell4];
            [sectionHeights1 addObject:@(-1)];
        }
        
        {
            XXTEMoreTitleValueCell *cell5 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
            cell5.titleLabel.text = NSLocalizedString(@"Size", nil);
            cell5.valueLabel.lineBreakMode = NSLineBreakByWordWrapping;
            
            if (entryDirectory)
            { // Async Sizing
                cell5.valueLabel.text = NSLocalizedString(@"Calculating...\n", nil);
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                    NSError *sizingError = nil;
                    NSFileManager *sizingManager = [[NSFileManager alloc] init];
                    NSNumber *itemSize = [sizingManager sizeOfDirectoryAtPath:entryPath error:&sizingError cancelFlag:&sizingCancelFlag];
                    dispatch_async_on_main_queue(^{
                        if (!sizingError && itemSize) {
                            cell5.valueLabel.text = [self formattedSizeLabelText:itemSize];
                        }
                        [self.tableView reloadData];
                    });
                });
            }
            else
            {
                NSNumber *entrySize = entry[XXTExplorerViewEntryAttributeSize];
                cell5.valueLabel.text = [self formattedSizeLabelText:entrySize];
            }
            
            [sectionCells1 addObject:cell5];
            [sectionHeights1 addObject:@(-1)];
        }
        
        {
            NSDate *entryCreationDate = entry[XXTExplorerViewEntryAttributeCreationDate];
            XXTEMoreTitleValueCell *cell6 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
            cell6.titleLabel.text = NSLocalizedString(@"Created At", nil);
            cell6.valueLabel.lineBreakMode = NSLineBreakByWordWrapping;
            cell6.valueLabel.text = [previewFormatter stringFromDate:entryCreationDate];
            
            [sectionCells1 addObject:cell6];
            [sectionHeights1 addObject:@(-1)];
        }
        
        {
            NSDate *entryModificationDate = entry[XXTExplorerViewEntryAttributeModificationDate];
            XXTEMoreTitleValueCell *cell7 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
            cell7.titleLabel.text = NSLocalizedString(@"Modified At", nil);
            cell7.valueLabel.lineBreakMode = NSLineBreakByWordWrapping;
            cell7.valueLabel.text = [previewFormatter stringFromDate:entryModificationDate];
            
            [sectionCells1 addObject:cell7];
            [sectionHeights1 addObject:@(-1)];
        }
    
        XXTExplorerDynamicSection *section4 = [[XXTExplorerDynamicSection alloc] init];
        section4.identifier = kXXTEDynamicSectionIdentifierSectionGeneral;
        section4.cells = [[NSArray alloc] initWithArray:sectionCells1];
        section4.cellHeights = [[NSArray alloc] initWithArray:sectionHeights1];
        section4.sectionTitle = NSLocalizedString(@"General", nil);
        section4.sectionFooter = @"";
        
        [mutableDynamicSections addObject:section4];
        
    }
    
    // #5 - Extended
    if (!entrySymlink)
    {
        NSMutableArray <UITableViewCell *> *extendedCells = [[NSMutableArray alloc] init];
        NSMutableArray <NSNumber *> *extendedHeights = [[NSMutableArray alloc] init];
        NSMutableArray *extendedObjects = [[NSMutableArray alloc] init];
        if (entryReader &&
            entryReader.metaDictionary &&
            entryReader.displayMetaKeys) {
            
            NSArray <Class> *supportedTypes = [XXTEBaseObjectViewController supportedTypes];
            NSDictionary *extendedDictionary = entryReader.metaDictionary;
            NSArray <NSString *> *displayExtendedKeys = entryReader.displayMetaKeys;
            
            for (NSString *extendedKey in displayExtendedKeys)
            {
                id extendedValue = extendedDictionary[extendedKey];
                
                Class valueClass = [extendedValue class];
                BOOL supportedValue = NO;
                for (Class supportedType in supportedTypes) {
                    if ([valueClass isSubclassOfClass:supportedType]) {
                        supportedValue = YES;
                        break;
                    }
                }
                if (supportedValue)
                {
                    XXTEMoreTitleValueCell *cell = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
                    cell.titleLabel.text = [entryBundle localizedStringForKey:(extendedKey) value:@"" table:(@"Meta")];
                    cell.accessoryType = UITableViewCellAccessoryNone;
                    cell.valueLabel.text = [extendedValue stringValue];
                    
                    [extendedCells addObject:cell];
                    [extendedHeights addObject:@(-1)];
                    [extendedObjects addObject:[NSNull null]];
                }
                else
                {
                    XXTEMoreLinkNoIconCell *cell = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreLinkNoIconCell class]) owner:nil options:nil] lastObject];
                    cell.titleLabel.text = [entryBundle localizedStringForKey:(extendedKey) value:@"" table:(@"Meta")];
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    
                    [extendedCells addObject:cell];
                    [extendedHeights addObject:@(-1)];
                    [extendedObjects addObject:extendedValue];
                }
                
            }
        }
        
        if (extendedCells.count > 0) {
            XXTExplorerDynamicSection *section5 = [[XXTExplorerDynamicSection alloc] init];
            section5.identifier = kXXTEDynamicSectionIdentifierSectionExtended;
            section5.cells = [[NSArray alloc] initWithArray:extendedCells];
            section5.cellHeights = [[NSArray alloc] initWithArray:extendedHeights];
            section5.relatedObjects = [[NSArray alloc] initWithArray:extendedObjects];
            section5.sectionTitle = NSLocalizedString(@"Extended", nil);
            section5.sectionFooter = @"";
            
            [mutableDynamicSections addObject:section5];
        }
        
    }
    
    // #6 - Owner
    
    {
        struct passwd *entryPWInfo = getpwuid(entryStat.st_uid);
        struct group *entryGRInfo = getgrgid(entryStat.st_gid);
        if (entryPWInfo != NULL && entryGRInfo != NULL) {
            XXTEMoreTitleValueCell *cell7 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
            cell7.titleLabel.text = NSLocalizedString(@"Owner", nil);
            cell7.valueLabel.lineBreakMode = NSLineBreakByWordWrapping;
            cell7.valueLabel.text = [[NSString alloc] initWithUTF8String:entryPWInfo->pw_name];
            
            XXTEMoreTitleValueCell *cell8 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
            cell8.titleLabel.text = NSLocalizedString(@"Group", nil);
            cell8.valueLabel.lineBreakMode = NSLineBreakByWordWrapping;
            cell8.valueLabel.text = [[NSString alloc] initWithUTF8String:entryGRInfo->gr_name];
            
            XXTExplorerDynamicSection *section6 = [[XXTExplorerDynamicSection alloc] init];
            section6.identifier = kXXTEDynamicSectionIdentifierSectionOwner;
            section6.cells = @[ cell7, cell8 ];
            section6.cellHeights = @[ @(-1), @(-1) ];
            section6.sectionTitle = NSLocalizedString(@"Owner", nil);
            section6.sectionFooter = @"";
            
            [mutableDynamicSections addObject:section6];
        }
    }
    
    // #7 - Perimssion
    
    {
        NSString *userReadFlag = (entryStat.st_mode & S_IRUSR) ? @"r" : @"-";
        NSString *userWriteFlag = (entryStat.st_mode & S_IWUSR) ? @"w" : @"-";
        NSString *userExecuteFlag = (entryStat.st_mode & S_IXUSR) ? @"x" : @"-";
        
        NSString *groupReadFlag = (entryStat.st_mode & S_IRGRP) ? @"r" : @"-";
        NSString *groupWriteFlag = (entryStat.st_mode & S_IWGRP) ? @"w" : @"-";
        NSString *groupExecuteFlag = (entryStat.st_mode & S_IXGRP) ? @"x" : @"-";
        
        NSString *otherReadFlag = (entryStat.st_mode & S_IROTH) ? @"r" : @"-";
        NSString *otherWriteFlag = (entryStat.st_mode & S_IWOTH) ? @"w" : @"-";
        NSString *otherExecuteFlag = (entryStat.st_mode & S_IXOTH) ? @"x" : @"-";
        
        XXTEMoreTitleValueCell *cell9 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
        cell9.titleLabel.text = NSLocalizedString(@"Owner", nil);
        cell9.valueLabel.lineBreakMode = NSLineBreakByWordWrapping;
        cell9.valueLabel.font = [UIFont fontWithName:@"CourierNewPSMT" size:17.f];
        cell9.valueLabel.text = [NSString stringWithFormat:@"%@%@%@", userReadFlag, userWriteFlag, userExecuteFlag];
        
        XXTEMoreTitleValueCell *cell10 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
        cell10.titleLabel.text = NSLocalizedString(@"Group", nil);
        cell10.valueLabel.lineBreakMode = NSLineBreakByWordWrapping;
        cell10.valueLabel.font = [UIFont fontWithName:@"CourierNewPSMT" size:17.f];
        cell10.valueLabel.text = [NSString stringWithFormat:@"%@%@%@", groupReadFlag, groupWriteFlag, groupExecuteFlag];
        
        XXTEMoreTitleValueCell *cell11 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
        cell11.titleLabel.text = NSLocalizedString(@"Everyone", nil);
        cell11.valueLabel.lineBreakMode = NSLineBreakByWordWrapping;
        cell11.valueLabel.font = [UIFont fontWithName:@"CourierNewPSMT" size:17.f];
        cell11.valueLabel.text = [NSString stringWithFormat:@"%@%@%@", otherReadFlag, otherWriteFlag, otherExecuteFlag];
        
        XXTExplorerDynamicSection *section7 = [[XXTExplorerDynamicSection alloc] init];
        section7.identifier = kXXTEDynamicSectionIdentifierSectionPermission;
        section7.cells = @[ cell9, cell10, cell11/*, cell12*/ ];
        section7.cellHeights = @[ @(-1), @(-1), @(-1)/*, @(-1)*/ ];
        section7.sectionTitle = NSLocalizedString(@"Permission", nil);
        section7.sectionFooter = @"";
        
        [mutableDynamicSections addObject:section7];
    }
    
    // #8 - Open with
    
    
    if (entryRegular)
    {
        NSString *entryExtension = entry[XXTExplorerViewEntryAttributeExtension];
        if (entryExtension.length > 0) {
            NSString *enteyViewerDescription = nil;
            if (entryReader.entryViewerDescription)
                enteyViewerDescription = NSLocalizedString(entryReader.entryViewerDescription, nil);
            else
                enteyViewerDescription = NSLocalizedString(@"None", nil);
            
            XXTEMoreTitleValueCell *cell13 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
            cell13.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell13.titleLabel.text = NSLocalizedString(@"Open with...", nil);
            cell13.valueLabel.lineBreakMode = NSLineBreakByWordWrapping;
            cell13.valueLabel.text = enteyViewerDescription;
            
            XXTExplorerDynamicSection *section8 = [[XXTExplorerDynamicSection alloc] init];
            section8.identifier = kXXTEDynamicSectionIdentifierSectionOpenWith;
            section8.cells = @[ cell13 ];
            section8.cellHeights = @[ @(-1), @(-1), @(-1), @(-1) ];
            section8.sectionTitle = NSLocalizedString(@"Open With", nil);
            section8.sectionFooter = NSLocalizedString(@"Use this viewer to open all documents like this one.", nil);
            
            [mutableDynamicSections addObject:section8];
        }
    }
    
    self.dynamicSections = [[NSArray alloc] initWithArray:mutableDynamicSections];
    
}

- (NSString *)formattedSizeLabelText:(NSNumber *)size {
    NSInteger byteCount = [size integerValue];
    NSString *readableSize = [NSByteCountFormatter stringFromByteCount:byteCount countStyle:NSByteCountFormatterCountStyleFile];
    NSByteCountFormatter *countFormatter = [[NSByteCountFormatter alloc] init];
    countFormatter.allowedUnits = NSByteCountFormatterUseBytes;
    NSString *readableSizeInBytes = [countFormatter stringFromByteCount:byteCount];
    return [NSString stringWithFormat:NSLocalizedString(@"%@\n(%@ on disk)", nil), readableSizeInBytes, readableSize];
}

#pragma mark - UIView Getters

- (UIBarButtonItem *)closeButtonItem {
    if (!_closeButtonItem) {
        UIBarButtonItem *closeButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", nil) style:UIBarButtonItemStylePlain target:self action:@selector(dismissViewController:)];
        closeButtonItem.tintColor = [UIColor whiteColor];
        _closeButtonItem = closeButtonItem;
    }
    return _closeButtonItem;
}

- (UIBarButtonItem *)doneButtonItem {
    if (!_doneButtonItem) {
        UIBarButtonItem *doneButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Rename", nil) style:UIBarButtonItemStyleDone target:self action:@selector(submitViewController:)];
        doneButtonItem.tintColor = [UIColor whiteColor];
        doneButtonItem.enabled = NO;
        _doneButtonItem = doneButtonItem;
    }
    return _doneButtonItem;
}

#pragma mark - UIControl Actions

- (void)dismissViewController:(id)sender {
    if ([self.nameField isFirstResponder]) {
        [self.nameField resignFirstResponder];
    }
    sizingCancelFlag = 1;
    if (XXTE_PAD) {
        [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:XXTENotificationEvent object:self userInfo:@{XXTENotificationEventType: XXTENotificationEventTypeFormSheetDismissed}]];
    }
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)submitViewController:(id)sender {
    if ([self.nameField isFirstResponder]) {
        [self.nameField resignFirstResponder];
    }
    NSFileManager *renameManager = [[NSFileManager alloc] init];
    NSDictionary *entry = self.entry;
    NSString *entryPath = entry[XXTExplorerViewEntryAttributePath];
    NSString *entryParentPath = [entryPath stringByDeletingLastPathComponent];
    if (entryParentPath.length == 0) {
        return;
    }
    BOOL isDirectory = NO;
    BOOL parentExists = [renameManager fileExistsAtPath:entryParentPath isDirectory:&isDirectory];
    if (!parentExists || !isDirectory) {
        return;
    }
    NSString *itemName = self.nameField.text;
    if (itemName.length == 0 || [itemName containsString:@"/"] || [itemName containsString:@"\0"]) {
        [self.itemNameShaker shake];
        return;
    }
    struct stat itemStat;
    NSString *itemPath = [entryParentPath stringByAppendingPathComponent:itemName];
    if (/* [renameManager fileExistsAtPath:itemPath] */ 0 == lstat([itemPath UTF8String], &itemStat)) {
        showUserMessage(self, [NSString stringWithFormat:NSLocalizedString(@"File \"%@\" already exists.", nil), itemName]);
        [self.itemNameShaker shake];
        return;
    }
    blockUserInteractions(self, YES, 0.2);
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
    }].then(^(id renameResult) {
        
    }).catch(^(NSError *systemError) {
        showUserMessage(self, [systemError localizedDescription]);
    }).finally(^() {
        blockUserInteractions(self, NO, 0.2);
        sizingCancelFlag = 1;
        if (XXTE_PAD) {
            [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:XXTENotificationEvent object:self userInfo:@{XXTENotificationEventType: XXTENotificationEventTypeFormSheetDismissed}]];
        }
        [self dismissViewControllerAnimated:YES completion:^{
            
        }];
    });
}

#pragma mark - UITableViewDelegate & UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.dynamicSections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        return self.dynamicSections[(NSUInteger) section].cells.count;
    }
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    return [self tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
        CGFloat storedHeight = [self.dynamicSections[indexPath.section].cellHeights[indexPath.row] floatValue];
        if (storedHeight < 0)
            storedHeight = UITableViewAutomaticDimension;
        return storedHeight;
    }
    return 44.f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (tableView == self.tableView) {
        NSString *sectionIdentifier = self.dynamicSections[indexPath.section].identifier;
        UITableViewCell *cell = self.dynamicSections[indexPath.section].cells[indexPath.row];
        if ([sectionIdentifier isEqualToString:kXXTEDynamicSectionIdentifierSectionOpenWith]) {
            if (indexPath.row == 0) {
                NSDictionary *entry = self.entry;
                if ([entry[XXTExplorerViewEntryAttributeMaskType] isEqualToString:XXTExplorerViewEntryAttributeTypeRegular] ||
                    [entry[XXTExplorerViewEntryAttributeMaskType] isEqualToString:XXTExplorerViewEntryAttributeMaskTypeBundle]) {
                    XXTExplorerEntryBindingViewController *bindingViewController = [[XXTExplorerEntryBindingViewController alloc] initWithEntry:entry];
                    bindingViewController.delegate = self;
                    [self.navigationController pushViewController:bindingViewController animated:YES];
                }
            }
        }
        else if ([cell isKindOfClass:[XXTEMoreLinkNoIconCell class]] &&
                 [sectionIdentifier isEqualToString:kXXTEDynamicSectionIdentifierSectionExtended]) {
            id relatedObject = self.dynamicSections[indexPath.section].relatedObjects[indexPath.row];
            XXTEObjectViewController *objectViewController = [[XXTEObjectViewController alloc] initWithRootObject:relatedObject];
            objectViewController.entryBundle = self.entryBundle;
            objectViewController.title = ((XXTEMoreLinkNoIconCell *)cell).titleLabel.text;
            [self.navigationController pushViewController:objectViewController animated:YES];
        }
        else if ([cell isKindOfClass:[XXTEMoreTitleValueCell class]]) {
            NSString *detailText = ((XXTEMoreTitleValueCell *)cell).valueLabel.text;
            if (detailText && detailText.length > 0) {
                blockUserInteractions(self, YES, 0.2);
                [PMKPromise new:^(PMKFulfiller fulfill, PMKRejecter reject) {
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                        [[UIPasteboard generalPasteboard] setString:detailText];
                        fulfill(nil);
                    });
                }].finally(^() {
                    showUserMessage(self, NSLocalizedString(@"Copied to the pasteboard.", nil));
                    blockUserInteractions(self, NO, 0.2);
                });
            }
        }
        else if ([cell isKindOfClass:[XXTEMoreAddressCell class]]) {
            NSString *detailText = ((XXTEMoreAddressCell *)cell).addressLabel.text;
            if (detailText && detailText.length > 0) {
                blockUserInteractions(self, YES, 0.2);
                [PMKPromise new:^(PMKFulfiller fulfill, PMKRejecter reject) {
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                        [[UIPasteboard generalPasteboard] setString:detailText];
                        fulfill(nil);
                    });
                }].finally(^() {
                    showUserMessage(self, NSLocalizedString(@"Path has been copied to the pasteboard.", nil));
                    blockUserInteractions(self, NO, 0.2);
                });
            }
        }
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        return self.dynamicSections[(NSUInteger) section].sectionTitle;
    }
    return @"";
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        return self.dynamicSections[(NSUInteger) section].sectionFooter;
    }
    return @"";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
        UITableViewCell *cell = self.dynamicSections[(NSUInteger) indexPath.section].cells[(NSUInteger) indexPath.row];
        return cell;
    }
    return [UITableViewCell new];
}

#pragma mark - UITextFieldDelegate

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
        if ([textField.text isEqualToString:self.entry[XXTExplorerViewEntryAttributeName]]) {
            self.doneButtonItem.enabled = NO;
        } else {
            self.doneButtonItem.enabled = YES;
        }
    } else {
        self.doneButtonItem.enabled = NO;
    }
}

#pragma mark - XXTExplorerEntryBindingViewControllerDelegate

- (void)bindingViewController:(XXTExplorerEntryBindingViewController *)controller
            bindingDidChanged:(NSString *)controllerName {
    NSString *entryPath = self.entry[XXTExplorerViewEntryAttributePath];
    self.entry = [self.entryParser entryOfPath:entryPath withError:nil];
    [self reloadStaticTableViewData];
    [self.tableView reloadData];
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"[XXTExplorerItemDetailViewController dealloc]");
#endif
}

@end
