//
//  JDONearMapController.m
//  YTBus
//
//  Created by zhang yi on 14-10-30.
//  Copyright (c) 2014年 胶东在线. All rights reserved.
//

#import "JDONearMapController.h"
#import "JDOStationModel.h"
#import "JDODatabase.h"
#import "JDOBusLine.h"
#import "JDOStationAnnotation.h"
#import "JDORealTimeController.h"
#import "JDOPaoPaoTable.h"

@interface JDONearMapController () <BMKMapViewDelegate,UITableViewDataSource,UITableViewDelegate> {
    
    NSMutableArray *_stations;
    NSMutableDictionary *_stationLines;
    FMDatabase *_db;
    id dbObserver;
}

@end

@implementation JDONearMapController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _mapView.centerCoordinate = self.centerCoor;
    _mapView.zoomEnabled = true;
    _mapView.zoomEnabledWithTap = true;
    _mapView.scrollEnabled = true;
    _mapView.zoomLevel = 17;
    _mapView.delegate = self;
    
    _db = [JDODatabase sharedDB];
    if (_db) {
        [self loadData];
    }
    dbObserver = [[NSNotificationCenter defaultCenter] addObserverForName:@"db_changed" object:nil queue:nil usingBlock:^(NSNotification *note) {
        _db = [JDODatabase sharedDB];
        [self loadData];
    }];
}

- (void) loadData {
    _stations = [NSMutableArray new];   // 有线路的站点
    _stationLines = [NSMutableDictionary new];
    for(int i=0; i<_nearbyStations.count; i++){
        // 从数据库查询该站点途径的线路
        // 若站点没有公交线路通过，则认为该站点无效，例如7路通过的奥运酒店
        BOOL find = [self findLinesAtStation:_nearbyStations[i]];
        if ( find) {
            [_stations addObject:_nearbyStations[i]];
        }
    }
    [self addAnnotations];
}

- (BOOL) findLinesAtStation:(JDOStationModel *)station{
    NSMutableArray *lines = [[NSMutableArray alloc] init];
    
    FMResultSet *rs = [_db executeQuery:GetLinesByStation,station.fid];
    while ([rs next]) {
        if (![rs stringForColumn:@"LINENAME"] || ![rs stringForColumn:@"LINEDETAIL"]) {
            NSLog(@"线路详情id：%@不存在",[rs stringForColumn:@"LINEID"]);
            continue;
        }
        
        JDOBusLine *busLine = [JDOBusLine new];
        busLine.lineId = [rs stringForColumn:@"LINEID"];
        busLine.lineName = [rs stringForColumn:@"LINENAME"];
        JDOBusLineDetail *lineDetail = [JDOBusLineDetail new];
        lineDetail.detailId = [rs stringForColumn:@"LINEDETAILID"];
        lineDetail.lineDetail = [rs stringForColumn:@"LINEDETAIL"];
        busLine.lineDetailPair = [@[lineDetail] mutableCopy];
        [lines addObject:busLine];
    }
    if (lines.count >0) {
        [_stationLines setObject:lines forKey:station.fid];
        return true;
    }
    return false;
}

-(void)viewWillAppear:(BOOL)animated {
    [_mapView viewWillAppear];
}

-(void)viewWillDisappear:(BOOL)animated {
    [_mapView viewWillDisappear];
}

-(void)viewDidAppear:(BOOL)animated {
    // 在viewDidLoad里设置annotation的话，因为mapView的delegate还没有设置，导致无法执行回调
    
}

-(void)addAnnotations{
    JDOStationModel *myPosition = [JDOStationModel new];
    myPosition.name = @"我的位置";
    myPosition.gpsX = [NSNumber numberWithDouble:self.centerCoor.longitude];
    myPosition.gpsY = [NSNumber numberWithDouble:self.centerCoor.latitude];
    [self addPointAnnotation:myPosition];
    
    for (int i=0; i<_stations.count; i++) {
        [self addPointAnnotation:_stations[i]];
    }
}

- (void)addPointAnnotation:(JDOStationModel *) station{
    JDOStationAnnotation *pointAnnotation = [[JDOStationAnnotation alloc] init];
    // GPS坐标转百度坐标
//    CLLocationCoordinate2D bdStation = BMKCoorDictionaryDecode(BMKConvertBaiduCoorFrom(CLLocationCoordinate2DMake(station.gpsY.doubleValue, station.gpsX.doubleValue),BMK_COORDTYPE_GPS));
//    pointAnnotation.coordinate = bdStation;
    pointAnnotation.coordinate = CLLocationCoordinate2DMake(station.gpsY.doubleValue, station.gpsX.doubleValue);
    pointAnnotation.title = station.name;
    pointAnnotation.station = station;
    [_mapView addAnnotation:pointAnnotation];
}

- (BMKAnnotationView *)mapView:(BMKMapView *)mapView viewForAnnotation:(id <BMKAnnotation>)annotation{
    static NSString *AnnotationViewID = @"annotationView";
    BMKPinAnnotationView *newAnnotation = [[BMKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:AnnotationViewID];
    if ([annotation.title isEqualToString:@"我的位置"]) {
        newAnnotation.pinColor = BMKPinAnnotationColorGreen;
        newAnnotation.animatesDrop = false;
    }else{
        newAnnotation.pinColor = BMKPinAnnotationColorPurple;
        newAnnotation.animatesDrop = true;
        newAnnotation.paopaoView = [self createPaoPaoView:[(JDOStationAnnotation *)annotation station]];
    }
    
    newAnnotation.draggable = false;
    return newAnnotation;
}

- (BMKActionPaopaoView *)createPaoPaoView:(JDOStationModel *)station{
    NSArray *paopaoLines = [_stationLines objectForKey:station.fid];
    // 弹出窗口中的线路数目如果小于200，则有多高就显示多高，否则最多显示200高度，内部表格滚动
    float tableHeight = paopaoLines.count*44<200?paopaoLines.count*44:200;
    UIView *customView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, tableHeight+44)];
    customView.backgroundColor = [UIColor lightGrayColor];
    
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 44)];
    title.font = [UIFont systemFontOfSize:15];
    title.text = [NSString stringWithFormat:@"%@  %@|%d米",station.name,station.direction,[station.distance intValue]];
    [customView addSubview:title];
    
    JDOPaoPaoTable *paopaoTable = [[JDOPaoPaoTable alloc] initWithFrame:CGRectMake(0, 44, 200, tableHeight)];
    paopaoTable.stationId = station.fid;
    paopaoTable.delegate = self;
    paopaoTable.dataSource = self;
    [customView addSubview:paopaoTable];
    
    BMKActionPaopaoView *paopaoView = [[BMKActionPaopaoView alloc] initWithCustomView:customView];
    return paopaoView;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [self performSegueWithIdentifier:@"toRealtimeFromMap" sender:@[tableView,indexPath]];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"toRealtimeFromMap"]) {
        JDORealTimeController *rt = segue.destinationViewController;
        JDOPaoPaoTable *paopaoTable = [(NSArray *)sender objectAtIndex:0];
        NSIndexPath *indexPath = [(NSArray *)sender objectAtIndex:1];
        NSArray *paopaoLines = [_stationLines objectForKey:paopaoTable.stationId];
        rt.busLine = paopaoLines[indexPath.row];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    JDOPaoPaoTable *paopaoTable = (JDOPaoPaoTable *)tableView;
    NSArray *paopaoLines = [_stationLines objectForKey:paopaoTable.stationId];
    return paopaoLines.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *lineIdentifier = @"lineIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:lineIdentifier];
    if( cell == nil){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:lineIdentifier];
        UILabel *lineLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 44)];
        lineLabel.font = [UIFont systemFontOfSize:14];
        lineLabel.tag = 3001;
        [cell addSubview:lineLabel];
    }
    UILabel *lineLabel = (UILabel *)[cell viewWithTag:3001];
    
    JDOPaoPaoTable *paopaoTable = (JDOPaoPaoTable *)tableView;
    NSArray *paopaoLines = [_stationLines objectForKey:paopaoTable.stationId];
    JDOBusLine *busLine = paopaoLines[indexPath.row];
    JDOBusLineDetail *lineDetail = busLine.lineDetailPair[0];
    NSArray *lineNamePair = [lineDetail.lineDetail componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"－-"]];

    NSString *lineContent;
    if (lineNamePair.count!=2) {
        NSLog(@"双向站点不全：%@",lineNamePair);
        lineContent = busLine.lineName;
    }else{
        lineContent = [NSString stringWithFormat:@"%@(开往 %@ 方向)",busLine.lineName,lineNamePair[1]];
    }
    lineLabel.text = lineContent;
    
    // 某条线路的该站点离当前位置最近，则用特殊颜色标示
    for(int i=0; i<_linesInfo.count; i++ ){
        JDOBusLine *aLine = _linesInfo[i];
        if ([busLine.lineId isEqualToString:aLine.lineId]) {
            NSArray *stationPair = aLine.nearbyStationPair;
            for (int j=0; j<stationPair.count; j++) {
                JDOStationModel *aStation = stationPair[j];
                if ([paopaoTable.stationId isEqualToString:aStation.fid]) {
                    lineLabel.textColor = [UIColor blueColor];
                    break;
                }
            }
            break;
        }
    }
    return cell;
}

// 当点击annotation view弹出的泡泡时，调用此接口
//- (void)mapView:(BMKMapView *)mapView annotationViewForBubble:(BMKAnnotationView *)view {
//    NSLog(@"paopaoclick");
//}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)dealloc{
    if (dbObserver) {
        [[NSNotificationCenter defaultCenter] removeObserver:dbObserver];
    }
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
