//
//  JDOLocationMapController.m
//  YTBus
//
//  Created by zhang yi on 14-11-27.
//  Copyright (c) 2014年 胶东在线. All rights reserved.
//

#import "JDOLocationMapController.h"
#import "BMapKit.h"
#import "AppDelegate.h"
#import "CMPopTipView.h"
#import "JDOInterChangeController.h"
#import "JDOConstants.h"

@interface JDOLocationMapController () <BMKMapViewDelegate,BMKLocationServiceDelegate,UINavigationBarDelegate,BMKGeoCodeSearchDelegate>{
    BMKLocationService *_locService;
    BMKGeoCodeSearch *_searcher;
    UIImageView *marker;
    CMPopTipView *popTipView;
    BMKPoiInfo *poi;
}

@property (nonatomic,assign) IBOutlet BMKMapView *mapView;

@end

@implementation JDOLocationMapController

// storyboard中添加navigationbar无法调整高度(44)，方案1：手动调整frame，方案2：设置delegate实现positionForBar
- (UIBarPosition)positionForBar:(id <UIBarPositioning>)bar{
    return UIBarPositionTopAttached;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _mapView.zoomEnabled = true;
    _mapView.zoomEnabledWithTap = true;
    _mapView.scrollEnabled = true;
    _mapView.rotateEnabled = true;
    _mapView.overlookEnabled = false;
    _mapView.showMapScaleBar = false;
    _mapView.minZoomLevel = 12;
    // 进入时候根据传入的定位位置进行设置(定位位置保存为全局变量)，并相应增大初始化时候的缩放级别
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (self.initialPoi) {
        _mapView.centerCoordinate = self.initialPoi.pt;
        _mapView.zoomLevel = 15;
    }else if (delegate.userLocation) {
        CLLocationCoordinate2D coor = delegate.userLocation.location.coordinate;
        if (coor.latitude>YT_MIN_Y && coor.latitude<YT_MAX_Y && coor.longitude>YT_MIN_X && coor.longitude<YT_MAX_X) {
            _mapView.centerCoordinate = delegate.userLocation.location.coordinate;
            _mapView.zoomLevel = 15;
        }else{  // 若定位范围出现偏差，超出烟台市区范围，则指向市政府位置
            _mapView.centerCoordinate = CLLocationCoordinate2DMake(37.4698,121.454);
            _mapView.zoomLevel = 13;
        }
    }else{
        _mapView.centerCoordinate = CLLocationCoordinate2DMake(37.4698,121.454);   // 市政府的位置
        _mapView.zoomLevel = 13;
    }
    
    _locService = [[BMKLocationService alloc] init];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated {
    _mapView.delegate = self;
    [_mapView viewWillAppear];
    
//    _searcher.delegate = self;
    _locService.delegate = self;
    [_locService startUserLocationService];
    _mapView.showsUserLocation = NO;
//    _mapView.userTrackingMode = BMKUserTrackingModeNone;//设置定位的状态
//    _mapView.showsUserLocation = YES;
//    BMKLocationViewDisplayParam *param = [BMKLocationViewDisplayParam new];
//    param.isAccuracyCircleShow = false;
//    [_mapView updateLocationViewWithParam:param];
}

-(void)viewWillDisappear:(BOOL)animated {
    [_mapView viewWillDisappear];
    _mapView.delegate = nil;
    
    [_locService stopUserLocationService];
    _locService.delegate = nil;
    _searcher.delegate = nil;
    _mapView.showsUserLocation = NO;
}

- (void)didUpdateBMKUserLocation:(BMKUserLocation *)userLocation{
    [_mapView updateLocationData:userLocation];
}

- (IBAction)close:(id)sender{
    [self.presentingViewController dismissViewControllerAnimated:true completion:^{
        
    }];
}

- (IBAction)confirm:(id)sender{
    if (_startOrEnd == 0) {
        self.parentVC.startPoi = poi;
        self.parentVC.startField.text = poi.name?poi.name:poi.address;
    }else if(_startOrEnd == 1){
        self.parentVC.endPoi = poi;
        self.parentVC.endField.text = poi.name?poi.name:poi.address;
    }
    [self.presentingViewController dismissViewControllerAnimated:true completion:^{
        
    }];
}

- (void)mapViewDidFinishLoading:(BMKMapView *)mapView{
    CGPoint p = [_mapView convertCoordinate:_mapView.centerCoordinate toPointToView:self.view];
    marker = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"location_marker"]];
    marker.frame = CGRectMake(p.x-11, p.y-16, 22, 32);
    [self.view addSubview:marker];
    if (self.initialPoi) {
        [self createPopViewTitle:self.initialPoi.name message:self.initialPoi.address];
    }else{
        [self mapView:mapView regionDidChangeAnimated:true];
    }
    
}

- (void)mapView:(BMKMapView *)mapView regionDidChangeAnimated:(BOOL)animated{
    if (popTipView) {
        [popTipView dismissAnimated:true];
        popTipView = nil;
    }
    _searcher =[[BMKGeoCodeSearch alloc] init];
    _searcher.delegate = self;
    BMKReverseGeoCodeOption *reverseGeoCodeSearchOption = [[BMKReverseGeoCodeOption alloc] init];
    reverseGeoCodeSearchOption.reverseGeoPoint = mapView.centerCoordinate;
    BOOL flag = [_searcher reverseGeoCode:reverseGeoCodeSearchOption];
    if(!flag){
        NSLog(@"反geo检索发送失败");
    }
}

-(void) onGetReverseGeoCodeResult:(BMKGeoCodeSearch *)searcher result: (BMKReverseGeoCodeResult *)result errorCode:(BMKSearchErrorCode)error{
    if (_searcher != searcher) {
        return;
    }
    if (error == BMK_SEARCH_NO_ERROR) {
        NSString *title, *detail;
        if (result.poiList.count>0) {
            poi = (BMKPoiInfo *)result.poiList[0];
            title = poi.name;
            detail = poi.address;
        }else{
            title = nil;
            detail = [[result.addressDetail.district stringByAppendingString:result.addressDetail.streetName] stringByAppendingString:result.addressDetail.streetNumber];
            poi = [[BMKPoiInfo alloc] init];
            poi.address = detail;
            poi.pt = result.location;
        }
        [self createPopViewTitle:title message:detail];
    }else{
        NSLog(@"抱歉，未找到结果");
    }
}
- (void) createPopViewTitle:(NSString *)title message:(NSString *)message {
    popTipView = [[CMPopTipView alloc] initWithTitle:title message:message];
    popTipView.disableTapToDismiss = true;
    popTipView.preferredPointDirection = PointDirectionDown;
    popTipView.hasGradientBackground = NO;
    popTipView.cornerRadius = 6.0f;
    popTipView.sidePadding = 10.0f;
    popTipView.maxWidth = 200;
    popTipView.topMargin = 0;
    popTipView.pointerSize = 6.0f;
    popTipView.hasShadow = true;
    popTipView.backgroundColor = [UIColor whiteColor];
    popTipView.titleColor = [UIColor colorWithHex:@"37aa32"];
    popTipView.titleAlignment = NSTextAlignmentLeft;
    popTipView.textColor = [UIColor colorWithHex:@"969696"];
    popTipView.textAlignment = NSTextAlignmentLeft;
    popTipView.animation = CMPopTipAnimationPop;
    popTipView.has3DStyle = false;
    popTipView.dismissTapAnywhere = false;
    popTipView.borderWidth = 0;
    popTipView.titleMessagePadding = 5.0f;
    [popTipView presentPointingAtView:marker inView:self.view animated:YES];
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
