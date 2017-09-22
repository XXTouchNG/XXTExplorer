//
//  SKCaptureCollection.h
//  XXTExplorer
//
//  Represents the captures attribute in a TextMate grammar.
//
//  Created by Zheng on 13/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SKCapture;

@interface SKCaptureCollection : NSObject

// MARK: - Properties
@property (nonatomic, strong, readonly, getter=getCaptureIndexes) NSArray <NSNumber *> *captureIndexes;

// MARK: - Initializers
- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

// MARK: - Accessing Captures
- (SKCapture *)objectForKeyedSubscript:(NSNumber *)index;

@end
