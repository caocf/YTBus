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
#import "JDOConstants.h"

#import "TBCoordinateQuadTree.h"
#import "TBClusterAnnotationView.h"
#import "TBClusterAnnotation.h"

@interface JDOPaoPaoTable2 : UITableView

@property (nonatomic,strong) NSArray *stations;

@end

@implementation JDOPaoPaoTable2

@end

@interface JDOStationMapController () <BMKMapViewDelegate,UITableViewDataSource,UITableViewDelegate>

@property (nonatomic,assign) IBOutlet BMKMapView *mapView;
@property (nonatomic,assign) IBOutlet UITableView *tableView;
@property (nonatomic,assign) IBOutlet UIView *lineView;
@property (nonatomic,assign) IBOutlet UILabel *stationLabel;
@property (nonatomic,assign) IBOutlet UISwitch *busMonitor;
@property (nonatomic,assign) IBOutlet UIButton *closeBtn;
@property (nonatomic,strong) TBCoordinateQuadTree *coordinateQuadTree;

@end

@implementation JDOStationMapController{
    FMDatabase *_db;
    NSMutableArray *_stations;
    JDOStationModel *selectedStation;
    NSIndexPath *selectedIndexPath;
    NSOperationQueue *_queryQueue;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    _mapView.zoomEnabled = true;
    _mapView.zoomEnabledWithTap = true;
    _mapView.scrollEnabled = true;
    _mapView.rotateEnabled = true;
    _mapView.overlookEnabled = false;
    _mapView.showMapScaleBar = false;
    _mapView.minZoomLevel = 12; // 覆盖当前全部站点的范围
    _mapView.zoomLevel = 13;
    // TODO 进入时候根据传入的定位位置进行设置(定位位置保存为全局变量)，并相应增大初始化时候的缩放级别
    _mapView.centerCoordinate = CLLocationCoordinate2DMake( 37.4698,121.454);   // 市政府的位置
    
    self.coordinateQuadTree = [[TBCoordinateQuadTree alloc] init];
    _queryQueue = [NSOperationQueue new];
    _queryQueue.maxConcurrentOperationCount = 1;
    
    _stations = [NSMutableArray new];
    _db = [JDODatabase sharedDB];
    if (_db) {
        [_queryQueue addOperationWithBlock:^{
            [self loadData2];
        }];
    }
    
    self.tableView.sectionHeaderHeight = 15;
    self.tableView.sectionFooterHeight = 15;
    self.tableView.backgroundColor = [UIColor colorWithHex:@"dfded9"];
    
    self.lineView.frame = CGRectMake(20, CGRectGetHeight(self.view.bounds)-44, 280, 44);
    self.stationLabel.text = @"请选择站点";
    self.busMonitor.hidden = true;
    self.closeBtn.hidden = true;
    [self.closeBtn addTarget:self action:@selector(closeLineView) forControlEvents:UIControlEventTouchUpInside];
    [self.busMonitor addTarget:self action:@selector(switchMonitor) forControlEvents:UIControlEventValueChanged];
}

- (void)loadData2{
    FMResultSet *rs = [_db executeQuery:GetAllStationsInfo];
    while ([rs next]) {
        JDOStationModel *station = [JDOStationModel new];
        station.fid = [rs stringForColumn:@"STATIONID"];
        station.name = [NSString stringWithFormat:@"%@[%@]",[rs stringForColumn:@"STATIONNAME"],[rs stringForColumn:@"DIRECTION"]];
        station.gpsX = [NSNumber numberWithDouble:[rs doubleForColumn:@"GPSX"]];
        station.gpsY = [NSNumber numberWithDouble:[rs doubleForColumn:@"GPSY"]];
        [_stations addObject:station];
    }
    [self.coordinateQuadTree buildTree:_stations];
    [_stations removeAllObjects];
    // 初始时候的mapView.visibleRect位置在北京，无法获取visibleRect变化完成的事件，即使在viewDidAppear直接调用也不行。
    // Fixed on BMK 2.6.0，mapViewDidFinishLoading事件中直接调用
//    [self performSelector:@selector(mapView:regionDidChangeAnimated:) withObject:_mapView afterDelay:0.1];
}

- (void)mapViewDidFinishLoading:(BMKMapView *)mapView{
    [self mapView:mapView regionDidChangeAnimated:false];
}

-(void)viewWillAppear:(BOOL)animated {
    [MobClick beginLogPageView:@"sitesmap"];
    [MobClick event:@"sitesmap"];
    [MobClick beginEvent:@"sitesmap"];
    
    _mapView.delegate = self;
    [_mapView viewWillAppear];
}

-(void)viewWillDisappear:(BOOL)animated {
    [MobClick endLogPageView:@"sitesmap"];
    [MobClick endEvent:@"sitesmap"];
    
    [_mapView viewWillDisappear];
    _mapView.delegate = nil;
}


- (void)mapView:(BMKMapView *)mapView didAddAnnotationViews:(NSArray *)views
{
    for (UIView *view in views) {
        [self addBounceAnnimationToView:view];
    }
}

- (void)addBounceAnnimationToView:(UIView *)view
{
    CAKeyframeAnimation *bounceAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
    
    bounceAnimation.values = @[@(0.05), @(1.1), @(0.9), @(1)];
    
    bounceAnimation.duration = 0.6;
    NSMutableArray *timingFunctions = [[NSMutableArray alloc] initWithCapacity:bounceAnimation.values.count];
    for (NSUInteger i = 0; i < bounceAnimation.values.count; i++) {
        [timingFunctions addObject:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    }
    [bounceAnimation setTimingFunctions:timingFunctions.copy];
    bounceAnimation.removedOnCompletion = NO;
    
    [view.layer addAnimation:bounceAnimation forKey:@"bounce"];
}

- (void)updateMapViewAnnotationsWithAnnotations:(NSArray *)annotations
{
    NSMutableSet *before = [NSMutableSet setWithArray:self.mapView.annotations];
//    [before removeObject:[self.mapView userLocation]];
    NSSet *after = [NSSet setWithArray:annotations];
    
    NSMutableSet *toKeep = [NSMutableSet setWithSet:before];
    [toKeep intersectSet:after];
    
    NSMutableSet *toAdd = [NSMutableSet setWithSet:after];
    [toAdd minusSet:toKeep];
    
    NSMutableSet *toRemove = [NSMutableSet setWithSet:before];
    [toRemove minusSet:after];
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.mapView addAnnotations:[toAdd allObjects]];
        [self.mapView removeAnnotations:[toRemove allObjects]];
    }];
}

- (void)mapView:(BMKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    [_queryQueue addOperationWithBlock:^{
        double scale = mapView.bounds.size.width / mapView.visibleMapRect.size.width;
//        NSArray *annotations = [self.coordinateQuadTree clusteredAnnotationsWithinMapRect:mapView.visibleMapRect withZoomScale:scale];
        NSArray *annotations = [self.coordinateQuadTree clusteredAnnotationsWithinMapView:mapView];
        [self updateMapViewAnnotationsWithAnnotations:annotations];
    }];
}

- (void)mapView:(BMKMapView *)mapView didSelectAnnotationView:(BMKAnnotationView *)view{
    TBClusterAnnotation *ca = (TBClusterAnnotation *)view.annotation;
    // 若marker上只有一个站点，则不弹出paopaoView，直接打开线路列表
    if(ca.stations.count ==1){
        selectedStation = ca.stations[0];
        [self showLineView];
    }
}

- (BMKAnnotationView *)mapView:(BMKMapView *)mapView viewForAnnotation:(id<BMKAnnotation>)annotation
{
    static NSString *const TBAnnotatioViewReuseID = @"TBAnnotatioViewReuseID";
    
    TBClusterAnnotationView *annotationView = (TBClusterAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:TBAnnotatioViewReuseID];
    
    if (!annotationView) {
        annotationView = [[TBClusterAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:TBAnnotatioViewReuseID];
    }else{
        annotationView.annotation = annotation;
    }
    
    TBClusterAnnotation *ca = (TBClusterAnnotation *)annotation;
    annotationView.count = ca.count;
    annotationView.canShowCallout = true;
    if (ca.stations.count == 0) {
        ca.title = [NSString stringWithFormat:@"附近有%d个站点",ca.count];
    }else if(ca.stations.count ==1) {
        annotationView.paopaoView = [[BMKActionPaopaoView alloc] initWithCustomView:[[UIView alloc] initWithFrame:CGRectZero]];
    }else{
        annotationView.paopaoView = [self createPaoPaoView:ca.stations];
    }
    
    return annotationView;
}

- (BMKActionPaopaoView *)createPaoPaoView:(NSArray *)paopaoLines{
    // 弹出窗口中的线路数目如果小于180，则有多高就显示多高，否则最多显示180高度，内部表格滚动
    float tableHeight = paopaoLines.count*40<100?paopaoLines.count*40:100;
    UIView *customView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 140, 35+tableHeight+12)];
    
    UIImageView *header = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 140, 35)];
    header.image = [UIImage imageNamed:@"弹出列表01"];
    [customView addSubview:header];
    
    UILabel *title = [[UILabel alloc] initWithFrame:header.bounds];
    title.backgroundColor = [UIColor clearColor];   // iOS7以下label背景色为白色，以上为透明
    title.font = [UIFont boldSystemFontOfSize:15];
    title.minimumFontSize = 12;
    title.adjustsFontSizeToFitWidth = true;
    title.textColor = [UIColor whiteColor];
    title.textAlignment = NSTextAlignmentCenter;
    title.text = @"站点列表";
    [header addSubview:title];
    
    UIImageView *footer = [[UIImageView alloc] initWithFrame:CGRectMake(0, 35+tableHeight+12-51, 140, 51)];
    footer.image = [UIImage imageNamed:@"弹出列表04"];
    [customView addSubview:footer];
    
    JDOPaoPaoTable2 *paopaoTable = [[JDOPaoPaoTable2 alloc] initWithFrame:CGRectMake(0, 35, 140, tableHeight)];
    paopaoTable.stations = paopaoLines;
    paopaoTable.rowHeight = 40;
    paopaoTable.separatorStyle = UITableViewCellSeparatorStyleNone;
    paopaoTable.delegate = self;
    paopaoTable.dataSource = self;
    [customView addSubview:paopaoTable];
    
    BMKActionPaopaoView *paopaoView = [[BMKActionPaopaoView alloc] initWithCustomView:customView];
    return paopaoView;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([tableView isKindOfClass:[JDOPaoPaoTable2 class]]) {
        JDOPaoPaoTable2 *paopaoTable = (JDOPaoPaoTable2 *)tableView;
        return paopaoTable.stations.count;
    }else{
        return selectedStation.passLines.count;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([tableView isKindOfClass:[JDOPaoPaoTable2 class]]) {
        static NSString *lineIdentifier = @"lineIdentifier";
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:lineIdentifier];
        if( cell == nil){
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:lineIdentifier];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            UILabel *lineLabel = [[UILabel alloc] initWithFrame:CGRectMake(5, 0, 140-10, 40)];
            lineLabel.backgroundColor = [UIColor clearColor];
            lineLabel.font = [UIFont systemFontOfSize:14];
            lineLabel.minimumFontSize = 12;
            lineLabel.numberOfLines = 2;
            lineLabel.adjustsFontSizeToFitWidth = true;
            lineLabel.textColor = [UIColor colorWithRed:110/255.0f green:110/255.0f blue:110/255.0f alpha:1];
            lineLabel.tag = 3001;
            [cell addSubview:lineLabel];
        }
        if (indexPath.row%2 == 0) {
            cell.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"弹出列表02"]];
        }else{
            cell.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"弹出列表03"]];
        }
        
        UILabel *lineLabel = (UILabel *)[cell viewWithTag:3001];
        
        JDOPaoPaoTable2 *paopaoTable = (JDOPaoPaoTable2 *)tableView;
        NSArray *paopaoLines = paopaoTable.stations;
        JDOStationModel *station = paopaoLines[indexPath.row];
        lineLabel.text = station.name;
        
        return cell;
    }else{
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"stationLine" forIndexPath:indexPath];
        cell.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"表格圆角中"]];
        
        JDOBusLine *busLine = selectedStation.passLines[indexPath.row];
        JDOBusLineDetail *lineDetail = busLine.lineDetailPair[0];
        [(UILabel *)[cell viewWithTag:1001] setText:busLine.lineName];
        [(UILabel *)[cell viewWithTag:1002] setText:lineDetail.lineDetail];
        [[cell viewWithTag:1003] setHidden:!self.busMonitor.on];
        [[cell viewWithTag:1004] setHidden:(indexPath.row == selectedStation.passLines.count-1)];  //最后一行不显示分割线
        
        return cell;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    if ([tableView isKindOfClass:[JDOPaoPaoTable2 class]]) {
        return nil;
    }else{
        UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 320, 15)];
        iv.image = [UIImage imageNamed:@"表格圆角上"];
        return iv;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    if ([tableView isKindOfClass:[JDOPaoPaoTable2 class]]) {
        return nil;
    }else{
        UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 320, 15)];
        iv.image = [UIImage imageNamed:@"表格圆角下"];
        return iv;
    }
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if ([tableView isKindOfClass:[JDOPaoPaoTable2 class]]) {
        JDOPaoPaoTable2 *paopaoTable = (JDOPaoPaoTable2 *)tableView;
        selectedStation = [paopaoTable.stations objectAtIndex:indexPath.row];
        [self showLineView];
    }
}

- (void) showLineView{
    selectedStation.passLines = [NSMutableArray new];
    // 根据站点id查询通过的线路，并实时刷新最近的车辆
    int count = 0;
    FMResultSet *rs = [_db executeQuery:GetLinesByStation,selectedStation.fid];
    while ([rs next]) {
        JDOBusLine *busLine = [JDOBusLine new];
        [selectedStation.passLines addObject:busLine];
        busLine.lineId = [rs stringForColumn:@"LINEID"];
        busLine.lineName = [rs stringForColumn:@"LINENAME"];
        busLine.lineDetailPair = [NSMutableArray new];
        
        JDOBusLineDetail *lineDetail = [JDOBusLineDetail new];
        [busLine.lineDetailPair addObject:lineDetail];
        lineDetail.detailId = [rs stringForColumn:@"LINEDETAILID"];
        lineDetail.lineDetail = [rs stringForColumn:@"LINEDETAIL"];
        lineDetail.direction = [rs stringForColumn:@"LINEDIRECTION"];
        
        count++;
    }
    [self.tableView reloadData];
    
    self.stationLabel.text = selectedStation.name;
    self.busMonitor.on = false;
    self.busMonitor.hidden = false;
    self.closeBtn.hidden = false;
    
    [UIView animateWithDuration:0.25f animations:^{
        float height = MIN(44+60*count+30, 250);
        self.lineView.frame = CGRectMake(20, CGRectGetHeight(self.view.bounds)-height, 280, height);
    } completion:^(BOOL finished) {
        
    }];
    
}

- (void)closeLineView{
    [UIView animateWithDuration:0.25f animations:^{
        self.lineView.frame = CGRectMake(20, CGRectGetHeight(self.view.bounds)-44, 280, 44);
    } completion:^(BOOL finished) {
        self.stationLabel.text = @"请选择站点";
        self.busMonitor.hidden = true;
        self.closeBtn.hidden = true;
    }];
}

- (void)switchMonitor{
    for (UITableViewCell *cell in [self.tableView visibleCells]){
        [[cell viewWithTag:1003] setHidden:!self.busMonitor.on];
    }
    // 停止计时器
}



// ========================================================================

//- (void)loadData{
//    _stations = [NSMutableArray new];
//    FMResultSet *rs = [_db executeQuery:GetStationsWithLinesByName,self.stationName];
//    JDOStationModel *preStation;
//    while ([rs next]) {
//        JDOStationModel *station;
//        // 相同id的站点的线路填充到station中
//        NSString *stationId = [rs stringForColumn:@"STATIONID"];
//        if (preStation && [stationId isEqualToString:preStation.fid]) {
//            station = preStation;
//        }else{
//            station = [JDOStationModel new];
//            station.fid = [rs stringForColumn:@"STATIONID"];
//            station.name = [rs stringForColumn:@"STATIONNAME"];
//            station.gpsX = [NSNumber numberWithDouble:[rs doubleForColumn:@"GPSX"]];
//            station.gpsY = [NSNumber numberWithDouble:[rs doubleForColumn:@"GPSY"]];
//            station.passLines = [NSMutableArray new];
//            
//            [_stations addObject:station];
//            preStation = station;
//        }
//        JDOBusLine *busLine = [JDOBusLine new];
//        [station.passLines addObject:busLine];
//        busLine.lineId = [rs stringForColumn:@"BUSLINEID"];
//        busLine.lineName = [rs stringForColumn:@"BUSLINENAME"];
//        busLine.lineDetailPair = [NSMutableArray new];
//        
//        JDOBusLineDetail *lineDetail = [JDOBusLineDetail new];
//        [busLine.lineDetailPair addObject:lineDetail];
//        lineDetail.detailId = [rs stringForColumn:@"LINEDETAILID"];
//        lineDetail.lineDetail = [rs stringForColumn:@"BUSLINEDETAIL"];
//        lineDetail.direction = [rs stringForColumn:@"DIRECTION"];
//    }
//    selectedStation = _stations[0];
//    _stationLabel.text = selectedStation.name;
//    [_tableView reloadData];
//    
//    if(_stations.count > 2){
//        _mapView.zoomLevel = 16;
//    }else{
//        _mapView.zoomLevel = 18;
//    }
//    [self setMapCenter];
//    [self addStationAnnotation];
//}
//
//- (void) setMapCenter{
//    // 将地图的中心定位到所有站点的中心。所有站点的经纬度大致范围应该是北纬37-38，东经121-122
//    double minX = 180, minY = 180, maxX = 0, maxY = 0;
//    for (int i=0; i<_stations.count; i++) {
//        JDOStationModel *station = _stations[i];
//        if (station.gpsX.doubleValue < minX) {
//            minX = station.gpsX.doubleValue;
//        }
//        if(station.gpsX.doubleValue > maxX ){
//            maxX = station.gpsX.doubleValue;
//        }
//        if (station.gpsY.doubleValue < minY) {
//            minY = station.gpsY.doubleValue;
//        }
//        if(station.gpsY.doubleValue > maxY ){
//            maxY = station.gpsY.doubleValue;
//        }
//    }
//    _mapView.centerCoordinate = CLLocationCoordinate2DMake( (maxY+minY)/2, (maxX+minX)/2);
//}
//
//-(void)addStationAnnotation{
//    for (int i=0; i<_stations.count; i++) {
//        JDOStationModel *station = _stations[i];
//        JDOStationAnnotation *annotation = [[JDOStationAnnotation alloc] init];
//        annotation.coordinate = CLLocationCoordinate2DMake(station.gpsY.doubleValue, station.gpsX.doubleValue);
//        annotation.station = station;
//        annotation.selected = (i==0);
//        annotation.index = i+1;
//        annotation.title = @""; //didSelectAnnotationView回调触发必须设置title，设置title后若不想弹出paopao，只能设置空customView
//        [_mapView addAnnotation:annotation];
//    }
//}
//
//- (BMKAnnotationView *)mapView:(BMKMapView *)mapView viewForAnnotation:(id <BMKAnnotation>)annotation{
//    static NSString *AnnotationViewID = @"annotationView";
//    BMKAnnotationView *annotationView = [mapView dequeueReusableAnnotationViewWithIdentifier:AnnotationViewID];
//    if (!annotationView) {
//        annotationView = [[BMKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:AnnotationViewID];
//        annotationView.centerOffset = CGPointMake(0, -16);
//        annotationView.paopaoView = [[BMKActionPaopaoView alloc] initWithCustomView:[[UIView alloc] initWithFrame:CGRectZero]];
//    }else{
//        annotationView.annotation = annotation;
//    }
//    JDOStationAnnotation *sa = (JDOStationAnnotation *)annotation;
//    if (sa.selected) {
//        annotationView.image = [UIImage imageNamed:[NSString stringWithFormat:@"地图标注蓝%d",sa.index]];
//    }else{
//        annotationView.image = [UIImage imageNamed:[NSString stringWithFormat:@"地图标注红%d",sa.index]];
//    }
//    return annotationView;
//}
//
//- (void)mapView:(BMKMapView *)mapView didSelectAnnotationView:(BMKAnnotationView *)view{
//    JDOStationAnnotation *sa = view.annotation;
//    sa.selected = true;
//    view.image = [UIImage imageNamed:[NSString stringWithFormat:@"地图标注蓝%d",sa.index]];
//    for(JDOStationAnnotation *other in _mapView.annotations){
//        if(other != sa){
//            other.selected = false;
//            [_mapView viewForAnnotation:other].image = [UIImage imageNamed:[NSString stringWithFormat:@"地图标注红%d",other.index]];
//        }
//    }
//    selectedStation = sa.station;
//    _stationLabel.text = selectedStation.name;
//    [_tableView reloadData];
//}
//
//
//
//
//
//- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath{
//    selectedIndexPath = indexPath;
//    return indexPath;
//}

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
