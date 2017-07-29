//
//  XUICellFactory.h
//  XXTExplorer
//
//  Created by Zheng on 17/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>

@class XUIBaseCell, XUIGroupCell;

extern NSString * const kXUICellFactoryErrorDomain;

@class XUICellFactory;

@protocol XUICellFactoryDelegate <NSObject>

- (void)cellFactory:(XUICellFactory *)parser didFailWithError:(NSError *)error;
- (void)cellFactoryDidFinishParsing:(XUICellFactory *)parser;

@end

@interface XUICellFactory : NSObject

@property (nonatomic, weak) id <XUICellFactoryDelegate> delegate;
@property (nonatomic, strong) NSBundle *bundle;
@property (nonatomic, strong, readonly) NSDictionary <NSString *, id> *rootEntry;
@property (nonatomic, strong, readonly) NSError *error;
@property (nonatomic, strong, readonly) NSArray <XUIGroupCell *> *sectionCells;
@property (nonatomic, strong, readonly) NSArray <NSArray <XUIBaseCell *> *> *otherCells;

- (instancetype)initWithRootEntry:(NSDictionary <NSString *, id> *)rootEntry;
- (void)parse; // this method should run in main thread

@end
