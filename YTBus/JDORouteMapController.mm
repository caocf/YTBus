//
//  JDORouteMapController.m
//  YTBus
//
//  Created by zhang yi on 14-11-25.
//  Copyright (c) 2014年 胶东在线. All rights reserved.
//

#import "JDORouteMapController.h"
#import "JDOConstants.h"
#import "JDOUtils.h"
#import "math.h"

#define MYBUNDLE_NAME @ "mapapi.bundle"
#define MYBUNDLE_PATH [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent: MYBUNDLE_NAME]
#define MYBUNDLE [NSBundle bundleWithPath: MYBUNDLE_PATH]

@interface RouteAnnotation : BMKPointAnnotation

@property (nonatomic) int type; ///<0:起点 1：终点 2：公交 3：步行
@property (nonatomic) int degree;
@end

@implementation RouteAnnotation

@end

@interface JDORouteMapController () <BMKMapViewDelegate,UITableViewDelegate,UITableViewDataSource>

@property (nonatomic,weak) IBOutlet BMKMapView *mapView;
@property (nonatomic,weak) IBOutlet UITableView *tableView;
@property (nonatomic,weak) IBOutlet UILabel *lineLabel;

@end

@implementation JDORouteMapController{
    NSInteger firstBusRow;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _mapView.zoomEnabled = true;
    _mapView.zoomEnabledWithTap = true;
    _mapView.scrollEnabled = true;
    _mapView.rotateEnabled = true;
    _mapView.overlookEnabled = false;
    _mapView.showMapScaleBar = false;
    _mapView.minZoomLevel = 11;
    
    _lineLabel.text = self.lineTitle;
}

- (void)mapViewDidFinishLoading:(BMKMapView *)mapView{
    CLLocationDegrees latitude = (_route.starting.location.latitude + _route.terminal.location.latitude)/2.0f;
    CLLocationDegrees longitude = (_route.starting.location.longitude + _route.terminal.location.longitude)/2.0f;
    CLLocationCoordinate2D center = CLLocationCoordinate2DMake(latitude, longitude);
    
    CLLocationDegrees longitudeDelta = fabs(_route.starting.location.longitude - _route.terminal.location.longitude);
    CLLocationDegrees latitudeDelta = fabs(_route.starting.location.latitude - _route.terminal.location.latitude);
    BMKCoordinateRegion mapRegion = [mapView regionThatFits:BMKCoordinateRegionMake(center,BMKCoordinateSpanMake(latitudeDelta,longitudeDelta))];
    [mapView setRegion:mapRegion animated:false];
    
    
    // 计算路线方案中的路段数目
    NSUInteger size = [_route.steps count];
    int planPointCounts = 0;
    for (int i = 0; i < size; i++) {
        BMKTransitStep* transitStep = [_route.steps objectAtIndex:i];
        if(i==0){
            RouteAnnotation* item = [[RouteAnnotation alloc] init];
            item.coordinate = _route.starting.location;
            item.type = 0;
            [_mapView addAnnotation:item]; // 添加起点标注
        }else if(i==size-1){
            RouteAnnotation* item = [[RouteAnnotation alloc] init];
            item.coordinate = _route.terminal.location;
            item.type = 1;
            [_mapView addAnnotation:item]; // 添加起点标注
        }
        if (i!=0) {
            RouteAnnotation* item = [[RouteAnnotation alloc] init];
            item.coordinate = transitStep.entrace.location;
            if (transitStep.vehicleInfo.title) {
                item.title = transitStep.vehicleInfo.title;
            }
            if (transitStep.stepType == BMK_BUSLINE) {
                item.type = 2;
            }else if (transitStep.stepType == BMK_WAKLING){
                item.type = 3;
            }
            [_mapView addAnnotation:item];
        }
        //轨迹点总数累计
        planPointCounts += transitStep.pointsCount;
    }
    
    //轨迹点
    BMKMapPoint * temppoints = new BMKMapPoint[planPointCounts];
    int i = 0;
    for (int j = 0; j < size; j++) {
        BMKTransitStep* transitStep = [_route.steps objectAtIndex:j];
        int k=0;
        for(k=0;k<transitStep.pointsCount;k++) {
            temppoints[i].x = transitStep.points[k].x;
            temppoints[i].y = transitStep.points[k].y;
            i++;
        }
    }
    
    // 通过points构建BMKPolyline
    BMKPolyline* polyLine = [BMKPolyline polylineWithPoints:temppoints count:planPointCounts];
    [_mapView addOverlay:polyLine]; // 添加路线overlay
    delete []temppoints;
}

- (BMKAnnotationView *)mapView:(BMKMapView *)view viewForAnnotation:(id <BMKAnnotation>)annotation{
    if ([annotation isKindOfClass:[RouteAnnotation class]]) {
        return [self getRouteAnnotationView:view viewForAnnotation:(RouteAnnotation*)annotation];
    }
    return nil;
}

- (BMKOverlayView*)mapView:(BMKMapView *)map viewForOverlay:(id<BMKOverlay>)overlay{
    if ([overlay isKindOfClass:[BMKPolyline class]]) {
        BMKPolylineView* polylineView = [[BMKPolylineView alloc] initWithOverlay:overlay];
        polylineView.fillColor = [[UIColor cyanColor] colorWithAlphaComponent:1];
        polylineView.strokeColor = [UIColor colorWithRed:55/255.0f green:170/255.0f blue:50/255.0f alpha:1.0f];
        polylineView.lineWidth = 3.0;
        return polylineView;
    }
    return nil;
}

- (NSString*)getMyBundlePath1:(NSString *)filename{
    NSBundle * libBundle = MYBUNDLE ;
    if ( libBundle && filename ){
        NSString * s=[[libBundle resourcePath ] stringByAppendingPathComponent : filename];
        return s;
    }
    return nil ;
}

- (BMKAnnotationView*)getRouteAnnotationView:(BMKMapView *)mapview viewForAnnotation:(RouteAnnotation*)routeAnnotation{
    BMKAnnotationView *view = nil;
    switch (routeAnnotation.type) {
        case 0:{
            view = [mapview dequeueReusableAnnotationViewWithIdentifier:@"start_node"];
            if (view == nil) {
                view = [[BMKAnnotationView alloc] initWithAnnotation:routeAnnotation reuseIdentifier:@"start_node"];
                view.image = [UIImage imageNamed:@"换乘-起步"];
                view.centerOffset = CGPointMake(0, -(view.frame.size.height * 0.5));
                view.canShowCallout = false;
            }
            view.annotation = routeAnnotation;
        }
            break;
        case 1:{
            view = [mapview dequeueReusableAnnotationViewWithIdentifier:@"end_node"];
            if (view == nil) {
                view = [[BMKAnnotationView alloc] initWithAnnotation:routeAnnotation reuseIdentifier:@"end_node"];
                view.image = [UIImage imageNamed:@"换乘-终点"];
                view.centerOffset = CGPointMake(0, -(view.frame.size.height * 0.5));
                view.canShowCallout = false;
            }
            view.annotation = routeAnnotation;
        }
            break;
        case 2:{
            view = [mapview dequeueReusableAnnotationViewWithIdentifier:@"bus_node"];
            if (view == nil) {
                view = [[BMKAnnotationView alloc] initWithAnnotation:routeAnnotation reuseIdentifier:@"bus_node"];
                view.image = [UIImage imageNamed:@"换乘-车"];
                view.canShowCallout = true;
            }
            view.annotation = routeAnnotation;
        }
            break;
        case 3:{
            view = [mapview dequeueReusableAnnotationViewWithIdentifier:@"walk_node"];
            if (view == nil) {
                view = [[BMKAnnotationView alloc] initWithAnnotation:routeAnnotation reuseIdentifier:@"walk_node"];
                view.image = [UIImage imageNamed:@"换乘-走"];
                view.canShowCallout = false;
            }
            view.annotation = routeAnnotation;
        }
            break;
        default:
            break;
    }
    
    return view;
}


-(void)viewWillAppear:(BOOL)animated {
    [MobClick beginLogPageView:@"transfermap"];
    [MobClick event:@"transfermap"];
    [MobClick beginEvent:@"transfermap"];
    
    _mapView.delegate = self;
    [_mapView viewWillAppear];
}

-(void)viewWillDisappear:(BOOL)animated {
    [MobClick endLogPageView:@"transfermap"];
    [MobClick endEvent:@"transfermap"];
    
    [_mapView viewWillDisappear];
    _mapView.delegate = nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.route.steps.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    BMKTransitStep *step = self.route.steps[indexPath.row];
    float contentHeight = [JDOUtils JDOSizeOfString:step.instruction :CGSizeMake(256.0f, MAXFLOAT) :[UIFont systemFontOfSize:14] :NSLineBreakByWordWrapping :0].height+2;
    return contentHeight + 24;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    BMKTransitStep *step = self.route.steps[indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"StepCell"]; // forIndexPath:indexPath];
    UIImageView *bg = (UIImageView *)[cell viewWithTag:1000];
    UIImageView *iv = (UIImageView *)[cell viewWithTag:1001];
    UILabel *label = (UILabel *)[cell viewWithTag:1002];
    UIImageView *separator = (UIImageView *)[cell viewWithTag:1003];
    float rowHeight = [self tableView:tableView heightForRowAtIndexPath:indexPath];
    label.frame = CGRectMake(50, 12, 256, rowHeight-24);
    label.text = step.instruction;
    separator.frame = CGRectMake(50, rowHeight-1, 256, 1);
    iv.frame = CGRectMake(10, (rowHeight-42)/2, 22, 42);
    if (indexPath.row == 0) {
        bg.frame = CGRectMake(10, rowHeight/2, 22, rowHeight/2);
        iv.image = [UIImage imageNamed:@"换乘-起"];
    }else if (indexPath.row == self.route.steps.count-1){
        bg.frame = CGRectMake(10, 0, 22, rowHeight/2);
        iv.image = [UIImage imageNamed:@"换乘-终"];
    }else if (step.stepType == BMK_WAKLING) {
        bg.frame = CGRectMake(10, 0, 22, rowHeight);
        iv.image = [UIImage imageNamed:@"换乘-步行"];
    }else if(step.stepType == BMK_BUSLINE){
        bg.frame = CGRectMake(10, 0, 22, rowHeight);
        if (firstBusRow == 0) {
            firstBusRow = indexPath.row;
            iv.image = [UIImage imageNamed:@"换乘-上车"];
        }else if(firstBusRow == indexPath.row){
            iv.image = [UIImage imageNamed:@"换乘-上车"];
        }else{
            iv.image = [UIImage imageNamed:@"换乘-换成"];
        }
    }
    return cell;
}

@end
