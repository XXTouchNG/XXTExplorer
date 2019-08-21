//
//  XXTLocationPicker.m
//  XXTLocationPicker
//
//  Created by Zheng on 15/04/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTLocationPicker.h"

#import <MapKit/MapKit.h>

#import "XXTPickerDefine.h"
#import "XXTPickerSnippetTask.h"
#import "XXTPickerFactory.h"

static NSString * const kXXTCoordinateRegionLatitudeKey = @"latitude";
static NSString * const kXXTCoordinateRegionLongitudeKey = @"longitude";
static NSString * const kXXTMapViewAnnotationIdentifier = @"kXXTMapViewAnnotationIdentifier";
static NSString * const kXXTMapViewAnnotationFormat = @"Latitude: %f, Longitude: %f";

@interface XXTLocationPicker () <MKMapViewDelegate>
@property (nonatomic, strong) MKMapView *mapView;
@property (nonatomic, strong) MKPointAnnotation *pointAnnotation;

@end

// type
// title
// subtitle

@implementation XXTLocationPicker {
    NSString *_pickerSubtitle;
}

@synthesize pickerTask = _pickerTask;
@synthesize pickerMeta = _pickerMeta;

#pragma mark - XXTBasePicker

+ (NSString *)pickerKeyword {
    return @"loc";
}

- (NSDictionary <NSString *, NSNumber *> *)pickerResult {
    return @{ kXXTCoordinateRegionLatitudeKey: @(self.pointAnnotation.coordinate.latitude), kXXTCoordinateRegionLongitudeKey: @(self.pointAnnotation.coordinate.longitude) };
}

- (NSString *)title {
    if (self.pickerMeta[@"title"]) {
        return self.pickerMeta[@"title"];
    } else {
        return NSLocalizedString(@"Location", nil);
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle {
#ifndef APPSTORE
    return UIStatusBarStyleLightContent;
#else
    return UIStatusBarStyleDefault;
#endif
}

#pragma mark - View

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = XXTColorPlainBackground();
    
    MKMapView *mapView = [[MKMapView alloc] initWithFrame:self.view.bounds];
    mapView.delegate = self;
    mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    mapView.zoomEnabled = YES; mapView.scrollEnabled = YES; mapView.rotateEnabled = YES;
    mapView.showsUserLocation = YES; mapView.showsBuildings = NO; mapView.showsPointsOfInterest = NO;
    XXTP_START_IGNORE_PARTIAL
    if (XXTP_SYSTEM_9) {
        mapView.showsCompass = YES; mapView.showsScale = YES; mapView.showsTraffic = NO;
    }
    XXTP_END_IGNORE_PARTIAL
    self.mapView = mapView;
    
    CLLocationCoordinate2D defaultCoordinate;
    defaultCoordinate.latitude = 39.92f;
    defaultCoordinate.longitude = 116.46f;
    MKCoordinateSpan defaultSpan = {1.f, 1.f};
    MKCoordinateRegion region = {defaultCoordinate, defaultSpan};
    NSDictionary *defaultPosition = self.pickerMeta[@"default"];
    if ([defaultPosition isKindOfClass:[NSDictionary class]]) {
        NSNumber *latitudeObj = defaultPosition[kXXTCoordinateRegionLatitudeKey];
        NSNumber *longitudeObj = defaultPosition[kXXTCoordinateRegionLongitudeKey];
        if (
            [latitudeObj isKindOfClass:[NSNumber class]] && [longitudeObj isKindOfClass:[NSNumber class]]
            ) {
            defaultCoordinate.latitude = [latitudeObj doubleValue];
            defaultCoordinate.longitude = [longitudeObj doubleValue];
        }
    }
    [mapView setRegion:region animated:YES];
    
    MKPointAnnotation *pointAnnotation = [[MKPointAnnotation alloc] init];
    pointAnnotation.title = NSLocalizedString(@"Drag & Drop 📌", nil);
    pointAnnotation.subtitle = [NSString stringWithFormat:NSLocalizedString(kXXTMapViewAnnotationFormat, nil), defaultCoordinate.latitude, defaultCoordinate.longitude];
    pointAnnotation.coordinate = defaultCoordinate;
    [mapView addAnnotation:pointAnnotation];
    [mapView selectAnnotation:pointAnnotation animated:YES];
    self.pointAnnotation = pointAnnotation;
    
    [self.view addSubview:mapView];
    
    UIBarButtonItem *rightItem = NULL;
    if ([self.pickerTask taskFinished]) {
        rightItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(taskFinished:)];
    } else {
        rightItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Next", nil) style:UIBarButtonItemStylePlain target:self action:@selector(taskNextStep:)];
    }
    self.navigationItem.rightBarButtonItem = rightItem;
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSString *subtitle = nil;
    if (self.pickerMeta[@"subtitle"]) {
        subtitle = self.pickerMeta[@"subtitle"];
    } else {
        subtitle = NSLocalizedString(@"Select a location by dragging 📌", nil);
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

#pragma mark - MKMapViewDelegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    if (annotation == mapView.userLocation) {
        return nil;
    }
    
    MKPinAnnotationView *customPinView = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:kXXTMapViewAnnotationIdentifier];
    if (!customPinView) {
        customPinView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:kXXTMapViewAnnotationIdentifier];
        XXTP_START_IGNORE_PARTIAL
        if (XXTP_SYSTEM_9) {
            customPinView.pinTintColor = XXTColorForeground();
        } else {
            customPinView.pinColor = MKPinAnnotationColorRed;
        }
        XXTP_END_IGNORE_PARTIAL
        customPinView.animatesDrop = YES;
        customPinView.canShowCallout = YES;
        customPinView.draggable = YES;
    } else {
        customPinView.annotation = annotation;
    }
    return customPinView;
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view didChangeDragState:(MKAnnotationViewDragState)newState fromOldState:(MKAnnotationViewDragState)oldState {
    MKPointAnnotation *anno = ((MKPointAnnotation *)view.annotation);
    NSString *dragTips = [NSString stringWithFormat:NSLocalizedString(kXXTMapViewAnnotationFormat, nil), anno.coordinate.latitude, anno.coordinate.longitude];
    switch (newState) {
        case MKAnnotationViewDragStateStarting:
            break;
        case MKAnnotationViewDragStateDragging:
            break;
        case MKAnnotationViewDragStateEnding:
            anno.subtitle = dragTips;
            [[NSUserDefaults standardUserDefaults] setObject:@((float) anno.coordinate.latitude) forKey:kXXTCoordinateRegionLatitudeKey];
            [[NSUserDefaults standardUserDefaults] setObject:@((float) anno.coordinate.longitude) forKey:kXXTCoordinateRegionLongitudeKey];
            break;
        default:
            break;
    }
    [self updateSubtitle:dragTips];
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [%@ dealloc]", NSStringFromClass([self class]));
#endif
}

@end
