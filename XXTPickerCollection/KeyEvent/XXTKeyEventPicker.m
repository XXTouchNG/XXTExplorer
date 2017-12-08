//
//  XXTKeyEventPicker.m
//  XXTPickerCollection
//
//  Created by Zheng on 30/04/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTKeyEventPicker.h"
#import "XXTKeyEvent.h"
#import "XXTPickerFactory.h"
#import "XXTPickerDefine.h"
#import "XXTPickerSnippet.h"

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
        return NSLocalizedStringFromTable(@"Key Event", @"XXTPickerCollection", nil);
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.sectionNames = @[
            NSLocalizedStringFromTable(@"Hardware Keys", @"XXTPickerCollection", nil),
            NSLocalizedStringFromTable(@"Keyboard Keys", @"XXTPickerCollection", nil),
            NSLocalizedStringFromTable(@"Media Keys", @"XXTPickerCollection", nil),
    ];
    self.events = @[
            @[
                    [XXTKeyEvent eventWithTitle:NSLocalizedStringFromTable(@"Home Button", @"XXTPickerCollection", nil) command:@"HOMEBUTTON"],
                    [XXTKeyEvent eventWithTitle:NSLocalizedStringFromTable(@"Volume +", @"XXTPickerCollection", nil) command:@"VOLUMEUP"],
                    [XXTKeyEvent eventWithTitle:NSLocalizedStringFromTable(@"Volume -", @"XXTPickerCollection", nil) command:@"VOLUMEDOWN"],
                    [XXTKeyEvent eventWithTitle:NSLocalizedStringFromTable(@"Power Button", @"XXTPickerCollection", nil) command:@"LOCK"],
                    [XXTKeyEvent eventWithTitle:NSLocalizedStringFromTable(@"Mute Button", @"XXTPickerCollection", nil) command:@"MUTE"],
            ],
            @[

                    [XXTKeyEvent eventWithTitle:NSLocalizedStringFromTable(@"Return Key", @"XXTPickerCollection", nil) command:@"RETURN"],
                    [XXTKeyEvent eventWithTitle:NSLocalizedStringFromTable(@"Esc Key", @"XXTPickerCollection", nil) command:@"ESCAPE"],
                    [XXTKeyEvent eventWithTitle:NSLocalizedStringFromTable(@"Backspace Key", @"XXTPickerCollection", nil) command:@"BACKSPACE"],
                    [XXTKeyEvent eventWithTitle:NSLocalizedStringFromTable(@"Space Key", @"XXTPickerCollection", nil) command:@"SPACE"],
                    [XXTKeyEvent eventWithTitle:NSLocalizedStringFromTable(@"Tab Key", @"XXTPickerCollection", nil) command:@"TAB"],
                    [XXTKeyEvent eventWithTitle:NSLocalizedStringFromTable(@"Spotlight Key", @"XXTPickerCollection", nil) command:@"SPOTLIGHT"],
                    [XXTKeyEvent eventWithTitle:NSLocalizedStringFromTable(@"Bright +", @"XXTPickerCollection", nil) command:@"BRIGHTUP"],
                    [XXTKeyEvent eventWithTitle:NSLocalizedStringFromTable(@"Bright -", @"XXTPickerCollection", nil) command:@"BRIGHTDOWN"],
                    [XXTKeyEvent eventWithTitle:NSLocalizedStringFromTable(@"Show/Hide Keyboard", @"XXTPickerCollection", nil) command:@"SHOW_HIDE_KEYBOARD"],
            ],
            @[
                    [XXTKeyEvent eventWithTitle:NSLocalizedStringFromTable(@"Media Forward Key", @"XXTPickerCollection", nil) command:@"FORWARD"],
                    [XXTKeyEvent eventWithTitle:NSLocalizedStringFromTable(@"Media Rewind Key", @"XXTPickerCollection", nil) command:@"REWIND"],
                    [XXTKeyEvent eventWithTitle:NSLocalizedStringFromTable(@"Media Forward 2 Key", @"XXTPickerCollection", nil) command:@"FORWARD2"],
                    [XXTKeyEvent eventWithTitle:NSLocalizedStringFromTable(@"Media Rewind 2 Key", @"XXTPickerCollection", nil) command:@"REWIND2"],
                    [XXTKeyEvent eventWithTitle:NSLocalizedStringFromTable(@"Media Play/Pause Key", @"XXTPickerCollection", nil) command:@"PLAYPAUSE"],
            ]
    ];
    
    NSString *selectedCommand = self.pickerMeta[@"default"];
    if (selectedCommand) {
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
        rightItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringFromTable(@"Next", @"XXTPickerCollection", nil) style:UIBarButtonItemStylePlain target:self action:@selector(taskNextStep:)];
    }
    self.navigationItem.rightBarButtonItem = rightItem;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSString *subtitle = nil;
    if (self.pickerMeta[@"subtitle"]) {
        subtitle = self.pickerMeta[@"subtitle"];
    } else {
        subtitle = NSLocalizedStringFromTable(@"Select a key event", @"XXTPickerCollection", nil);
    }
    [self updateSubtitle:subtitle];
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
    cell.textLabel.font = [UIFont fontWithName:@"CourierNewPSMT" size:16.0f];
    cell.tintColor = XXTE_COLOR;
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
    NSLog(@"- [XXTKeyEventPicker dealloc]");
#endif
}

@end
