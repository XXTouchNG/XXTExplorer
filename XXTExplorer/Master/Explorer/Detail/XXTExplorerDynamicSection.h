//
//  XXTExplorerDynamicSection.h
//  XXTExplorer
//
//  Created by Zheng on 26/11/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

static NSString * const kXXTEDynamicSectionIdentifierSectionName = @"SectionName";
static NSString * const kXXTEDynamicSectionIdentifierSectionRepeat = @"SectionRepeat";
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
