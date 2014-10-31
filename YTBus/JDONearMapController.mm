//
//  JDONearMapController.m
//  YTBus
//
//  Created by zhang yi on 14-10-30.
//  Copyright (c) 2014年 胶东在线. All rights reserved.
//

#import "JDONearMapController.h"
#import "JDOStationModel.h"

@interface JDONearMapController () <BMKMapViewDelegate> {
    BMKMapView *_mapView;
}

@end

@implementation JDONearMapController

- (void)viewDidLoad {
    [super viewDidLoad];

    _mapView = (BMKMapView *)self.view;
    
    _mapView.centerCoordinate = self.centerCoor;
    _mapView.zoomEnabled = true;
    _mapView.zoomEnabledWithTap = true;
    _mapView.scrollEnabled = true;
    [_mapView setZoomLevel:17];
}

-(void)viewWillAppear:(BOOL)animated {
    [_mapView viewWillAppear];
    _mapView.delegate = self;
}

-(void)viewDidAppear:(BOOL)animated {
    // 在viewDidLoad里设置annotation的话，因为mapView的delegate还没有设置，导致无法执行回调
    JDOStationModel *myPosition = [JDOStationModel new];
    myPosition.name = @"我的位置";
    myPosition.gpsX = [NSNumber numberWithDouble:self.centerCoor.longitude];
    myPosition.gpsY = [NSNumber numberWithDouble:self.centerCoor.latitude];
    [self addPointAnnotation:myPosition];
    
    for (int i=0; i<self.nearbyStations.count; i++) {
        [self addPointAnnotation:self.nearbyStations[i]];
    }
}

-(void)viewWillDisappear:(BOOL)animated {
    [_mapView viewWillDisappear];
    _mapView.delegate = nil;
}

- (void)addPointAnnotation:(JDOStationModel *) station{
    BMKPointAnnotation *pointAnnotation = [[BMKPointAnnotation alloc] init];
    pointAnnotation.coordinate = CLLocationCoordinate2DMake(station.gpsY.doubleValue, station.gpsX.doubleValue);
    pointAnnotation.title = station.name;
    //    pointAnnotation.subtitle = @"此Annotation可拖拽!";
    [_mapView addAnnotation:pointAnnotation];
}

- (BMKAnnotationView *)mapView:(BMKMapView *)mapView viewForAnnotation:(id <BMKAnnotation>)annotation
{
    NSString *AnnotationViewID = [annotation title];
    BMKAnnotationView *newAnnotation = [[BMKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:AnnotationViewID];
    if ([AnnotationViewID isEqualToString:@"我的位置"]) {
        ((BMKPinAnnotationView*)newAnnotation).pinColor = BMKPinAnnotationColorGreen;
    }else{
        ((BMKPinAnnotationView*)newAnnotation).pinColor = BMKPinAnnotationColorPurple;
    }
    ((BMKPinAnnotationView*)newAnnotation).animatesDrop = YES;
    ((BMKPinAnnotationView*)newAnnotation).draggable = false;
    return newAnnotation;
    
}

// 当点击annotation view弹出的泡泡时，调用此接口
- (void)mapView:(BMKMapView *)mapView annotationViewForBubble:(BMKAnnotationView *)view;
{
    NSLog(@"paopaoclick");
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
