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
#import "AppDelegate.h"
#import <objc/runtime.h>

#import "TBCoordinateQuadTree.h"
#import "TBClusterAnnotationView.h"
#import "TBClusterAnnotation.h"

#define PaoPaoLineHeight 35

static const void *LabelKey = &LabelKey;

@interface BMKGeoCodeSearch (JDOCategory)

@property (nonatomic,retain) UILabel *titleLabel;

@end

@implementation BMKGeoCodeSearch (JDOCategory)

@dynamic titleLabel;

- (UILabel *)titleLabel {
    return objc_getAssociatedObject(self, LabelKey);
}

- (void)setTitleLabel:(UILabel *)titleLabel{
    objc_setAssociatedObject(self, LabelKey, titleLabel, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@interface JDOPaoPaoTable2 : UITableView

@property (nonatomic,strong) NSArray *stations;

@end

@implementation JDOPaoPaoTable2

@end

@interface JDOStationMapController () <BMKMapViewDelegate,UITableViewDataSource,UITableViewDelegate,BMKGeoCodeSearchDelegate>

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
    NSIndexPath *selectedIndexPath;
    NSOperationQueue *_queryQueue;
    BOOL rightBtnIsSearch;
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
    // 进入时候根据传入的定位位置进行设置(定位位置保存为全局变量)，并相应增大初始化时候的缩放级别
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    // 有站点信息，则是通过站点详情进入的
    if (self.selectedStation && _selectedStation.gpsY.doubleValue>0 && _selectedStation.gpsX.doubleValue>0) {
        _mapView.centerCoordinate = CLLocationCoordinate2DMake(_selectedStation.gpsY.doubleValue, _selectedStation.gpsX.doubleValue);
        _mapView.zoomLevel = 19;
    }else if (delegate.userLocation) {
        CLLocationCoordinate2D coor = delegate.userLocation.location.coordinate;
        if (coor.latitude>YT_MIN_Y && coor.latitude<YT_MAX_Y && coor.longitude>YT_MIN_X && coor.longitude<YT_MAX_X) {
            _mapView.centerCoordinate = delegate.userLocation.location.coordinate;
            _mapView.zoomLevel = 15;
        }else{  // 若定位范围出现偏差，超出烟台市区范围，则指向市政府位置
            _mapView.centerCoordinate = CLLocationCoordinate2DMake(37.4698,121.454);
            _mapView.zoomLevel = 13;
        }
    }else{  // 未能定位，也指向市政府的位置
        _mapView.centerCoordinate = CLLocationCoordinate2DMake(37.4698,121.454);
        _mapView.zoomLevel = 13;
    }
    
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
    
//    self.tableView.sectionHeaderHeight = 15;
//    self.tableView.sectionFooterHeight = 15;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.bounces = true;
    
    self.lineView.frame = CGRectMake(10, CGRectGetHeight(self.view.bounds)-44, 300, 44);
    self.stationLabel.text = @"请选择站点";
    self.busMonitor.hidden = true;
    self.closeBtn.hidden = true;
    [self.closeBtn addTarget:self action:@selector(closeLineView) forControlEvents:UIControlEventTouchUpInside];
    [self.busMonitor addTarget:self action:@selector(switchMonitor) forControlEvents:UIControlEventValueChanged];
    
//    self.navigationItem.rightBarButtonItem.target = self;
//    self.navigationItem.rightBarButtonItem.action = @selector(searchOrClear:);
    rightBtnIsSearch = true;
    
}

- (void) searchOrClear:(id)sender {
    if (rightBtnIsSearch) {
        self.navigationItem.rightBarButtonItem.image = [UIImage imageNamed:@"地图-清除"];
    }else{
        self.navigationItem.rightBarButtonItem.image = [UIImage imageNamed:@"地图-搜索"];
    }
    rightBtnIsSearch = !rightBtnIsSearch;
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
    [rs close];
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
    
    if (self.selectedStation) {
        [self showLineView];
    }
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
    
    if (ca.stations.count == 0) {

    }else if(ca.stations.count ==1) {
        [mapView setCenterCoordinate:view.annotation.coordinate animated:YES];
        // 若marker上只有一个站点，则不弹出paopaoView，直接打开线路列表
        _selectedStation = ca.stations[0];
        [self showLineView];
    }else{
        // 选中某个marker后，将此marker移动到地图中心
        [mapView setCenterCoordinate:view.annotation.coordinate animated:YES];
        
        TBClusterAnnotationView *annotationView = (TBClusterAnnotationView *)view;
        UIView *customView = [annotationView.paopaoView subviews][0];
        UILabel *title = (UILabel *)[customView viewWithTag:8001];
        
        // 多个站点的时候，取位置进行反地理编码填充表格头部
        BMKReverseGeoCodeOption *reverseGeoCodeSearchOption = [[BMKReverseGeoCodeOption alloc] init];
        reverseGeoCodeSearchOption.reverseGeoPoint = ca.coordinate;
        BMKGeoCodeSearch *searcher =[[BMKGeoCodeSearch alloc] init];
        searcher.delegate = self;
        searcher.titleLabel = title;
        BOOL flag = [searcher reverseGeoCode:reverseGeoCodeSearchOption];
        if(!flag){
            NSLog(@"反geo检索发送失败");
        }
        UITableView *tv = (UITableView *)[customView viewWithTag:8002];
        [tv scrollsToTop];
    }
}

//接收反向地理编码结果
-(void) onGetReverseGeoCodeResult:(BMKGeoCodeSearch *)searcher result: (BMKReverseGeoCodeResult *)result errorCode:(BMKSearchErrorCode)error{
    if (error == BMK_SEARCH_NO_ERROR) {
//        if (result.poiList.count>0) {
//            searcher.titleLabel.text = [(BMKPoiInfo *)result.poiList[0] name];
//        }else{
            searcher.titleLabel.text = [[result.addressDetail.district stringByAppendingString:result.addressDetail.streetName] stringByAppendingString:result.addressDetail.streetNumber];
//        }
    }else{
        searcher.titleLabel.text = @"无法获取位置信息";
    }
    searcher.delegate = nil;
}

- (BMKAnnotationView *)mapView:(BMKMapView *)mapView viewForAnnotation:(id<BMKAnnotation>)annotation
{
    static NSString *const TBAnnotatioViewReuseID = @"TBAnnotatioViewReuseID";
    
    TBClusterAnnotationView *annotationView = (TBClusterAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:TBAnnotatioViewReuseID];
    
    if (!annotationView) {
        annotationView = [[TBClusterAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:TBAnnotatioViewReuseID];
    }else{
        annotationView.annotation = annotation;
        annotationView.markerColor = nil;
    }
    
    TBClusterAnnotation *ca = (TBClusterAnnotation *)annotation;
    annotationView.count = ca.count;
    annotationView.canShowCallout = true;
    if (ca.stations.count == 0) {
        ca.title = [NSString stringWithFormat:@"%ld个站点,放大可显示详情",(long)ca.count];
    }else if(ca.stations.count ==1) {
//        annotationView.paopaoView = [[BMKActionPaopaoView alloc] initWithCustomView:[[UIView alloc] initWithFrame:CGRectZero]];
        JDOStationModel *station = ca.stations[0];
        ca.title = station.name;
//        if ([station.fid isEqualToString:self.selectedStation.fid]) {
//            annotationView.markerColor = [UIColor orangeColor];
//        }
    }else{
        annotationView.paopaoView = [self createPaoPaoView:ca.stations];
    }
    
    return annotationView;
}

- (BMKActionPaopaoView *)createPaoPaoView:(NSArray *)paopaoLines{
    float tableHeight = paopaoLines.count*PaoPaoLineHeight;
    // 计算最长的站点名称宽度
    float tableWidth = 0;
    for (int i=0; i<paopaoLines.count; i++) {
        JDOStationModel *station = paopaoLines[i];
        float width = [station.name sizeWithFont:[UIFont systemFontOfSize:14] forWidth:MAXFLOAT lineBreakMode:NSLineBreakByWordWrapping].width;
        tableWidth = MAX(tableWidth, width+10);
    }
    tableWidth = MAX(tableWidth,140);
    
    UIView *customView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableWidth, 35+tableHeight+12)];
    UIImageView *header = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, tableWidth, 35)];
    header.image = [UIImage imageNamed:@"弹出列表01"];
    [customView addSubview:header];
    
    UILabel *title = [[UILabel alloc] initWithFrame:header.bounds];
    title.backgroundColor = [UIColor clearColor];   // iOS7以下label背景色为白色，以上为透明
    title.font = [UIFont boldSystemFontOfSize:15];
    title.minimumFontSize = 12;
    title.adjustsFontSizeToFitWidth = true;
    title.textColor = [UIColor whiteColor];
    title.textAlignment = NSTextAlignmentCenter;
    title.tag = 8001;
//    title.text = @"正在获取位置";
    [customView addSubview:title];
    
    UIImageView *footer = [[UIImageView alloc] initWithFrame:CGRectMake(0, 35+tableHeight+12-51, tableWidth, 51)];
    footer.image = [UIImage imageNamed:@"弹出列表04"];
    [customView addSubview:footer];
    
    JDOPaoPaoTable2 *paopaoTable = [[JDOPaoPaoTable2 alloc] initWithFrame:CGRectMake(0, 35, tableWidth, tableHeight)];
    paopaoTable.stations = paopaoLines;
    paopaoTable.rowHeight = PaoPaoLineHeight;
    paopaoTable.bounces = false;
    paopaoTable.separatorStyle = UITableViewCellSeparatorStyleNone;
    paopaoTable.delegate = self;
    paopaoTable.dataSource = self;
    paopaoTable.tag = 8002;
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
        return _selectedStation.passLines.count;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([tableView isKindOfClass:[JDOPaoPaoTable2 class]]) {
        static NSString *lineIdentifier = @"lineIdentifier";
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:lineIdentifier];
        if( cell == nil){
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:lineIdentifier];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            UILabel *lineLabel = [[UILabel alloc] initWithFrame:CGRectMake(5, 0, CGRectGetWidth(tableView.frame)-10, PaoPaoLineHeight)];
            lineLabel.backgroundColor = [UIColor clearColor];
            lineLabel.font = [UIFont systemFontOfSize:14];
            lineLabel.minimumFontSize = 12;
            lineLabel.numberOfLines = 1;
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
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"stationLine"]; // forIndexPath:indexPath];
        if (indexPath.row%2==0) {
            cell.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"隔行1"]];
        }else{
            cell.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"隔行2"]];
        }
        
        JDOBusLine *busLine = _selectedStation.passLines[indexPath.row];
        JDOBusLineDetail *lineDetail = busLine.lineDetailPair[0];
        [(UILabel *)[cell viewWithTag:1001] setText:busLine.lineName];
        [(UILabel *)[cell viewWithTag:1002] setText:lineDetail.lineDetail];
//        [[cell viewWithTag:1003] setHidden:!self.busMonitor.on];
        [[cell viewWithTag:1004] setHidden:(indexPath.row == _selectedStation.passLines.count-1)];  //最后一行不显示分割线
        
        return cell;
    }
}

//- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
//    if ([tableView isKindOfClass:[JDOPaoPaoTable2 class]]) {
//        return nil;
//    }else{
//        UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 320, 15)];
//        iv.image = [UIImage imageNamed:@"表格圆角上"];
//        return iv;
//    }
//}
//
//- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
//    if ([tableView isKindOfClass:[JDOPaoPaoTable2 class]]) {
//        return nil;
//    }else{
//        UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 320, 15)];
//        iv.image = [UIImage imageNamed:@"表格圆角下"];
//        return iv;
//    }
//}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if ([tableView isKindOfClass:[JDOPaoPaoTable2 class]]) {
        JDOPaoPaoTable2 *paopaoTable = (JDOPaoPaoTable2 *)tableView;
        _selectedStation = [paopaoTable.stations objectAtIndex:indexPath.row];
        [self showLineView];
    }
}

- (void) showLineView{
    _selectedStation.passLines = [NSMutableArray new];
    // 根据站点id查询通过的线路，并实时刷新最近的车辆
    int count = 0;
    FMResultSet *rs = [_db executeQuery:GetLinesByStation,_selectedStation.fid];
    while ([rs next]) {
        JDOBusLine *busLine = [JDOBusLine new];
        [_selectedStation.passLines addObject:busLine];
        busLine.lineId = [rs stringForColumn:@"LINEID"];
        busLine.lineName = [rs stringForColumn:@"LINENAME"];
        busLine.zhixian = [rs intForColumn:@"ZHIXIAN"];
        busLine.lineDetailPair = [NSMutableArray new];
        
        JDOBusLineDetail *lineDetail = [JDOBusLineDetail new];
        [busLine.lineDetailPair addObject:lineDetail];
        lineDetail.detailId = [rs stringForColumn:@"LINEDETAILID"];
        lineDetail.lineDetail = [rs stringForColumn:@"LINEDETAIL"];
        lineDetail.direction = [rs stringForColumn:@"LINEDIRECTION"];
        
        count++;
    }
    [rs close];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
    
    self.stationLabel.text = _selectedStation.name;
//    self.busMonitor.on = false;
//    self.busMonitor.hidden = false;
    self.closeBtn.hidden = false;
    
    [UIView animateWithDuration:0.25f animations:^{
        float height = 56+36*MIN(count,4);
        self.lineView.frame = CGRectMake(10, CGRectGetHeight(self.view.bounds)-height, 300, height);
        self.tableView.frame = CGRectMake(0, 49, 300, 36*MIN(count,4));
    } completion:^(BOOL finished) {
        
    }];
    
}

- (void)closeLineView{
    [UIView animateWithDuration:0.25f animations:^{
        self.lineView.frame = CGRectMake(10, CGRectGetHeight(self.view.bounds)-44, 300, 44);
    } completion:^(BOOL finished) {
        self.stationLabel.text = @"请选择站点";
//        self.busMonitor.hidden = true;
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


- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (tableView == self.tableView) {
        selectedIndexPath = indexPath;
    }
    return indexPath;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"toRealtimeFromStation"]) {
        JDORealTimeController *rt = segue.destinationViewController;
        JDOBusLine *busLine = _selectedStation.passLines[selectedIndexPath.row];
        busLine.nearbyStationPair = [NSMutableArray arrayWithObject:_selectedStation];
        rt.busLine = busLine;
        rt.busLine.zhixian = busLine.zhixian;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
