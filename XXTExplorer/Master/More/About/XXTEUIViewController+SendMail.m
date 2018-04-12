//
//  XXTEUIViewController+SendMail.m
//  XXTExplorer
//
//  Created by Zheng Wu on 13/10/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEUIViewController+SendMail.h"
#import "XXTEMailComposeViewController.h"

#import <XUI/XUIButtonCell.h>
#import <XUI/XUILogger.h>

@implementation XXTEUIViewController (SendMail)

- (NSNumber *)xui_SendMail:(XUIButtonCell *)cell {
    NSDictionary *args = cell.xui_args;
    if ((args[@"subject"] && ![args[@"subject"] isKindOfClass:[NSString class]]))
    {
        [self.logger logMessage:XUIParserErrorInvalidType(@"@selector(SendMail:) -> subject", @"NSString")];
        return @(NO);
    }
    if ((args[@"toRecipients"] && ![args[@"toRecipients"] isKindOfClass:[NSArray class]])) {
        [self.logger logMessage:XUIParserErrorInvalidType(@"@selector(SendMail:) -> toRecipients", @"NSArray")];
        return @(NO);
    }
    if ((args[@"ccRecipients"] && ![args[@"ccRecipients"] isKindOfClass:[NSArray class]])) {
        [self.logger logMessage:XUIParserErrorInvalidType(@"@selector(SendMail:) -> ccRecipients", @"NSArray")];
        return @(NO);
    }
    if ((args[@"bccRecipients"] && ![args[@"bccRecipients"] isKindOfClass:[NSArray class]])) {
        [self.logger logMessage:XUIParserErrorInvalidType(@"@selector(SendMail:) -> bccRecipients", @"NSArray")];
        return @(NO);
    }
    if ((args[@"attachments"] && ![args[@"attachments"] isKindOfClass:[NSArray class]])) {
        [self.logger logMessage:XUIParserErrorInvalidType(@"@selector(SendMail:) -> attachments", @"NSArray")];
        return @(NO);
    }
    if ([XXTEMailComposeViewController canSendMail]) {
        XXTEMailComposeViewController *picker = [[XXTEMailComposeViewController alloc] init];
        if (!picker) return @(NO);
        picker.mailComposeDelegate = self;
        if (args[@"subject"])
            [picker setSubject:args[@"subject"]];
        if (args[@"toRecipients"])
            [picker setToRecipients:args[@"toRecipients"]];
        if (args[@"ccRecipients"])
            [picker setCcRecipients:args[@"ccRecipients"]];
        if (args[@"bccRecipients"])
            [picker setBccRecipients:args[@"bccRecipients"]];
        if (args[@"attachments"]) {
            for (NSString *attachmentName in args[@"attachments"]) {
                @autoreleasepool {
                    NSString *attachmentPath = [self.adapter.bundle pathForResource:attachmentName ofType:nil];
                    if (!attachmentPath) {
                        continue;
                    }
                    NSData *attachmentData = [[NSData alloc] initWithContentsOfFile:attachmentPath];
                    if (!attachmentData) {
                        continue;
                    }
                    NSString *attachmentShortName = [attachmentPath lastPathComponent];
                    [picker addAttachmentData:attachmentData mimeType:@"application/octet-stream" fileName:attachmentShortName];
                }
            }
        }
        picker.modalPresentationStyle = UIModalPresentationFormSheet;
        [self presentViewController:picker animated:YES completion:nil];
        return @(YES);
    } else {
        toastMessage(self, NSLocalizedString(@"Please setup \"Mail\" to send mail feedback directly.", nil));
        return @(NO);
    }
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    @weakify(self);
    [controller dismissViewControllerAnimated:YES completion:^() {
        @strongify(self);
        if (error) {
            toastError(self, error);
        }
    }];
}

@end
