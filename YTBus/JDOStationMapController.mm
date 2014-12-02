//
//  JDOStationMapController.m
//  YTBus
//
//  Created by zhang yi on 14-11-18.
//  Copyright (c) 2014年 胶东在线. All rights reserved.
//

#import "JDOStationMapController.h"
#import "BMapKit.h"
#import "JDODatabase.h"
#import "JDOStationModel.h"
#import "JDOBusLine.h"
#import "JDOBusLineDetail.h"
#import "JDOStationAnnotation.h"
#import "JDORealTimeController.h"

@interface JDOStationMapController () <BMKMapViewDelegate,UITableViewDataSource,UITableViewDelegate>

@property (nonatomic,assign) IBOutlet BMKMapView *mapView;
@property (nonatomic,assign) IBOutlet UITableView *tableView;
@property (nonatomic,assign) IBOutlet UILabel *stationLabel;

@end

@implementation JDOStationMapController{
    FMDatabase *_db;
    NSMutableArray *_stations;
    JDOStationModel *selectedStation;
    NSIndexPath *selectedIndexPath;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    _mapView.zoomEnabled = true;
    _mapView.zoomEnabledWithTap = true;
    _mapView.scrollEnabled = true;
    _mapView.rotateEnabled = false;
    _mapView.overlookEnabled = false;
    _mapView.showMapScaleBar = false;
    _mapView.delegate = self;
    _mapView.minZoomLevel = 15;
    
    _db = [JDODatabase sharedDB];
    if (_db) {
        [self loadData];
    }
}

- (void)loadData{
    _stations = [NSMutableArray new];
    FMResultSet *rs = [_db executeQuery:GetStationsWithLinesByName,self.stationName];
    JDOStationModel *preStation;
    while ([rs next]) {
        JDOStationModel *station;
        // 相同id的站点的线路填充到station中
        NSString *stationId = [rs stringForColumn:@"STATIONID"];
        if (preStation && [stationId isEqualToString:preStation.fid]) {
            station = preStation;
        }else{
            station = [JDOStationModel new];
            station.fid = [rs stringForColumn:@"STATIONID"];
            station.name = [rs stringForColumn:@"STATIONNAME"];
            station.gpsX = [NSNumber numberWithDouble:[rs doubleForColumn:@"GPSX"]];
            station.gpsY = [NSNumber numberWithDouble:[rs doubleForColumn:@"GPSY"]];
            station.passLines = [NSMutableArray new];
            
            [_stations addObject:station];
            preStation = station;
        }
        JDOBusLine *busLine = [JDOBusLine new];
        [station.passLines addObject:busLine];
        busLine.lineId = [rs stringForColumn:@"BUSLINEID"];
        busLine.lineName = [rs stringForColumn:@"BUSLINENAME"];
        busLine.lineDetailPair = [NSMutableArray new];
        
        JDOBusLineDetail *lineDetail = [JDOBusLineDetail new];
        [busLine.lineDetailPair addObject:lineDetail];
        lineDetail.detailId = [rs stringForColumn:@"LINEDETAILID"];
        lineDetail.lineDetail = [rs stringForColumn:@"BUSLINEDETAIL"];
        lineDetail.direction = [rs stringForColumn:@"DIRECTION"];
    }
    selectedStation = _stations[0];
    _stationLabel.text = selectedStation.name;
    [_tableView reloadData];
    
    if(_stations.count > 2){
        _mapView.zoomLevel = 16;
    }else{
        _mapView.zoomLevel = 19;
    }
    [self setMapCenter];
    [self addStationAnnotation];
}

- (void) setMapCenter{
    // 将地图的中心定位到所有站点的中心。所有站点的经纬度大致范围应该是北纬37-38，东经121-122
    double minX = 180, minY = 180, maxX = 0, maxY = 0;
    for (int i=0; i<_stations.count; i++) {
        JDOStationModel *station = _stations[i];
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

-(void)addStationAnnotation{
    for (int i=0; i<_stations.count; i++) {
        JDOStationModel *station = _stations[i];
        JDOStationAnnotation *annotation = [[JDOStationAnnotation alloc] init];
        annotation.coordinate = CLLocationCoordinate2DMake(station.gpsY.doubleValue, station.gpsX.doubleValue);
        annotation.station = station;
        annotation.selected = (i==0);
        annotation.title = @""; //didSelectAnnotationView回调触发必须设置title，设置title后若不想弹出paopao，只能设置空customView
        [_mapView addAnnotation:annotation];
    }
}

- (BMKAnnotationView *)mapView:(BMKMapView *)mapView viewForAnnotation:(id <BMKAnnotation>)annotation{
    static NSString *AnnotationViewID = @"annotationView";
    BMKAnnotationView *annotationView = [[BMKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:AnnotationViewID];
    annotationView.centerOffset = CGPointMake(0, -16);
    annotationView.paopaoView = [[BMKActionPaopaoView alloc] initWithCustomView:[[UIView alloc] initWithFrame:CGRectZero]];
    if (((JDOStationAnnotation *)annotation).selected) {
        annotationView.image = [UIImage imageNamed:@"地图标注1"];
    }else{
        annotationView.image = [UIImage imageNamed:@"地图标注2"];
    }
    return annotationView;
}

- (void)mapView:(BMKMapView *)mapView didSelectAnnotationView:(BMKAnnotationView *)view{
    JDOStationAnnotation *sa = view.annotation;
    sa.selected = true;
    view.image = [UIImage imageNamed:@"地图标注1"];
    for(JDOStationAnnotation *other in _mapView.annotations){
        if(other != sa){
            other.selected = false;
            [_mapView viewForAnnotation:other].image = [UIImage imageNamed:@"地图标注2"];
        }
    }
    selectedStation = sa.station;
    _stationLabel.text = selectedStation.name;
    [_tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return selectedStation.passLines.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"stationLine" forIndexPath:indexPath];
//    cell.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"线路单元格背景"]];
    
    JDOBusLine *busLine = selectedStation.passLines[indexPath.row];
    JDOBusLineDetail *lineDetail = busLine.lineDetailPair[0];
    [(UILabel *)[cell viewWithTag:1001] setText:busLine.lineName];
    [(UILabel *)[cell viewWithTag:1002] setText:lineDetail.lineDetail];
    
    return cell;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    selectedIndexPath = indexPath;
    return indexPath;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"toRealtimeFromStation"]) {
        JDORealTimeController *rt = segue.destinationViewController;
        JDOBusLine *busLine = selectedStation.passLines[selectedIndexPath.row];
        busLine.nearbyStationPair = [NSMutableArray arrayWithObject:selectedStation];
        rt.busLine = busLine;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
