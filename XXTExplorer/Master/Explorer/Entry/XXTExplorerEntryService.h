//
//  XXTExplorerEntryService.h
//  XXTExplorer
//
//  Created by Zheng on 11/06/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol XXTEViewer, XXTEEditor;

@interface XXTExplorerEntryService : NSObject

@property (nonatomic, strong) NSDictionary *bindingDictionary;
@property (nonatomic, strong) NSArray <Class> *registeredViewers;

+ (instancetype)sharedInstance;
- (void)bindExtension:(NSString *)extension toViewer:(NSString *)viewerName;

- (BOOL)hasViewerForEntry:(NSDictionary *)entry;
- (BOOL)hasEditorForEntry:(NSDictionary *)entry;
- (BOOL)hasConfiguratorForEntry:(NSDictionary *)entry;

#pragma mark - Controller Methods

- (UIViewController <XXTEViewer> *)viewerForEntry:(NSDictionary *)entry;
- (UIViewController <XXTEEditor> *)editorForEntry:(NSDictionary *)entry;
- (UIViewController *)configuratorForEntry:(NSDictionary *)entry;
- (UIViewController <XXTEViewer> *)viewerWithName:(NSString *)controllerName forEntryPath:(NSString *)entryPath;

@end
