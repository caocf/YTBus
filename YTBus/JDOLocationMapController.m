//
//  JDOLocationMapController.m
//  YTBus
//
//  Created by zhang yi on 14-11-27.
//  Copyright (c) 2014年 胶东在线. All rights reserved.
//

#import "JDOLocationMapController.h"
#import "BMapKit.h"

@interface JDOLocationMapController () <BMKMapViewDelegate,BMKLocationServiceDelegate>{
    BMKLocationService *_locService;
    BMKMapView *_mapView;
}

@end

@implementation JDOLocationMapController

- (void)viewDidLoad {
    [super viewDidLoad];

    _locService = [[BMKLocationService alloc] init];
    _mapView = (BMKMapView *)self.view;
    _mapView.delegate = self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated {
    [_mapView viewWillAppear];
    if (_locService) {
        _locService.delegate = self;
        [_locService startUserLocationService];
        _mapView.showsUserLocation = NO;
        _mapView.userTrackingMode = BMKUserTrackingModeNone;//设置定位的状态
        _mapView.showsUserLocation = YES;
        BMKLocationViewDisplayParam *param = [BMKLocationViewDisplayParam new];
        param.isAccuracyCircleShow = false;
        [_mapView updateLocationViewWithParam:param];
    }
}

-(void)viewWillDisappear:(BOOL)animated {
    [_mapView viewWillDisappear];
    if (_locService) {
        [_locService stopUserLocationService];
        _locService.delegate = nil;
        _mapView.showsUserLocation = NO;
    }
}

- (void)didUpdateBMKUserLocation:(BMKUserLocation *)userLocation{
    [_mapView updateLocationData:userLocation];
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
