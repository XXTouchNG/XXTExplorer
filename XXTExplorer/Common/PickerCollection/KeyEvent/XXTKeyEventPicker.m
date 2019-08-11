//
//  XXTKeyEventPicker.m
//  XXTPickerCollection
//
//  Created by Zheng on 30/04/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTKeyEventPicker.h"
#import "XXTKeyEvent.h"

#import "XXTPickerDefine.h"
#import "XXTPickerSnippetTask.h"
#import "XXTPickerFactory.h"

static NSString * const kXXTKeyEventTableViewCellReuseIdentifier = @"kXXTKeyEventTableViewCellReuseIdentifier";

@interface XXTKeyEventPicker () <UITableViewDelegate, UITableViewDataSource>
@property (strong, nonatomic) UITableView *tableView;
@property (nonatomic, strong) NSArray <NSArray <XXTKeyEvent *> *> *events;
@property (nonatomic, strong) NSArray <NSString *> *sectionNames;
@property (nonatomic, strong) NSString *selectedCommand;

@end

// type
// title
// subtitle

@implementation XXTKeyEventPicker {
    NSString *_pickerSubtitle;
}

@synthesize pickerTask = _pickerTask;
@synthesize pickerMeta = _pickerMeta;

#pragma mark - XXTBasePicker

+ (NSString *)pickerKeyword {
    return @"key";
}

- (NSString *)pickerResult {
    return self.selectedCommand;
}

- (NSString *)title {
    if (self.pickerMeta[@"title"]) {
        return self.pickerMeta[@"title"];
    } else {
        return NSLocalizedString(@"Key Event", nil);
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.sectionNames = @[
            NSLocalizedString(@"Hardware Keys", nil),
            NSLocalizedString(@"Keyboard Keys", nil),
            NSLocalizedString(@"Media Keys", nil),
    ];
    self.events = @[
            @[
                    [XXTKeyEvent eventWithTitle:NSLocalizedString(@"Home Button", nil) command:@"HOMEBUTTON"],
                    [XXTKeyEvent eventWithTitle:NSLocalizedString(@"Volume +", nil) command:@"VOLUMEUP"],
                    [XXTKeyEvent eventWithTitle:NSLocalizedString(@"Volume -", nil) command:@"VOLUMEDOWN"],
                    [XXTKeyEvent eventWithTitle:NSLocalizedString(@"Power Button", nil) command:@"LOCK"],
                    [XXTKeyEvent eventWithTitle:NSLocalizedString(@"Mute Button", nil) command:@"MUTE"],
            ],
            @[

                    [XXTKeyEvent eventWithTitle:NSLocalizedString(@"Return Key", nil) command:@"RETURN"],
                    [XXTKeyEvent eventWithTitle:NSLocalizedString(@"Esc Key", nil) command:@"ESCAPE"],
                    [XXTKeyEvent eventWithTitle:NSLocalizedString(@"Backspace Key", nil) command:@"BACKSPACE"],
                    [XXTKeyEvent eventWithTitle:NSLocalizedString(@"Space Key", nil) command:@"SPACE"],
                    [XXTKeyEvent eventWithTitle:NSLocalizedString(@"Tab Key", nil) command:@"TAB"],
                    [XXTKeyEvent eventWithTitle:NSLocalizedString(@"Spotlight Key", nil) command:@"SPOTLIGHT"],
                    [XXTKeyEvent eventWithTitle:NSLocalizedString(@"Bright +", nil) command:@"BRIGHTUP"],
                    [XXTKeyEvent eventWithTitle:NSLocalizedString(@"Bright -", nil) command:@"BRIGHTDOWN"],
                    [XXTKeyEvent eventWithTitle:NSLocalizedString(@"Show/Hide Keyboard", nil) command:@"SHOW_HIDE_KEYBOARD"],
            ],
            @[
                    [XXTKeyEvent eventWithTitle:NSLocalizedString(@"Media Forward Key", nil) command:@"FORWARD"],
                    [XXTKeyEvent eventWithTitle:NSLocalizedString(@"Media Rewind Key", nil) command:@"REWIND"],
                    [XXTKeyEvent eventWithTitle:NSLocalizedString(@"Media Forward 2 Key", nil) command:@"FORWARD2"],
                    [XXTKeyEvent eventWithTitle:NSLocalizedString(@"Media Rewind 2 Key", nil) command:@"REWIND2"],
                    [XXTKeyEvent eventWithTitle:NSLocalizedString(@"Media Play/Pause Key", nil) command:@"PLAYPAUSE"],
            ]
    ];
    
    NSString *selectedCommand = self.pickerMeta[@"default"];
    if ([selectedCommand isKindOfClass:[NSString class]]) {
        self.selectedCommand = selectedCommand;
    } else {
        self.selectedCommand = self.events[0][0].command;
    }
    
    self.view.backgroundColor = [UIColor whiteColor];

    UITableView * tableView1 = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    tableView1.delegate = self;
    tableView1.dataSource = self;
    tableView1.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    XXTP_START_IGNORE_PARTIAL
    if (XXTP_SYSTEM_9) {
        tableView1.cellLayoutMarginsFollowReadableWidth = NO;
    }
    XXTP_END_IGNORE_PARTIAL
    self.tableView = tableView1;
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }

    [self.view addSubview:tableView1];

    UIBarButtonItem *rightItem = NULL;
    if ([self.pickerTask taskFinished]) {
        rightItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(taskFinished:)];
    } else {
        rightItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Next", nil) style:UIBarButtonItemStylePlain target:self action:@selector(taskNextStep:)];
    }
    self.navigationItem.rightBarButtonItem = rightItem;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSString *subtitle = nil;
    if (self.pickerMeta[@"subtitle"]) {
        subtitle = self.pickerMeta[@"subtitle"];
    } else {
        subtitle = NSLocalizedString(@"Select a key event", nil);
    }
    [self updateSubtitle:subtitle];
}

- (void)viewSafeAreaInsetsDidChange {
    [super viewSafeAreaInsetsDidChange];
    UIEdgeInsets insets1 = self.tableView.contentInset;
    insets1.bottom -= self.view.safeAreaInsets.bottom;
    UIEdgeInsets insets2 = self.tableView.scrollIndicatorInsets;
    insets2.bottom -= self.view.safeAreaInsets.bottom;
    self.tableView.contentInset = insets1;
    self.tableView.scrollIndicatorInsets = insets2;
}

#pragma mark - Task Operations

- (void)taskFinished:(UIBarButtonItem *)sender {
    [self.pickerFactory performFinished:self];
}

- (void)taskNextStep:(UIBarButtonItem *)sender {
    [self.pickerFactory performNextStep:self];
}

- (void)updateSubtitle:(NSString *)subtitle {
    _pickerSubtitle = subtitle;
    [self.pickerFactory performUpdateStep:self];
}

- (NSString *)pickerSubtitle {
    return _pickerSubtitle;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.events.count;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    header.textLabel.font = [UIFont systemFontOfSize:14.0];
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(nonnull UIView *)view forSection:(NSInteger)section {
    if (tableView.style == UITableViewStylePlain) {
        UITableViewHeaderFooterView *footer = (UITableViewHeaderFooterView *)view;
        footer.textLabel.font = [UIFont systemFontOfSize:12.0];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return self.sectionNames[(NSUInteger) section];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.events[(NSUInteger) section].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kXXTKeyEventTableViewCellReuseIdentifier];
    if (nil == cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:kXXTKeyEventTableViewCellReuseIdentifier];
    }
    XXTKeyEvent *keyEvent = self.events[(NSUInteger) indexPath.section][(NSUInteger) indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%@ (%@)", keyEvent.title, keyEvent.command];
    cell.textLabel.font = [UIFont fontWithName:@"Courier" size:16.0f];
    cell.tintColor = XXTColorForeground();
    if ([self.selectedCommand isEqualToString:keyEvent.command]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    for (UITableViewCell *cell in tableView.visibleCells) {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    UITableViewCell *cell1 = [tableView cellForRowAtIndexPath:indexPath];
    cell1.accessoryType = UITableViewCellAccessoryCheckmark;
    [self updateSubtitle:cell1.textLabel.text];
    XXTKeyEvent *keyEvent = self.events[(NSUInteger) indexPath.section][(NSUInteger) indexPath.row];
    self.selectedCommand = keyEvent.command;
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [%@ dealloc]", NSStringFromClass([self class]));
#endif
}

@end
