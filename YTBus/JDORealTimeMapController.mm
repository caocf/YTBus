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
#import "JDOConstants.h"
#import "JSONKit.h"
#import "JDOBusModel.h"

@interface JDORealTimeMapController () <BMKMapViewDelegate,NSXMLParserDelegate>{
    int count;
    NSTimer *_timer;
    NSURLConnection *_connection;
    NSMutableData *_webData;
    NSMutableString *_jsonResult;
    BOOL isRecording;
    NSMutableArray *_buses;
    NSMutableArray *_drawedBusAnnotations;
    NSMutableArray *_stationAnnotations;
}

@end

@implementation JDORealTimeMapController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _mapView.zoomEnabled = true;
    _mapView.zoomEnabledWithTap = true;
    _mapView.scrollEnabled = true;
    _mapView.rotateEnabled = false;
    _mapView.overlookEnabled = false;
    _mapView.showMapScaleBar = false;
    _mapView.zoomLevel = 13;
    _mapView.delegate = self;
    
    [self setMapCenter];
    [self addStationOverlay];
    
    _buses = [NSMutableArray new];
    _drawedBusAnnotations = [NSMutableArray new];
    _stationAnnotations = [NSMutableArray new];
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
        if (station.gpsY.doubleValue < minY){
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
    _timer = [NSTimer scheduledTimerWithTimeInterval:Bus_Refresh_Interval target:self selector:@selector(refreshData:) userInfo:nil repeats:true];
    [_timer fire];
}

-(void)viewWillDisappear:(BOOL)animated {
    [_mapView viewWillDisappear];
    if ( _timer && _timer.valid) {
        [_timer invalidate];
        _timer = nil;
    }
}

- (void) refreshData:(NSTimer *)timer{
    NSString *soapMessage = [NSString stringWithFormat:GetBusLineStatus_MSG,_stationId,_lineId,_lineStatus];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:GetBusLineStatus_URL]];
    [request addValue:@"text/xml; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"http://www.dongfang-china.com/GetBusLineStatus" forHTTPHeaderField:@"SOAPAction"];
    [request addValue:[NSString stringWithFormat:@"%d",[soapMessage length]] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[soapMessage dataUsingEncoding:NSUTF8StringEncoding]];
    if (_connection) {
        [_connection cancel];
    }
    _connection = [NSURLConnection connectionWithRequest:request delegate:self];
    _webData = [NSMutableData data];
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    [_webData appendData:data];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection{
    NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData: _webData];
    [xmlParser setDelegate: self];
    [xmlParser parse];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    [JDOUtils showHUDText:[NSString stringWithFormat:@"无法获取实时数据：%@",error] inView:self.view];
}

-(void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *) namespaceURI qualifiedName:(NSString *)qName attributes: (NSDictionary *)attributeDict{
    if( [elementName isEqualToString:@"GetBusLineStatusResult"]){
        _jsonResult = [[NSMutableString alloc] init];
        isRecording = true;
    }
}

-(void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string{
    if( isRecording ){
        [_jsonResult appendString: string];
    }
}

-(void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName{
    if( [elementName isEqualToString:@"GetBusLineStatusResult"]){
        NSLog(@"%@",_jsonResult);
        isRecording = false;
        if (_jsonResult.length==0) {
            [JDOUtils showHUDText:@"没有满足条件的车辆信息" inView:self.view];
            // 删除掉已经绘制的所有车辆，可能发生的情景是：最后一辆车开过参考站点，则要删除该车辆
            if (_buses.count>0) {
                [_buses removeAllObjects];
                [self redrawBus];
            }
        }else{
            NSArray *list = [_jsonResult objectFromJSONString];
            if (!list) {
                [JDOUtils showHUDText:@"实时数据JSON格式错误" inView:self.view];
            }else{
                [_buses removeAllObjects];
                for (int i=0; i<list.count; i++){
                    JDOBusModel *bus = [JDOBusModel new];
                    NSDictionary *dict = [list objectAtIndex:i];
                    bus.busId = [dict objectForKey:@"ID"];
                    bus.busNo = [dict objectForKey:@"车牌"];
                    bus.toStationId = [dict objectForKey:@"站"];
                    bus.gpsX = [NSNumber numberWithDouble:[(NSString *)[dict objectForKey:@"GPSX"] doubleValue]];
                    bus.gpsY = [NSNumber numberWithDouble:[(NSString *)[dict objectForKey:@"GPSY"] doubleValue]];
                    [_buses addObject:bus];
                }
                [self redrawBus];
            }
        }
    }
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError{
    [JDOUtils showHUDText:[NSString stringWithFormat:@"解析实时数据XML时出现错误：%@",parseError] inView:self.view];
}

- (void) redrawBus{
    // 删除上次绘制的车辆
    for (int i=0; i<_drawedBusAnnotations.count; i++) {
        [_mapView removeAnnotation:_drawedBusAnnotations[i]];
    }
    [_drawedBusAnnotations removeAllObjects];
    
    for (int i=0; i<_buses.count; i++){
        JDOBusModel *bus = _buses[i];

        BMKPointAnnotation *annotation = [[BMKPointAnnotation alloc] init];
        annotation.coordinate = BMKCoorDictionaryDecode(BMKConvertBaiduCoorFrom(CLLocationCoordinate2DMake(bus.gpsY.doubleValue, bus.gpsX.doubleValue),BMK_COORDTYPE_GPS));
        annotation.title = bus.busNo;
        [_mapView addAnnotation:annotation];
        
        [_drawedBusAnnotations addObject:annotation];
    }
}

- (void)mapStatusDidChanged:(BMKMapView *)mapView{
    BMKMapStatus *status = [mapView getMapStatus];
    if (status.fLevel>14) { // 用annotation显示站点
        if (_mapView.overlays.count>0) {
            [_mapView removeOverlays:[NSArray arrayWithArray:_mapView.overlays]];
            [self addStationAnnotation];
        }
    }else{  // 用overlay显示站点
        if (_stationAnnotations.count>0) {
            [_mapView removeAnnotations:_stationAnnotations];
            [_stationAnnotations removeAllObjects];
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
}

-(void)addStationAnnotation{
    [_stationAnnotations removeAllObjects];
    for (int i=0; i<_stations.count; i++) {
        JDOStationModel *station = _stations[i];
        JDOStationAnnotation *annotation = [[JDOStationAnnotation alloc] init];
        annotation.coordinate = CLLocationCoordinate2DMake(station.gpsY.doubleValue, station.gpsX.doubleValue);
        annotation.title = station.name;
        annotation.station = station;
        [_mapView addAnnotation:annotation];
        [_stationAnnotations addObject:annotation];
    }
}

- (BMKAnnotationView *)mapView:(BMKMapView *)mapView viewForAnnotation:(id <BMKAnnotation>)annotation{
    static NSString *AnnotationViewID = @"annotationView";
    BMKAnnotationView *newAnnotation = [[BMKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:AnnotationViewID];
    
    if ([annotation isKindOfClass:[JDOStationAnnotation class]]) {
        JDOStationAnnotation *sa = (JDOStationAnnotation *)annotation;
        if (sa.station.isStart) {
            newAnnotation.image = [UIImage imageNamed:@"second"];
        }else if(sa.station.isEnd){
            newAnnotation.image = [UIImage imageNamed:@"first"];
        }else{
            newAnnotation.image = [UIImage imageNamed:@"first"];
        }
    }else{
        newAnnotation.image = [UIImage imageNamed:@"公交"];
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
