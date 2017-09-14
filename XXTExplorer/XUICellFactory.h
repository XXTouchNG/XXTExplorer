//
//  XUICellFactory.h
//  XXTExplorer
//
//  Created by Zheng on 17/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>

@class XUIBaseCell, XUIGroupCell, XUILogger, XUIDefaultsService, XUITheme;

@class XUICellFactory;

@protocol XUICellFactoryDelegate <NSObject>

- (void)cellFactory:(XUICellFactory *)parser didFailWithError:(NSError *)error;
- (void)cellFactoryDidFinishParsing:(XUICellFactory *)parser;

@end

@interface XUICellFactory : NSObject

@property (nonatomic, strong, readonly) XUILogger *logger;
@property (nonatomic, strong, readonly) XUIDefaultsService *defaultsService;

@property (nonatomic, weak) id <XUICellFactoryDelegate> delegate;
@property (nonatomic, strong, readonly) NSBundle *bundle;
@property (nonatomic, strong, readonly) NSDictionary <NSString *, id> *rootEntry;
@property (nonatomic, strong, readonly) NSError *error;
@property (nonatomic, strong, readonly) NSArray <XUIGroupCell *> *sectionCells;
@property (nonatomic, strong, readonly) NSArray <NSArray <XUIBaseCell *> *> *otherCells;

@property (nonatomic, strong, readonly) XUITheme *theme;

- (instancetype)initWithRootEntry:(NSDictionary <NSString *, id> *)rootEntry withBundle:(NSBundle *)bundle;
- (void)parse; // this method should run in main thread

@end
