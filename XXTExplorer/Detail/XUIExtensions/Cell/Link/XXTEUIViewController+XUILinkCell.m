//
//  XXTEUIViewController+XUILinkCell.m
//  XXTExplorer
//
//  Created by Zheng Wu on 29/09/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEUIViewController+XUILinkCell.h"
#import "XXTEUIViewController+SharedInstance.h"

#import "XXTECommonWebViewController.h"
#import <XUI/XUICellFactory.h>

@implementation XXTEUIViewController (XUILinkCell)

- (void)tableView:(UITableView *)tableView XUILinkCell:(UITableViewCell *)cell {
    XUILinkCell *linkCell = (XUILinkCell *)cell;
    NSString *detailUrl = linkCell.xui_url;
    UIViewController *detailController = nil;
    NSURL *detailPathURL = [NSURL URLWithString:detailUrl];
    if ([detailPathURL scheme]) {
        XXTECommonWebViewController *webController = [[XXTECommonWebViewController alloc] initWithURL:detailPathURL];
        detailController = webController;
    } else {
        NSString *detailPathNameExt = [[detailUrl pathExtension] lowercaseString];
        NSString *detailPath = [self.bundle pathForResource:detailUrl ofType:nil];
        if ([[self.class suggestedExtensions] containsObject:detailPathNameExt]) {
            detailController = [[[self class] alloc] initWithPath:detailPath withBundlePath:[self.bundle bundlePath]];
            detailController.hidesBottomBarWhenPushed = self.hidesBottomBarWhenPushed;
        }
        else {
            NSError *entryError = nil;
            XXTExplorerEntry *entryDetail = [self.class.entryParser entryOfPath:detailPath withError:&entryError];
            if (!entryError && [self.class.entryService hasViewerForEntry:entryDetail]) {
                UIViewController <XXTEViewer> *viewer = [self.class.entryService viewerForEntry:entryDetail];
                detailController = viewer;
            }
        }
    }
    if (detailController) {
        detailController.title = linkCell.textLabel.text;
        if ([detailController isKindOfClass:[self class]])
        {
            XXTEUIViewController *nextController = (XXTEUIViewController *)detailController;
            nextController.cellFactory.theme = self.cellFactory.theme;
        }
        [self.navigationController pushViewController:detailController animated:YES];
    }
}

@end
