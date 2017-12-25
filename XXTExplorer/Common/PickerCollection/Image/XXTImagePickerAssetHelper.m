//
//  XXTImagePickerAssetHelper.m
//  XXTPickerCollection
//

#import "XXTImagePickerAssetHelper.h"

@implementation XXTImagePickerAssetHelper


+ (XXTImagePickerAssetHelper *)sharedAssetHelper {
    static XXTImagePickerAssetHelper *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[XXTImagePickerAssetHelper alloc] init];
        [_sharedInstance initAsset];
    });

    return _sharedInstance;
}

- (void)initAsset {
    if (self.assetsLibrary == nil) {
        _assetsLibrary = [[ALAssetsLibrary alloc] init];

        NSString *strVersion = [[UIDevice alloc] systemVersion];
        if ([strVersion compare:@"5"] >= 0)
            [_assetsLibrary writeImageToSavedPhotosAlbum:nil metadata:nil completionBlock:^(NSURL *assetURL, NSError *error) {
            }];
    }
}

- (void)setCameraRollAtFirst {
    for (ALAssetsGroup *group in _assetGroups) {
        if ([[group valueForProperty:@"ALAssetsGroupPropertyType"] intValue] == ALAssetsGroupSavedPhotos) {
            // send to head
            [_assetGroups removeObject:group];
            [_assetGroups insertObject:group atIndex:0];

            return;
        }
    }
}

- (void)getGroupList:(void (^)(NSArray *))result {
    [self initAsset];

    void (^assetGroupEnumerator)(ALAssetsGroup *, BOOL *) = ^(ALAssetsGroup *group, BOOL *stop) {
        [group setAssetsFilter:[ALAssetsFilter allPhotos]];

        if (group == nil) {
            if (self->_bReverse)
                self->_assetGroups = [[NSMutableArray alloc] initWithArray:[[self->_assetGroups reverseObjectEnumerator] allObjects]];

            [self setCameraRollAtFirst];

            // end of enumeration
            result(self->_assetGroups);
            return;
        }

        [self->_assetGroups addObject:group];
    };

    void (^assetGroupEnumberatorFailure)(NSError *) = ^(NSError *error) {

    };

    _assetGroups = [[NSMutableArray alloc] init];
    [_assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAll
                                  usingBlock:assetGroupEnumerator
                                failureBlock:assetGroupEnumberatorFailure];
}

- (void)getPhotoListOfGroup:(ALAssetsGroup *)alGroup result:(void (^)(NSArray *))result {
    [self initAsset];

    _assetPhotos = [[NSMutableArray alloc] init];
    [alGroup setAssetsFilter:[ALAssetsFilter allPhotos]];
    [alGroup enumerateAssetsUsingBlock:^(ALAsset *alPhoto, NSUInteger index, BOOL *stop) {

        if (alPhoto == nil) {
            if (self->_bReverse)
                self->_assetPhotos = [[NSMutableArray alloc] initWithArray:[[self->_assetPhotos reverseObjectEnumerator] allObjects]];

            result(self->_assetPhotos);
            return;
        }

        [self->_assetPhotos addObject:alPhoto];
    }];
}

- (void)getPhotoListOfGroupByIndex:(NSInteger)nGroupIndex result:(void (^)(NSArray *))result {
    [self getPhotoListOfGroup:_assetGroups[(NSUInteger) nGroupIndex] result:^(NSArray *aResult) {
        result(self->_assetPhotos);
    }];
}

- (void)getSavedPhotoList:(void (^)(NSArray *))result error:(void (^)(NSError *))error {
    [self initAsset];

    dispatch_async(dispatch_get_main_queue(), ^{

        void (^assetGroupEnumerator)(ALAssetsGroup *, BOOL *) = ^(ALAssetsGroup *group, BOOL *stop) {
            if ([[group valueForProperty:@"ALAssetsGroupPropertyType"] intValue] == ALAssetsGroupSavedPhotos) {
                [group setAssetsFilter:[ALAssetsFilter allPhotos]];

                [group enumerateAssetsUsingBlock:^(ALAsset *alPhoto, NSUInteger index, BOOL *stop) {

                    if (alPhoto == nil) {
                        if (self->_bReverse)
                            self->_assetPhotos = [[NSMutableArray alloc] initWithArray:[[self->_assetPhotos reverseObjectEnumerator] allObjects]];

                        result(self->_assetPhotos);
                        return;
                    }

                    [self->_assetPhotos addObject:alPhoto];
                }];
            }
        };

        void (^assetGroupEnumberatorFailure)(NSError *) = ^(NSError *err) {
            error(err);
        };

        self->_assetPhotos = [[NSMutableArray alloc] init];
        [self->_assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos
                                            usingBlock:assetGroupEnumerator
                                          failureBlock:assetGroupEnumberatorFailure];
    });
}

- (NSInteger)getGroupCount {
    return _assetGroups.count;
}

- (NSInteger)getPhotoCountOfCurrentGroup {
    return _assetPhotos.count;
}

- (NSDictionary *)getGroupInfo:(NSInteger)nIndex {
    return @{@"name": [_assetGroups[(NSUInteger) nIndex] valueForProperty:ALAssetsGroupPropertyName],
            @"count": @([_assetGroups[(NSUInteger) nIndex] numberOfAssets])};
}

- (void)clearData {
    _assetGroups = nil;
    _assetPhotos = nil;
}

#pragma mark - utils

- (UIImage *)getCroppedImage:(NSURL *)urlImage {
    __block UIImage *iImage = nil;
    __block BOOL bBusy = YES;

    ALAssetsLibraryAssetForURLResultBlock resultblock = ^(ALAsset *myasset) {
        ALAssetRepresentation *rep = [myasset defaultRepresentation];
        NSString *strXMP = rep.metadata[@"AdjustmentXMP"];
        if (strXMP == nil || [strXMP isKindOfClass:[NSNull class]]) {
            CGImageRef iref = [rep fullResolutionImage];
            if (iref)
                iImage = [UIImage imageWithCGImage:iref scale:1.0 orientation:(UIImageOrientation) rep.orientation];
            else
                iImage = nil;
        } else {
            // to get edited photo by photo app
            NSData *dXMP = [strXMP dataUsingEncoding:NSUTF8StringEncoding];

            CIImage *image = [CIImage imageWithCGImage:rep.fullResolutionImage];

            NSError *error = nil;
            NSArray *filterArray = [CIFilter filterArrayFromSerializedXMP:dXMP
                                                         inputImageExtent:image.extent
                                                                    error:&error];
            if (error) {

            }

            for (CIFilter *filter in filterArray) {
                [filter setValue:image forKey:kCIInputImageKey];
                image = [filter outputImage];
            }

            iImage = [UIImage imageWithCIImage:image scale:1.0 orientation:(UIImageOrientation) rep.orientation];
        }

        bBusy = NO;
    };

    ALAssetsLibraryAccessFailureBlock failureblock = ^(NSError *myerror) {

    };

    [_assetsLibrary assetForURL:urlImage
                    resultBlock:resultblock
                   failureBlock:failureblock];

    while (bBusy)
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];

    return iImage;
}

- (UIImage *)getImageFromAsset:(ALAsset *)asset type:(NSInteger)nType {
    CGImageRef iRef = nil;

    if (nType == XXT_ASSET_PHOTO_THUMBNAIL)
        iRef = [asset thumbnail];
    else if (nType == XXT_ASSET_PHOTO_ASPECT_THUMBNAIL)
        iRef = [asset aspectRatioThumbnail];
    else if (nType == XXT_ASSET_PHOTO_SCREEN_SIZE)
        iRef = [asset.defaultRepresentation fullScreenImage];
    else if (nType == XXT_ASSET_PHOTO_FULL_RESOLUTION) {
        NSString *strXMP = asset.defaultRepresentation.metadata[@"AdjustmentXMP"];
        if (strXMP == nil || [strXMP isKindOfClass:[NSNull class]]) {
            iRef = [asset.defaultRepresentation fullResolutionImage];
            return [UIImage imageWithCGImage:iRef scale:1.0 orientation:(UIImageOrientation) asset.defaultRepresentation.orientation];
        } else {
            NSData *dXMP = [strXMP dataUsingEncoding:NSUTF8StringEncoding];

            CIImage *image = [CIImage imageWithCGImage:asset.defaultRepresentation.fullResolutionImage];

            NSError *error = nil;
            NSArray *filterArray = [CIFilter filterArrayFromSerializedXMP:dXMP
                                                         inputImageExtent:image.extent
                                                                    error:&error];
            if (error) {

            }

            for (CIFilter *filter in filterArray) {
                [filter setValue:image forKey:kCIInputImageKey];
                image = [filter outputImage];
            }

            UIImage *iImage = [UIImage imageWithCIImage:image scale:1.0 orientation:(UIImageOrientation) asset.defaultRepresentation.orientation];
            return iImage;
        }
    }
    UIImage *resultImage = nil;
    if (iRef) {
        resultImage = [UIImage imageWithCGImage:iRef];
    }
    return resultImage;
}

- (UIImage *)getImageAtIndex:(NSInteger)nIndex type:(NSInteger)nType {
    return [self getImageFromAsset:(ALAsset *) _assetPhotos[(NSUInteger) nIndex] type:nType];
}

- (ALAsset *)getAssetAtIndex:(NSInteger)nIndex {
    return _assetPhotos[(NSUInteger) nIndex];
}

- (ALAssetsGroup *)getGroupAtIndex:(NSInteger)nIndex {
    return _assetGroups[(NSUInteger) nIndex];
}

@end
