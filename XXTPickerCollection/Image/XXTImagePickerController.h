//
//  XXTImagePickerController.h
//  XXTPickerCollection
//

#import <UIKit/UIKit.h>

#define XXT_RGB(r, g, b)     [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1]

#define XXT_ALBUM_NAME_TEXT_COLOR    XXT_RGB(26, 161, 230)
#define XXT_ALBUM_COUNT_TEXT_COLOR   XXT_RGB(247, 200, 142)
#define XXT_BOTTOM_TEXT_COLOR        XXT_RGB(255, 255, 255)

#define XXT_PICKER_RESULT_UIIMAGE    0
#define XXT_PICKER_RESULT_ASSET      1

#define XXT_NO_LIMIT_SELECT          -1


// if you don't want to save selected album, remove this.
#define XXT_SAVE_SELECTED_ALBUM

@interface XXTImagePickerController : UIViewController

@property(assign, nonatomic) id delegate;

@property(readwrite) NSInteger nMaxCount;      // -1 : no limit
@property(readwrite) NSInteger nColumnCount;   // 2, 3, or 4
@property(readwrite) NSInteger nResultType;    // default : XXT_PICKER_RESULT_UIIMAGE

@property(weak, nonatomic) IBOutlet UICollectionView *cvPhotoList;
@property(weak, nonatomic) IBOutlet UITableView *tvAlbumList;
@property(weak, nonatomic) IBOutlet UIView *vDimmed;


// init
- (void)initControls;

- (void)readAlbumList:(BOOL)bFirst;

// bottom menu
@property(weak, nonatomic) IBOutlet UIView *vBottomMenu;
@property(weak, nonatomic) IBOutlet UIButton *btSelectAlbum;
@property(weak, nonatomic) IBOutlet UIButton *btOK;
@property(weak, nonatomic) IBOutlet UIImageView *ivLine1;
@property(weak, nonatomic) IBOutlet UIImageView *ivLine2;
@property(weak, nonatomic) IBOutlet UILabel *lbSelectCount;
@property(weak, nonatomic) IBOutlet UIImageView *ivShowMark;

- (void)initBottomMenu;

- (IBAction)onSelectPhoto:(id)sender;

- (IBAction)onCancel:(id)sender;

- (IBAction)onSelectAlbum:(id)sender;

- (void)hideBottomMenu;


// side buttons
@property(weak, nonatomic) IBOutlet UIButton *btUp;
@property(weak, nonatomic) IBOutlet UIButton *btDown;

- (IBAction)onUp:(id)sender;

- (IBAction)onDown:(id)sender;


// photos
@property(strong, nonatomic) UIImageView *ivPreview;

- (void)showPhotosInGroup:(NSInteger)nIndex;    // nIndex : index in album array
- (void)showPreview:(NSInteger)nIndex;          // nIndex : index in photo array
- (void)hidePreview;


// select photos
@property(strong, nonatomic) NSMutableDictionary *dSelected;
@property(strong, nonatomic) NSIndexPath *lastAccessed;

@end

@protocol XXTImagePickerControllerDelegate

- (void)didCancelImagePickerController:(XXTImagePickerController *)picker;

- (void)didSelectPhotosFromImagePickerController:(XXTImagePickerController *)picker result:(NSArray *)aSelected;

@end
