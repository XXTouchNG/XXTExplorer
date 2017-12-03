/**
 Copyright (c) 2014-present, Facebook, Inc.
 All rights reserved.
 
 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import <QuartzCore/CALayer.h>

#import "XXTEShimmering.h"

/**
  @abstract Lightweight, generic shimmering layer.
 */
@interface XXTEShimmeringLayer : CALayer <XXTEShimmering>

//! @abstract The content layer to be shimmered.
@property (strong, nonatomic) CALayer *contentLayer;

@end
