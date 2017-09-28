//
//  XXTEEditorFontSizeCell.h
//  XXTExplorer
//
//  Created by Zheng Wu on 21/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

@class XXTEEditorFontSizeView;

@interface XXTEEditorFontSizeCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet XXTEEditorFontSizeView *sizeView;

@end
