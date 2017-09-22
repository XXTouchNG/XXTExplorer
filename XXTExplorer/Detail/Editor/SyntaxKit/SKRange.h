//
//  SKRange.h
//  XXTExplorer
//
//  Created by Zheng on 19/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#ifndef SKRange_h
#define SKRange_h

#import <Foundation/Foundation.h>

#pragma mark - NSRangeExtensions

NS_INLINE BOOL NSRangeEmpty(NSRange range) {
    return range.length == 0;
}

NS_INLINE BOOL NSRangeContainsIndex(NSRange _self, NSUInteger index) {
    return (_self.length == 0 && index == _self.location) || (index >= _self.location && index < _self.location + _self.length);
}

NS_INLINE BOOL NSRangePartiallyContains(NSRange _self, NSRange otherRange) {
    return otherRange.location + otherRange.length >= _self.location && otherRange.location < _self.location + _self.length;
}

NS_INLINE BOOL NSRangeEntirelyContains(NSRange _self, NSRange otherRange) {
    return _self.location <= otherRange.location && _self.location + _self.length >= otherRange.location + otherRange.length;
}

NS_INLINE NSRange NSRangeRemoveIndexesFromRange(NSRange _self, NSRange range) {
    _self.length -= NSIntersectionRange(range, NSMakeRange(_self.location, _self.length)).length;
    if (range.location < _self.location) {
        _self.location -= NSIntersectionRange(range, NSMakeRange(0, _self.location)).length;
    }
    return _self;
}

NS_INLINE NSRange NSRangeInsertIndexesFromRange(NSRange _self, NSRange range) {
    if (NSRangeContainsIndex(_self, range.location) && range.location < NSMaxRange(_self)) {
        _self.length += range.length;
    } else if (_self.location > range.location) {
        _self.location += range.length;
    }
    return _self;
}

#endif /* SKRange_h */
