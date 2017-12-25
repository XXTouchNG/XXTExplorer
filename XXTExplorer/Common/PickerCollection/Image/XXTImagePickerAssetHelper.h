//
//  XXTImagePickerAssetHelper.m
//  XXTPickerCollection
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>

#define XXT_ASSET_HELPER    [XXTImagePickerAssetHelper sharedAssetHelper]

#define XXT_ASSET_PHOTO_THUMBNAIL           0
#define XXT_ASSET_PHOTO_ASPECT_THUMBNAIL    1
#define XXT_ASSET_PHOTO_SCREEN_SIZE         2
#define XXT_ASSET_PHOTO_FULL_RESOLUTION     3

@interface XXTImagePickerAssetHelper : NSObject

- (void)initAsset;

@property(nonatomic, strong) ALAssetsLibrary *assetsLibrary;
@property(nonatomic, strong) NSMutableArray *assetPhotos;
@property(nonatomic, strong) NSMutableArray *assetGroups;

@property(readwrite) BOOL bReverse;

+ (XXTImagePickerAssetHelper *)sharedAssetHelper;

// get album list from asset
- (void)getGroupList:(void (^)(NSArray *))result;

// get photos from specific album with ALAssetsGroup object
- (void)getPhotoListOfGroup:(ALAssetsGroup *)alGroup result:(void (^)(NSArray *))result;

// get photos from specific album with index of album array
- (void)getPhotoListOfGroupByIndex:(NSInteger)nGroupIndex result:(void (^)(NSArray *))result;

// get photos from camera roll
- (void)getSavedPhotoList:(void (^)(NSArray *))result error:(void (^)(NSError *))error;

- (NSInteger)getGroupCount;

- (NSInteger)getPhotoCountOfCurrentGroup;

- (NSDictionary *)getGroupInfo:(NSInteger)nIndex;

- (void)clearData;

// utils
- (UIImage *)getCroppedImage:(NSURL *)urlImage;

- (UIImage *)getImageFromAsset:(ALAsset *)asset type:(NSInteger)nType;

- (UIImage *)getImageAtIndex:(NSInteger)nIndex type:(NSInteger)nType;

- (ALAsset *)getAssetAtIndex:(NSInteger)nIndex;

- (ALAssetsGroup *)getGroupAtIndex:(NSInteger)nIndex;

@end

