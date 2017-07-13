//
//  XXTExplorerEntryService.m
//  XXTExplorer
//
//  Created by Zheng on 11/06/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTExplorerEntryService.h"
#import "XXTEAppDefines.h"
#import "XXTExplorerDefaults.h"
#import "XXTEViewer.h"

@interface XXTExplorerEntryService ()

@end

@implementation XXTExplorerEntryService

+ (NSArray <Class> *)registeredViewers {
    static NSArray <Class> *registeredViewers = nil;
    if (!registeredViewers) {
        NSArray <NSString *> *registeredNames = XXTEBuiltInDefaultsObject(@"AVAILABLE_VIEWER");
        NSMutableArray <Class> *registeredMutableViewers = [[NSMutableArray alloc] initWithCapacity:registeredNames.count];
        for (NSString *className in registeredNames) {
            [registeredMutableViewers addObject:NSClassFromString(className)];
        }
        registeredViewers = [[NSArray alloc] initWithArray:registeredMutableViewers];
    }
    return registeredViewers;
}

- (instancetype)init {
    if (self = [super init]) {
        [self setup];
    }
    return self;
}

- (void)setup {
    NSDictionary *bindingDictionary = XXTEDefaultsObject(XXTExplorerViewEntryBindingKey);
    NSMutableDictionary *newBindingDictionary = [[NSMutableDictionary alloc] initWithDictionary:bindingDictionary];
    for (Class registeredViewerClass in self.class.registeredViewers) {
        Class <XXTEViewer> viewerClass = registeredViewerClass;
        NSArray <NSString *> *suggestedExtensions = [viewerClass suggestedExtensions];
        for (NSString *suggestExtension in suggestedExtensions) {
            if (!bindingDictionary[suggestExtension]) { // if no binding, set default binding
                newBindingDictionary[suggestExtension] = NSStringFromClass(viewerClass);
            }
        }
    }
    NSDictionary *saveBindingDictionary = [[NSDictionary alloc] initWithDictionary:newBindingDictionary];
    XXTEDefaultsSetObject(XXTExplorerViewEntryBindingKey, saveBindingDictionary);
}

- (BOOL)hasDefaultViewControllerForEntry:(NSDictionary *)entry {
    NSString *entryBaseExtension = [entry[XXTExplorerViewEntryAttributeExtension] lowercaseString];
    NSDictionary *bindingDictionary = XXTEDefaultsObject(XXTExplorerViewEntryBindingKey);
    if (bindingDictionary[entryBaseExtension]) {
        return YES;
    }
    return NO;
}

- (UIViewController <XXTEViewer> *)viewControllerForEntry:(NSDictionary *)entry {
    NSString *entryPath = entry[XXTExplorerViewEntryAttributePath];
    NSString *entryBaseExtension = [entry[XXTExplorerViewEntryAttributeExtension] lowercaseString];
    NSDictionary *bindingDictionary = XXTEDefaultsObject(XXTExplorerViewEntryBindingKey);
    if (bindingDictionary[entryBaseExtension]) {
        NSString *viewerClassName = bindingDictionary[entryBaseExtension];
        Class viewerClass = NSClassFromString(viewerClassName);
        UIViewController <XXTEViewer> *viewer = [[viewerClass alloc] initWithPath:entryPath];
        return viewer;
    }
    return nil;
}

- (UIViewController *)openInControllerForEntry:(NSDictionary *)entry {
    return nil;
}

@end
