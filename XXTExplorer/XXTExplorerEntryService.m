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

+ (instancetype)sharedInstance {
    static XXTExplorerEntryService *sharedInstance = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    if (self = [super init]) {
        [self setup];
    }
    return self;
}

- (void)setup {
    
}

- (NSArray <Class> *)registeredViewers {
    if (!_registeredViewers) {
        NSArray <NSString *> *registeredNames = XXTEBuiltInDefaultsObject(@"AVAILABLE_VIEWER");
        NSMutableArray <Class> *registeredMutableViewers = [[NSMutableArray alloc] initWithCapacity:registeredNames.count];
        for (NSString *className in registeredNames) {
            [registeredMutableViewers addObject:NSClassFromString(className)];
        }
        _registeredViewers = [[NSArray alloc] initWithArray:registeredMutableViewers];
    }
    return _registeredViewers;
}

- (NSDictionary *)bindingDictionary {
    if (!_bindingDictionary) {
        // Auto-register binding
        NSDictionary *originalBindingDictionary = XXTEDefaultsObject(XXTExplorerViewEntryBindingKey);
        NSMutableDictionary *newBindingDictionary = [[NSMutableDictionary alloc] initWithDictionary:originalBindingDictionary];
        for (Class registeredViewerClass in self.registeredViewers) {
            Class <XXTEViewer> viewerClass = registeredViewerClass;
            NSArray <NSString *> *suggestedExtensions = [viewerClass suggestedExtensions];
            for (NSString *suggestExtension in suggestedExtensions) {
                if (!originalBindingDictionary[suggestExtension]) { // if no binding, set default binding
                    newBindingDictionary[suggestExtension] = NSStringFromClass(viewerClass);
                    continue;
                }
            }
        }
        NSDictionary *saveBindingDictionary = [[NSDictionary alloc] initWithDictionary:newBindingDictionary];
        XXTEDefaultsSetObject(XXTExplorerViewEntryBindingKey, saveBindingDictionary);
        _bindingDictionary = saveBindingDictionary;
    }
    return _bindingDictionary;
}

- (void)bindExtension:(NSString *)extension toViewer:(NSString *)viewerName {
    Class testClass = viewerName.length > 0 ? NSClassFromString(viewerName) : nil;
    NSMutableDictionary *mutableBindingDictionary = [[NSMutableDictionary alloc] initWithDictionary:self.bindingDictionary];
    if (testClass) {
        [mutableBindingDictionary setObject:viewerName forKey:extension];
    } else {
        [mutableBindingDictionary removeObjectForKey:extension];
    }
    NSDictionary *saveBindingDictionary = [[NSDictionary alloc] initWithDictionary:mutableBindingDictionary];
    XXTEDefaultsSetObject(XXTExplorerViewEntryBindingKey, saveBindingDictionary);
    _bindingDictionary = nil; // clear binding cache
}

- (BOOL)hasViewerForEntry:(NSDictionary *)entry {
    NSString *entryBaseExtension = [entry[XXTExplorerViewEntryAttributeExtension] lowercaseString];
    NSDictionary *bindingDictionary = XXTEDefaultsObject(XXTExplorerViewEntryBindingKey);
    NSString *viewerName = bindingDictionary[entryBaseExtension];
    Class testClass = viewerName.length > 0 ? NSClassFromString(viewerName) : nil;
    if (testClass) {
        return YES;
    }
    return NO;
}

- (UIViewController <XXTEViewer> *)viewerForEntry:(NSDictionary *)entry {
    NSString *entryPath = entry[XXTExplorerViewEntryAttributePath];
    NSString *entryBaseExtension = [entry[XXTExplorerViewEntryAttributeExtension] lowercaseString];
    NSString *viewerName = self.bindingDictionary[entryBaseExtension];
    if (viewerName) {
        Class viewerClass = viewerName.length > 0 ? NSClassFromString(viewerName) : nil;
        if (viewerClass) {
            UIViewController <XXTEViewer> *viewer = [[viewerClass alloc] initWithPath:entryPath];
            return viewer;
        }
    }
    return nil;
}

- (UIViewController *)openWithControllerForEntry:(NSDictionary *)entry {
    return nil;
}

@end
