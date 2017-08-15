//
//  SKScopedString.h
//  XXTExplorer
//
//  A datastructure that facilitates working with strings that have nested
//  scopes associated with them. A scope being a named range that can have an
//  attribute assciated with it for the callers convenience.
//  The ranges can be nested. The datastructure could be visualized like this:
//  In fact, something like this is returned by the prettyPrint function.
//
//  Top:                              ----
//                              -------------
//            -------   -----------------------------
//  Bottom:  ------------------------------------------
//  String: "(This is) (string (with (nest)ed) scopes)!"
//
//  Note:
//  In the picture above the parens are not actually in the string, they serve
//  visualization purposes. The bottom-most layer is implicit and is not stored.
//  A new layer is added if no layer can hold the inserted scope without
//  creating intersections.
//
//  In the future the datastructure could be optimized by using binary search
//  for insertions at the individual levels.
//
//  Created by Zheng on 13/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SKResult;

/// In this project the difference between a Result and a Scope is that the
/// scope has the attribute set while the Result does not. This is an implicit
/// agreement, please respect ;).
typedef SKResult SKScope;

@interface SKScopedString : NSObject

// MARK: - Properties
@property (nonatomic, strong) NSString *string;

/// The inplicit scope at the base of each ScopedString
@property (nonatomic, strong, readonly, getter=getBaseScope) SKScope *baseScope;

// MARK: - Initializers
- (instancetype)initWithString:(NSString *)string;

// MARK: - Interface
- (NSInteger)numberOfScopes;
- (NSInteger)numberOfLevels;
- (BOOL)isInStringAtIndex:(NSInteger)index;
- (void)appendScopeAtTop:(SKScope *)scope;
- (void)appendScopeAtBottom:(SKScope *)scope;
- (SKScope *)topMostScopeAtIndex:(NSInteger)index;
- (SKScope *)lowerScopeForScope:(SKScope *)scope atIndex:(NSInteger)index;
- (NSInteger)levelForScope:(SKScope *)scope;

/// Removes all scopes that are entirely contained in the spcified range.
- (void)removeScopesInRange:(NSRange)range; // mutating

/// Inserts the given string into the underlying string, stretching and
/// shifting ranges as needed. If the range starts before and ends after the
/// insertion point, it is stretched.
- (void)insertString:(NSString *)string atIndex:(NSInteger)index;

/// Deletes the characters from the underlying string, shrinking and
/// deleting scopes as needed.
- (void)deleteCharactersInRange:(NSRange)range;

/// - note: This representation is guaranteed not to change between releases
///         (except for releases with breaking changes) so it can be used
///         for unit testing.
/// - returns: A user-friendly description of the instance.
- (NSString *)prettyRepresentation;

@end
