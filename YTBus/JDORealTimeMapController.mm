//
//  JDORealTimeMapController.m
//  YTBus
//
//  Created by zhang yi on 14-11-10.
//  Copyright (c) 2014年 胶东在线. All rights reserved.
//

#import "JDORealTimeMapController.h"
#import "JDOStationModel.h"
#import "JDOStationAnnotation.h"

@interface JDORealTimeMapController () <BMKMapViewDelegate>{
    int count;
}

@end

@implementation JDORealTimeMapController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _mapView.zoomEnabled = true;
    _mapView.zoomEnabledWithTap = true;
    _mapView.scrollEnabled = true;
    _mapView.zoomLevel = 13;
    _mapView.delegate = self;
    
    [self setMapCenter];
    [self addStationOverlay];
}

- (void) setMapCenter{
    // 将地图的中心定位到所有站点的中心。所有站点的经纬度大致范围应该是北纬37-38，东经121-122
    double minX = 180, minY = 180, maxX = 0, maxY = 0;
    for (int i=0; i<_stations.count; i++) {
        JDOStationModel *station = _stations[i];
        // 有的站点没有gps数据
        if (station.gpsX.doubleValue == 0.0 || station.gpsY.doubleValue == 0.0) {
            continue;
        }
        if (station.gpsX.doubleValue < minX) {
            minX = station.gpsX.doubleValue;
        }
        if(station.gpsX.doubleValue > maxX ){
            maxX = station.gpsX.doubleValue;
        }
        if (station.gpsY.doubleValue < minY) {
            minY = station.gpsY.doubleValue;
        }
        if(station.gpsY.doubleValue > maxY ){
            maxY = station.gpsY.doubleValue;
        }
    }
    _mapView.centerCoordinate = CLLocationCoordinate2DMake( (maxY+minY)/2, (maxX+minX)/2);
}

-(void)viewWillAppear:(BOOL)animated {
    [_mapView viewWillAppear];
}

-(void)viewWillDisappear:(BOOL)animated {
    [_mapView viewWillDisappear];
}

- (void)mapStatusDidChanged:(BMKMapView *)mapView{
    BMKMapStatus *status = [mapView getMapStatus];
    if (status.fLevel>14) { // 用annotation显示站点
        if (_mapView.overlays.count>0) {
            [_mapView removeOverlays:[_mapView.overlays copy]];
            [self addStationAnnotation];
        }
    }else{  // 用overlay显示站点
        if (_mapView.annotations.count>0) {
            [_mapView removeAnnotations:[_mapView.annotations copy]];
            [self addStationOverlay];
        }
    }
}


-(void)addStationOverlay{
    count = 1;
    for (int i=0; i<_stations.count; i++) {
        JDOStationModel *station = _stations[i];
        BMKCircle *circle = [BMKCircle circleWithCenterCoordinate:CLLocationCoordinate2DMake(station.gpsY.doubleValue, station.gpsX.doubleValue) radius:300];
        [_mapView addOverlay:circle];
    }
}

- (BMKOverlayView *)mapView:(BMKMapView *)mapView viewForOverlay:(id <BMKOverlay>)overlay
{
    BMKCircleView* circleView = [[BMKCircleView alloc] initWithOverlay:overlay];
    circleView.fillColor = [UIColor colorWithRed:0.43f green:0.26f blue:0.88f alpha:1.0f];
    circleView.strokeColor = [UIColor blueColor] ;
    circleView.lineWidth = 1.0;
    
    UILabel *num = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
    num.text = [NSString stringWithFormat:@"%d",count++];
    num.center = circleView.center;
    [circleView addSubview:num];
    
    return circleView;

//    if ([overlay isKindOfClass:[BMKGroundOverlay class]])
//    {
//        BMKGroundOverlayView* groundView = [[[BMKGroundOverlayView alloc] initWithOverlay:overlay] autorelease];
//        return groundView;
//    }
}

-(void)addStationAnnotation{
    for (int i=0; i<_stations.count; i++) {
        JDOStationModel *station = _stations[i];
        JDOStationAnnotation *annotation = [[JDOStationAnnotation alloc] init];
        annotation.coordinate = CLLocationCoordinate2DMake(station.gpsY.doubleValue, station.gpsX.doubleValue);
        annotation.title = station.name;
        annotation.station = station;
        [_mapView addAnnotation:annotation];                                                                  
    }
}

- (BMKAnnotationView *)mapView:(BMKMapView *)mapView viewForAnnotation:(id <BMKAnnotation>)annotation{
    static NSString *AnnotationViewID = @"annotationView";
    BMKAnnotationView *newAnnotation = [[BMKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:AnnotationViewID];
    JDOStationAnnotation *sa = (JDOStationAnnotation *)annotation;
    if (sa.station.isStart) {
        newAnnotation.image = [UIImage imageNamed:@"second"];
    }else if(sa.station.isEnd){
        newAnnotation.image = [UIImage imageNamed:@"first"];
    }else{
        newAnnotation.image = [UIImage imageNamed:@"first"];
    }
    newAnnotation.draggable = false;
    return newAnnotation;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
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
