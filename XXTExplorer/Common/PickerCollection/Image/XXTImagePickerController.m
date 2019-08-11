//
//  XXTImagePickerController.m
//  XXTPickerCollection
//

#import "XXTImagePickerController.h"
#import "XXTImagePickerAssetHelper.h"

#import "XXTImagePickerAlbumCell.h"
#import "XXTImagePickerPhotoCell.h"

@implementation XXTImagePickerController

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self initBottomMenu];
    [self initControls];

    NSBundle *frameworkBundle = [NSBundle mainBundle];
    UINib *nib = [UINib nibWithNibName:@"XXTImagePickerPhotoCell" bundle:frameworkBundle];
    [_cvPhotoList registerNib:nib forCellWithReuseIdentifier:@"XXTImagePickerPhotoCell"];

    _tvAlbumList.frame = CGRectMake(0, _vBottomMenu.frame.origin.y, self.view.frame.size.width, self.view.frame.size.height);
    _tvAlbumList.alpha = 0.0;

    [self readAlbumList:YES];

    // new photo is located at the first of array
    XXT_ASSET_HELPER.bReverse = YES;

    if (_nMaxCount != 1) {
        // init gesture for multiple selection with panning
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPanForSelection:)];
        [self.view addGestureRecognizer:pan];
    }

    // add observer for refresh asset data
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleEnterForeground:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (_nResultType == XXT_PICKER_RESULT_UIIMAGE)
        [XXT_ASSET_HELPER clearData];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)handleEnterForeground:(NSNotification *)notification {
    [self readAlbumList:NO];
}

#pragma mark - for init

- (void)initControls {
    // side buttons
    _btUp.backgroundColor = XXTColorBarTint();
    _btDown.backgroundColor = XXTColorBarTint();

    CALayer *layer1 = [_btDown layer];
    [layer1 setMasksToBounds:YES];
    [layer1 setCornerRadius:(CGFloat) (_btDown.frame.size.height / 2.0 - 1)];

    CALayer *layer2 = [_btUp layer];
    [layer2 setMasksToBounds:YES];
    [layer2 setCornerRadius:(CGFloat) (_btUp.frame.size.height / 2.0 - 1)];

    // table view
    UIImageView *ivHeader = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, _tvAlbumList.frame.size.width, 0.5)];
    ivHeader.backgroundColor = XXT_ALBUM_NAME_TEXT_COLOR;
    _tvAlbumList.tableHeaderView = ivHeader;

    UIImageView *ivFooter = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, _tvAlbumList.frame.size.width, 0.5)];
    ivFooter.backgroundColor = XXT_ALBUM_NAME_TEXT_COLOR;
    _tvAlbumList.tableFooterView = ivFooter;
}

- (void)readAlbumList:(BOOL)bFirst {
    [XXT_ASSET_HELPER getGroupList:^(NSArray *aGroups) {

        [self->_tvAlbumList reloadData];

        NSInteger nIndex = 0;
#ifdef XXT_SAVE_SELECTED_ALBUM
        nIndex = [self getSelectedGroupIndex:aGroups];
        if (nIndex < 0)
            nIndex = 0;
#endif
        [self->_tvAlbumList selectRowAtIndexPath:[NSIndexPath indexPathForRow:nIndex inSection:0] animated:NO scrollPosition:UITableViewScrollPositionTop];
        [self->_btSelectAlbum setTitle:[XXT_ASSET_HELPER getGroupInfo:nIndex][@"name"] forState:UIControlStateNormal];

        [self showPhotosInGroup:nIndex];

        if (aGroups.count == 1)
            self->_btSelectAlbum.enabled = NO;

        // calculate tableview's height
        self->_tvAlbumList.frame = CGRectMake(self->_tvAlbumList.frame.origin.x, self->_tvAlbumList.frame.origin.y, self->_tvAlbumList.frame.size.width, MIN(aGroups.count * 50, 200));
    }];
}

#pragma mark - for bottom menu

- (void)initBottomMenu {
    _vBottomMenu.backgroundColor = XXTColorBarTint();
    [_btSelectAlbum setTitleColor:XXT_BOTTOM_TEXT_COLOR forState:UIControlStateNormal];
    [_btSelectAlbum setTitleColor:XXT_BOTTOM_TEXT_COLOR forState:UIControlStateDisabled];

    _ivLine1.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"xxt-picker-line"]];
    _ivLine2.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"xxt-picker-line"]];

    if (_nMaxCount == XXT_NO_LIMIT_SELECT) {
        _lbSelectCount.text = NSLocalizedString(@"(0)", nil);
        _lbSelectCount.textColor = XXT_BOTTOM_TEXT_COLOR;
    } else if (_nMaxCount <= 1) {
        // hide ok button
        _btOK.hidden = YES;
        _ivLine1.hidden = YES;

        CGRect rect = _btSelectAlbum.frame;
        rect.size.width = rect.size.width + 60;
        _btSelectAlbum.frame = rect;

        _lbSelectCount.hidden = YES;
    } else {
        _lbSelectCount.text = [NSString stringWithFormat:@"(0/%d)", (int) _nMaxCount];
        _lbSelectCount.textColor = XXT_BOTTOM_TEXT_COLOR;
    }
}

- (IBAction)onSelectPhoto:(id)sender {
    NSMutableArray *aResult = [[NSMutableArray alloc] initWithCapacity:_dSelected.count];
    NSArray *aKeys = [_dSelected keysSortedByValueUsingSelector:@selector(compare:)];

    if (_nResultType == XXT_PICKER_RESULT_UIIMAGE) {
        for (int i = 0; i < _dSelected.count; i++) {
            UIImage *iSelected = [XXT_ASSET_HELPER getImageAtIndex:[aKeys[i] integerValue] type:XXT_ASSET_PHOTO_SCREEN_SIZE];
            if (iSelected != nil)
                [aResult addObject:iSelected];
        }
    } else {
        for (int i = 0; i < _dSelected.count; i++)
            [aResult addObject:[XXT_ASSET_HELPER getAssetAtIndex:[aKeys[i] integerValue]]];
    }

    [_delegate didSelectPhotosFromImagePickerController:self result:aResult];
}

- (IBAction)onCancel:(id)sender {
    [_delegate didCancelImagePickerController:self];
}

- (IBAction)onSelectAlbum:(id)sender {
    if (_tvAlbumList.frame.origin.y == _vBottomMenu.frame.origin.y) {
        // show tableview
        [UIView animateWithDuration:0.2 animations:^(void) {
            self->_tvAlbumList.frame = CGRectMake(0, self->_vBottomMenu.frame.origin.y - self->_tvAlbumList.frame.size.height,
                    self->_tvAlbumList.frame.size.width, self->_tvAlbumList.frame.size.height);
            self->_tvAlbumList.alpha = 1.0;

            self->_ivShowMark.transform = CGAffineTransformMakeRotation(M_PI);
        }];
    } else {
        // hide tableview
        [self hideBottomMenu];
    }
}

#pragma mark - for side buttons

- (IBAction)onUp:(id)sender {
    [_cvPhotoList scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionTop animated:YES];
}

- (IBAction)onDown:(id)sender {
    [_cvPhotoList scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:[XXT_ASSET_HELPER getPhotoCountOfCurrentGroup] - 1 inSection:0] atScrollPosition:UICollectionViewScrollPositionTop animated:YES];
}

#pragma mark - UITableViewDelegate for selecting album

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [XXT_ASSET_HELPER getGroupCount];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    XXTImagePickerAlbumCell *cell = (XXTImagePickerAlbumCell *) [tableView dequeueReusableCellWithIdentifier:@"XXTImagePickerAlbumCell"];

    if (cell == nil) {
        NSBundle *frameworkBundle = [NSBundle mainBundle];
        cell = [[frameworkBundle loadNibNamed:@"XXTImagePickerAlbumCell" owner:nil options:nil] lastObject];
    }

    NSDictionary *d = [XXT_ASSET_HELPER getGroupInfo:indexPath.row];
    cell.lbAlbumName.text = d[@"name"];
    cell.lbCount.text = [NSString stringWithFormat:@"%@", d[@"count"]];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self showPhotosInGroup:indexPath.row];
    [_btSelectAlbum setTitle:[XXT_ASSET_HELPER getGroupInfo:indexPath.row][@"name"] forState:UIControlStateNormal];

    [self hideBottomMenu];
}

- (void)hideBottomMenu {
    [UIView animateWithDuration:0.2 animations:^(void) {

        self->_tvAlbumList.frame = CGRectMake(0, self->_vBottomMenu.frame.origin.y, self->_tvAlbumList.frame.size.width, self->_tvAlbumList.frame.size.height);
        self->_ivShowMark.transform = CGAffineTransformMakeRotation(0);

        [UIView setAnimationDelay:0.1];

        self->_tvAlbumList.alpha = 0.0;
    }];
}

#pragma mark - UICollectionViewDelegates for photos

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [XXT_ASSET_HELPER getPhotoCountOfCurrentGroup];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    XXTImagePickerPhotoCell *cell = (XXTImagePickerPhotoCell *) [_cvPhotoList dequeueReusableCellWithReuseIdentifier:@"XXTImagePickerPhotoCell" forIndexPath:indexPath];

//    if (_nColumnCount >= 4)
//        cell.ivPhoto.image = [XXT_ASSET_HELPER getImageAtIndex:indexPath.row type:XXT_ASSET_PHOTO_THUMBNAIL];
//    else
    cell.ivPhoto.image = [XXT_ASSET_HELPER getImageAtIndex:indexPath.row type:XXT_ASSET_PHOTO_ASPECT_THUMBNAIL];


    [cell setSelectMode:_dSelected[@(indexPath.row)] != nil];

    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (_nMaxCount > 1 || _nMaxCount == XXT_NO_LIMIT_SELECT) {
        XXTImagePickerPhotoCell *cell = (XXTImagePickerPhotoCell *) [collectionView cellForItemAtIndexPath:indexPath];

        if ((_dSelected[@(indexPath.row)] == nil) && (_nMaxCount > _dSelected.count)) {
            // select
            _dSelected[@(indexPath.row)] = @(_dSelected.count);
            [cell setSelectMode:YES];
        } else {
            // unselect
            [_dSelected removeObjectForKey:@(indexPath.row)];
            [cell setSelectMode:NO];
        }

        if (_nMaxCount == XXT_NO_LIMIT_SELECT)
            _lbSelectCount.text = [NSString stringWithFormat:@"(%d)", (int) _dSelected.count];
        else
            _lbSelectCount.text = [NSString stringWithFormat:@"(%d/%d)", (int) _dSelected.count, (int) _nMaxCount];
    } else {
        if (_nResultType == XXT_PICKER_RESULT_UIIMAGE) {
            UIImage *resultImage = [XXT_ASSET_HELPER getImageAtIndex:indexPath.row type:XXT_ASSET_PHOTO_SCREEN_SIZE];
            if (resultImage) {
                [_delegate didSelectPhotosFromImagePickerController:self result:@[resultImage]];
            } else {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
                                                                    message:NSLocalizedString(@"Please download this image from iCloud.", nil)
                                                                   delegate:nil
                                                          cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                          otherButtonTitles:nil];
                [alertView show];
            }
        } else {
            ALAsset *resultAsset = [XXT_ASSET_HELPER getAssetAtIndex:indexPath.row];
            if (resultAsset) {
                [_delegate didSelectPhotosFromImagePickerController:self result:@[resultAsset]];
            } else {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
                                                                    message:NSLocalizedString(@"Please download this image from iCloud.", nil)
                                                                   delegate:nil
                                                          cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                          otherButtonTitles:nil];
                [alertView show];
            }
        }
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGRect rx = collectionView.bounds;
    CGFloat totalWidth = MIN(rx.size.width, rx.size.height);
    CGFloat width = (totalWidth - (4 * (_nColumnCount - 1))) / _nColumnCount;
    return CGSizeMake(width, width);
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView == _cvPhotoList) {
        [UIView animateWithDuration:0.2 animations:^(void) {
            if (scrollView.contentOffset.y <= 50)
                self->_btUp.alpha = 0.0;
            else
                self->_btUp.alpha = 1.0;

            if (scrollView.contentOffset.y + scrollView.frame.size.height >= scrollView.contentSize.height)
                self->_btDown.alpha = 0.0;
            else
                self->_btDown.alpha = 1.0;
        }];
    }
}

// for multiple selection with panning
- (void)onPanForSelection:(UIPanGestureRecognizer *)gestureRecognizer {
    double fX = [gestureRecognizer locationInView:_cvPhotoList].x;
    double fY = [gestureRecognizer locationInView:_cvPhotoList].y;

    for (UICollectionViewCell *cell in _cvPhotoList.visibleCells) {
        float fSX = cell.frame.origin.x;
        float fEX = cell.frame.origin.x + cell.frame.size.width;
        float fSY = cell.frame.origin.y;
        float fEY = cell.frame.origin.y + cell.frame.size.height;

        if (fX >= fSX && fX <= fEX && fY >= fSY && fY <= fEY) {
            NSIndexPath *indexPath = [_cvPhotoList indexPathForCell:cell];

            if (_lastAccessed != indexPath) {
                [self collectionView:_cvPhotoList didSelectItemAtIndexPath:indexPath];
            }

            _lastAccessed = indexPath;
        }
    }

    if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        _lastAccessed = nil;
        _cvPhotoList.scrollEnabled = YES;
    }
}

#pragma mark - for photos

- (void)showPhotosInGroup:(NSInteger)nIndex {
    if (_nMaxCount == XXT_NO_LIMIT_SELECT) {
        _dSelected = [[NSMutableDictionary alloc] init];
        _lbSelectCount.text = NSLocalizedString(@"(0)", nil);
    } else if (_nMaxCount > 1) {
        _dSelected = [[NSMutableDictionary alloc] initWithCapacity:(NSUInteger) _nMaxCount];
        _lbSelectCount.text = [NSString stringWithFormat:@"(0/%d)", (int) _nMaxCount];
    }

    [XXT_ASSET_HELPER getPhotoListOfGroupByIndex:nIndex result:^(NSArray *aPhotos) {

        [self->_cvPhotoList reloadData];

        self->_cvPhotoList.alpha = 0.3;
        [UIView animateWithDuration:0.2 animations:^(void) {
            [UIView setAnimationDelay:0.1];
            self->_cvPhotoList.alpha = 1.0;
        }];

        if (aPhotos.count > 0) {
            [self->_cvPhotoList scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionTop animated:NO];
        }

        self->_btUp.alpha = 0.0;

        dispatch_async(dispatch_get_main_queue(), ^(void) {
            if (self->_cvPhotoList.contentSize.height < self->_cvPhotoList.frame.size.height)
                self->_btDown.alpha = 0.0;
            else
                self->_btDown.alpha = 1.0;
        });
    }];

#ifdef XXT_SAVE_SELECTED_ALBUM
    // save selected album
    [self saveSelectedGroup:nIndex];
#endif

}

#pragma mark - save selected album

- (void)saveSelectedGroup:(NSInteger)nIndex {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    [defaults setObject:[[XXT_ASSET_HELPER getGroupAtIndex:nIndex] valueForProperty:ALAssetsGroupPropertyName] forKey:@"XXT_SELECTED_ALBUM"];
    [defaults synchronize];
}

- (NSString *)loadSelectedGroup {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    return [defaults objectForKey:@"XXT_SELECTED_ALBUM"];
}

- (NSInteger)getSelectedGroupIndex:(NSArray *)aGroups {
    NSString *strOldAlbumName = [self loadSelectedGroup];
    for (int i = 0; i < aGroups.count; i++) {
        NSDictionary *d = [XXT_ASSET_HELPER getGroupInfo:i];
        if ([d[@"name"] isEqualToString:strOldAlbumName])
            return i;
    }

    return -1;
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [%@ dealloc]", NSStringFromClass([self class]));
#endif
}

@end
