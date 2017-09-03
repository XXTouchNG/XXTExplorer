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
@property (nonatomic, strong) NSIndexPath *lastSelected;

@end

@implementation XXTKeyEventPicker {
    NSString *_pickerSubtitle;
}

@synthesize pickerTask = _pickerTask;
@synthesize pickerMeta = _pickerMeta;

#pragma mark - XXTBasePicker

+ (NSString *)pickerKeyword {
    return @"@key@";
}

- (NSString *)pickerResult {
    return self.events[(NSUInteger) self.lastSelected.section][(NSUInteger) self.lastSelected.row].command;
}

#pragma mark - Default Style

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (NSString *)title {
    if (self.pickerMeta[@"title"]) {
        return self.pickerMeta[@"title"];
    } else {
        return NSLocalizedStringFromTableInBundle(@"Key Event", @"XXTPickerCollection", [XXTPickerFactory bundle], nil);
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.lastSelected = [NSIndexPath indexPathForRow:0 inSection:0];
    self.sectionNames = @[
            NSLocalizedStringFromTableInBundle(@"Hardware Keys", @"XXTPickerCollection", [XXTPickerFactory bundle], nil),
            NSLocalizedStringFromTableInBundle(@"Keyboard Keys", @"XXTPickerCollection", [XXTPickerFactory bundle], nil),
            NSLocalizedStringFromTableInBundle(@"Media Keys", @"XXTPickerCollection", [XXTPickerFactory bundle], nil),
    ];
    self.events = @[
            @[
                    [XXTKeyEvent eventWithTitle:NSLocalizedStringFromTableInBundle(@"Home Button", @"XXTPickerCollection", [XXTPickerFactory bundle], nil) command:@"HOMEBUTTON"],
                    [XXTKeyEvent eventWithTitle:NSLocalizedStringFromTableInBundle(@"Volume +", @"XXTPickerCollection", [XXTPickerFactory bundle], nil) command:@"VOLUMEUP"],
                    [XXTKeyEvent eventWithTitle:NSLocalizedStringFromTableInBundle(@"Volume -", @"XXTPickerCollection", [XXTPickerFactory bundle], nil) command:@"VOLUMEDOWN"],
                    [XXTKeyEvent eventWithTitle:NSLocalizedStringFromTableInBundle(@"Power Button", @"XXTPickerCollection", [XXTPickerFactory bundle], nil) command:@"LOCK"],
                    [XXTKeyEvent eventWithTitle:NSLocalizedStringFromTableInBundle(@"Mute Button", @"XXTPickerCollection", [XXTPickerFactory bundle], nil) command:@"MUTE"],
            ],
            @[

                    [XXTKeyEvent eventWithTitle:NSLocalizedStringFromTableInBundle(@"Return Key", @"XXTPickerCollection", [XXTPickerFactory bundle], nil) command:@"RETURN"],
                    [XXTKeyEvent eventWithTitle:NSLocalizedStringFromTableInBundle(@"Esc Key", @"XXTPickerCollection", [XXTPickerFactory bundle], nil) command:@"ESCAPE"],
                    [XXTKeyEvent eventWithTitle:NSLocalizedStringFromTableInBundle(@"Backspace Key", @"XXTPickerCollection", [XXTPickerFactory bundle], nil) command:@"BACKSPACE"],
                    [XXTKeyEvent eventWithTitle:NSLocalizedStringFromTableInBundle(@"Space Key", @"XXTPickerCollection", [XXTPickerFactory bundle], nil) command:@"SPACE"],
                    [XXTKeyEvent eventWithTitle:NSLocalizedStringFromTableInBundle(@"Tab Key", @"XXTPickerCollection", [XXTPickerFactory bundle], nil) command:@"TAB"],
                    [XXTKeyEvent eventWithTitle:NSLocalizedStringFromTableInBundle(@"Spotlight Key", @"XXTPickerCollection", [XXTPickerFactory bundle], nil) command:@"SPOTLIGHT"],
                    [XXTKeyEvent eventWithTitle:NSLocalizedStringFromTableInBundle(@"Bright +", @"XXTPickerCollection", [XXTPickerFactory bundle], nil) command:@"BRIGHTUP"],
                    [XXTKeyEvent eventWithTitle:NSLocalizedStringFromTableInBundle(@"Bright -", @"XXTPickerCollection", [XXTPickerFactory bundle], nil) command:@"BRIGHTDOWN"],
                    [XXTKeyEvent eventWithTitle:NSLocalizedStringFromTableInBundle(@"Show/Hide Keyboard", @"XXTPickerCollection", [XXTPickerFactory bundle], nil) command:@"SHOW_HIDE_KEYBOARD"],
            ],
            @[
                    [XXTKeyEvent eventWithTitle:NSLocalizedStringFromTableInBundle(@"Media Forward Key", @"XXTPickerCollection", [XXTPickerFactory bundle], nil) command:@"FORWARD"],
                    [XXTKeyEvent eventWithTitle:NSLocalizedStringFromTableInBundle(@"Media Rewind Key", @"XXTPickerCollection", [XXTPickerFactory bundle], nil) command:@"REWIND"],
                    [XXTKeyEvent eventWithTitle:NSLocalizedStringFromTableInBundle(@"Media Forward 2 Key", @"XXTPickerCollection", [XXTPickerFactory bundle], nil) command:@"FORWARD2"],
                    [XXTKeyEvent eventWithTitle:NSLocalizedStringFromTableInBundle(@"Media Rewind 2 Key", @"XXTPickerCollection", [XXTPickerFactory bundle], nil) command:@"REWIND2"],
                    [XXTKeyEvent eventWithTitle:NSLocalizedStringFromTableInBundle(@"Media Play/Pause Key", @"XXTPickerCollection", [XXTPickerFactory bundle], nil) command:@"PLAYPAUSE"],
            ]
    ];

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

    [self.view addSubview:tableView1];

    UIBarButtonItem *rightItem = NULL;
    if ([self.pickerTask taskFinished]) {
        rightItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(taskFinished:)];
    } else {
        rightItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Next", @"XXTPickerCollection", [XXTPickerFactory bundle], nil) style:UIBarButtonItemStylePlain target:self action:@selector(taskNextStep:)];
    }
    self.navigationItem.rightBarButtonItem = rightItem;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSString *subtitle = nil;
    if (self.pickerMeta[@"subtitle"]) {
        subtitle = self.pickerMeta[@"subtitle"];
    } else {
        subtitle = NSLocalizedStringFromTableInBundle(@"Select a key event", @"XXTPickerCollection", [XXTPickerFactory bundle], nil);
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
    cell.tintColor = XXTP_PICKER_FRONT_COLOR;
    if (self.lastSelected &&
            self.lastSelected.section == indexPath.section &&
            self.lastSelected.row == indexPath.row) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (self.lastSelected) {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:self.lastSelected];
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    self.lastSelected = indexPath;
    UITableViewCell *cell1 = [tableView cellForRowAtIndexPath:indexPath];
    cell1.accessoryType = UITableViewCellAccessoryCheckmark;
    [self updateSubtitle:cell1.textLabel.text];
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"[XXTKeyEventPicker dealloc]");
#endif
}

@end
