//
//  XXTExplorerEntryService.h
//  XXTExplorer
//
//  Created by Zheng on 11/06/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol XXTEViewer;

@interface XXTExplorerEntryService : NSObject

@property (nonatomic, strong) NSDictionary *bindingDictionary;
@property (nonatomic, strong) NSArray <Class> *registeredViewers;

+ (instancetype)sharedInstance;
- (void)bindExtension:(NSString *)extension toViewer:(NSString *)viewerName;
- (BOOL)hasViewerForEntry:(NSDictionary *)entry;
- (UIViewController <XXTEViewer> *)viewerForEntry:(NSDictionary *)entry;
- (UIViewController *)openWithControllerForEntry:(NSDictionary *)entry;

@end
