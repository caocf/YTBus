//
//  JDORealTimeController.m
//  YTBus
//
//  Created by zhang yi on 14-10-21.
//  Copyright (c) 2014年 胶东在线. All rights reserved.
//

#import "JDORealTimeController.h"
#import "BMapKit.h"
#import "JDOBusLineDetail.h"
#import "JDOStationModel.h"
#import "JDODatabase.h"
#import "JDORealTimeMapController.h"
#import "JDOConstants.h"
#import "JSONKit.h"
#import "JDOBusModel.h"
#import "CMPopTipView.h"

#define GrayColor [UIColor colorWithRed:110/255.0f green:110/255.0f blue:110/255.0f alpha:1.0f]

@interface JDORealTimeCell : UITableViewCell

@property (nonatomic,assign) IBOutlet UIImageView *stationIcon;
@property (nonatomic,assign) IBOutlet UILabel *stationName;
@property (nonatomic,assign) IBOutlet UILabel *stationSeq;
@property (nonatomic,assign) IBOutlet UIButton *arrivingBus;
@property (nonatomic,assign) IBOutlet UIButton *arrivedBus;
@property (nonatomic,assign) IBOutlet UILabel *busNumLabel;
@property (nonatomic,assign) IBOutlet UIImageView *busNumBorder;

@property (nonatomic,assign) JDORealTimeController *controller;
@property (nonatomic,strong) CMPopTipView *popTipView;

@end

@implementation JDORealTimeCell

- (IBAction)onBusClicked:(id)sender{
    [self.controller showBusMenu:self];
}

//- (void)prepareForReuse{
//    [super prepareForReuse];
//}

@end

@interface JDORealTimeController () <NSXMLParserDelegate,CMPopTipViewDelegate> {
    NSMutableArray *_stations;
    FMDatabase *_db;
    id dbObserver;
    NSMutableData *_webData;
    NSTimer *_timer;
    BOOL isLoadFinised;
    NSURLConnection *_connection;
    BOOL isRecording;
    NSMutableString *_jsonResult;
    NSMutableSet *_busIndexSet;
    JDOStationModel *selectedStartStation;
    BOOL notHintSelectStart;
}

@property (nonatomic,assign) IBOutlet UILabel *lineDetail;
@property (nonatomic,assign) IBOutlet UILabel *startTime;
@property (nonatomic,assign) IBOutlet UILabel *endTime;
@property (nonatomic,assign) IBOutlet UILabel *price;
@property (nonatomic,assign) IBOutlet UIButton *directionBtn;
@property (nonatomic,assign) IBOutlet UIButton *favorBtn;
@property (nonatomic,assign) IBOutlet UITableView *tableView;
@property (nonatomic,assign) IBOutlet UIView *topBackground;

@property (nonatomic,assign) IBOutlet UIButton *reportErrorBtn;
@property (nonatomic,assign) IBOutlet UIButton *shareBtn;
@property (nonatomic,assign) IBOutlet UIView *menu;

@property (nonatomic,strong) NSMutableArray *visiblePopTipViews;
@property (nonatomic,strong) NSMutableArray *realBusList;


- (IBAction)changeDirection:(id)sender;
- (IBAction)clickFavor:(id)sender;

@end

@implementation JDORealTimeController{
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = _busLine.lineName;
    self.navigationItem.rightBarButtonItem.enabled = false;
    isLoadFinised = false;
    
    _stations = [NSMutableArray new];
    _db = [JDODatabase sharedDB];
    if (_db) {
        [self loadData];
    }else{
        dbObserver = [[NSNotificationCenter defaultCenter] addObserverForName:@"db_finished" object:nil queue:nil usingBlock:^(NSNotification *note) {
            _db = [JDODatabase sharedDB];
            [self loadData];
        }];
    }
    
    self.tableView.sectionHeaderHeight = 15;
    self.tableView.sectionFooterHeight = 15;
    self.tableView.backgroundColor = [UIColor colorWithHex:@"dfded9"];
    
    _topBackground.backgroundColor=(_busLine.showingIndex==0?[UIColor colorWithHex:@"d2ebed"]:[UIColor colorWithHex:@"d2eddb"]);
    self.visiblePopTipViews = [NSMutableArray array];
}

- (void) toggleMenu {
    BOOL isHidden = self.menu.hidden;
    if(isHidden) {
        self.menu.hidden = NO;
    }
    [UIView animateWithDuration:0.4 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        CGRect menuFrame = self.menu.frame;
        menuFrame.origin.y = isHidden?0.0f:-menuFrame.size.height;
        self.menu.frame = menuFrame;
        self.menu.alpha = isHidden?0.8f:0.0f;
    } completion:^(BOOL finished) {
        if (!isHidden) {
            self.menu.hidden = YES;
        }
    }];
}

- (void)loadData{
    [self loadBothDirectionLineDetailAndTargetStation];
    [self loadCurrentLineInfoAndAllStations];
    
    self.navigationItem.rightBarButtonItem.enabled = true;
    [self setFavorBtnState];
    
    [self scrollToTargetStation:true];
}

- (void)setFavorBtnState {  // 收藏标志
    NSArray *favorLineIds = [[NSUserDefaults standardUserDefaults] arrayForKey:@"favor_line"];
    if (favorLineIds) {
        _favorBtn.selected = false;
        JDOBusLineDetail *lineDetail = _busLine.lineDetailPair[_busLine.showingIndex];
        for (int i=0; i<favorLineIds.count; i++) {
            NSString *lineDetailId = favorLineIds[i];
            if([lineDetail.detailId isEqualToString:lineDetailId]){
                _favorBtn.selected = true;
                break;
            }
        }
    }
}

- (void)loadBothDirectionLineDetailAndTargetStation{
    if(_busLine.lineDetailPair.count==2 ){
        return;
    }
    
    NSMutableArray *lineDetails = [NSMutableArray new];
    NSString *getDetailIdByLineId = @"select ID,DIRECTION from BusLineDetail where BUSLINEID = ?";
    FMResultSet *rs = [_db executeQuery:getDetailIdByLineId,_busLine.lineId];
    while ([rs next]) {
        JDOBusLineDetail *aLineDetail = [JDOBusLineDetail new];
        aLineDetail.detailId = [rs stringForColumn:@"ID"];
        aLineDetail.direction = [rs stringForColumn:@"DIRECTION"];
        [lineDetails addObject:aLineDetail];
    }
    if(lineDetails.count == 0){
        NSLog(@"线路无详情数据");
        return;
    }
    // 从线路进入时，没有lineDetail
    if (!_busLine.lineDetailPair || _busLine.lineDetailPair.count ==0) {
        _busLine.lineDetailPair = lineDetails;
        _busLine.nearbyStationPair = [NSMutableArray arrayWithObjects:[NSNull null],[NSNull null],nil];
    }else if(_busLine.lineDetailPair.count == 1){
        // 从附近进入，且附近只有单向线路 或者从站点进入
        if ( lineDetails.count == 2) {  // 重新查询出双向线路
            JDOBusLineDetail *d0 = _busLine.lineDetailPair[0];
            JDOBusLineDetail *d1 = lineDetails[0];
            JDOBusLineDetail *d2 = lineDetails[1];
            JDOBusLineDetail *converseLine;
            if ([d0.detailId isEqualToString:d1.detailId]) {
                converseLine = d2;
                _busLine.lineDetailPair = [NSMutableArray arrayWithObjects:d1,d2,nil];
            }else{
                converseLine = d1;
                _busLine.lineDetailPair = [NSMutableArray arrayWithObjects:d2,d1,nil];
            }
//            [_busLine.lineDetailPair addObject:converseLine];
            
            if (_busLine.nearbyStationPair && _busLine.nearbyStationPair.count >0) {
                JDOStationModel *cStation = [self findStationByLine:converseLine andConverseStation:_busLine.nearbyStationPair[0]];
                if (cStation) {
                    [_busLine.nearbyStationPair addObject:cStation];
                }else{
                    [_busLine.nearbyStationPair addObject:[NSNull null]];
                }
            }else{
                _busLine.nearbyStationPair = [NSMutableArray arrayWithObjects:[NSNull null],[NSNull null],nil];
            }
            
        }
    }else{
        NSLog(@"线路超过两条!");
    }
}

- (void) loadCurrentLineInfoAndAllStations{
    isLoadFinised = false;
    
    // 选择显示方向线路详情
    JDOBusLineDetail *lineDetail = _busLine.lineDetailPair[_busLine.showingIndex];
    NSString *lineDetailId = lineDetail.detailId;
    
    NSString *getDetailById = @"select BUSLINENAME,PRICE,FIRSTTIME,LASTTIME from BusLineDetail where id = ?";
    FMResultSet *rs = [_db executeQuery:getDetailById,lineDetailId];
    if ([rs next]) {
        _lineDetail.text = [rs stringForColumn:@"BUSLINENAME"];
        _startTime.text = [rs stringForColumn:@"FIRSTTIME"];
        _endTime.text = [rs stringForColumn:@"LASTTIME"];
        _price.text = [NSString stringWithFormat:@"%g",[rs doubleForColumn:@"PRICE"]];
    }
    
    // 加载该线路的所有站点信息
    [_stations removeAllObjects];
    rs = [_db executeQuery:GetStationsByLineDetail,lineDetailId];
    while ([rs next]) {
        JDOStationModel *station = [JDOStationModel new];
        station.fid = [rs stringForColumn:@"STATIONID"];
        station.name = [rs stringForColumn:@"STATIONNAME"];
        station.direction = [rs stringForColumn:@"DIRECTION"];
        station.gpsX = [NSNumber numberWithDouble:[rs doubleForColumn:@"GPSX"]];
        station.gpsY = [NSNumber numberWithDouble:[rs doubleForColumn:@"GPSY"]];
        [_stations addObject:station];
    }
    
    [_busIndexSet removeAllObjects];
    [_tableView reloadData];
    
    isLoadFinised = true;
}

- (JDOStationModel *) findStationByLine:(JDOBusLineDetail *)lineDetail andConverseStation:(JDOStationModel *)station{
    FMResultSet *rs = [_db executeQuery:GetConverseStation,station.name,lineDetail.detailId];
    if ([rs next]) {
        JDOStationModel *station = [JDOStationModel new];
        station.fid = [rs stringForColumn:@"STATIONID"];
        station.name = [rs stringForColumn:@"STATIONNAME"];
        station.direction = [rs stringForColumn:@"DIRECTION"];
        station.gpsX = [NSNumber numberWithDouble:[rs doubleForColumn:@"GPSX"]];
        station.gpsY = [NSNumber numberWithDouble:[rs doubleForColumn:@"GPSY"]];
        return station;
    }
    return nil;
}

- (void)viewWillAppear:(BOOL)animated{
    [MobClick beginLogPageView:@"realtime"];
    [MobClick event:@"realtime"];
    [MobClick beginEvent:@"realtime"];
    
    int interval = [[NSUserDefaults standardUserDefaults] integerForKey:@"refresh_interval"]?:10;
    _timer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(refreshData:) userInfo:nil repeats:true];
    [_timer fire];
    [self scrollToTargetStation:false];
}

- (void)viewWillDisappear:(BOOL)animated{
    [MobClick endLogPageView:@"realtime"];
    [MobClick endEvent:@"realtime"];
    
    if ( _timer && [_timer isValid]) {
        [_timer invalidate];
        _timer = nil;
    }
}

- (void) refreshData:(NSTimer *)timer{
    // 若开启到站提醒，也可以在后台运行时继续执行定时器，一直到程序进程超时被关闭时再请求后台推送
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateActive) {
        return;
    }
    // 双向站点列表未加载完成,延迟1秒再刷新
    if( !isLoadFinised ){
        timer.fireDate = [NSDate dateWithTimeInterval:1 sinceDate:[NSDate date]];
        return;
    }
    
    if (!_busLine.lineDetailPair || _busLine.lineDetailPair.count==0) {
        NSLog(@"线路详情不存在");
        return;
    }
    if (!_busLine.nearbyStationPair || _busLine.nearbyStationPair.count==0 ) {
        NSLog(@"站点信息不存在");
        return;
    }
    JDOStationModel *startStation;
    if(selectedStartStation){
        startStation = selectedStartStation;
    }else if (_busLine.nearbyStationPair[_busLine.showingIndex] == [NSNull null]) {
        // 没有附近站点的时候，以线路终点站作为实时数据获取的参照物
//        startStation = [_stations lastObject];
        // 没有附近站点的时候，不显示实时数据
        if(!notHintSelectStart){
            [JDOUtils showHUDText:@"请选择起始站点" inView:self.view];
            notHintSelectStart = true;
        }
        return;
    }else{
        startStation = _busLine.nearbyStationPair[_busLine.showingIndex];
    }
    NSString *stationId = startStation.fid;
    NSString *busLineId = _busLine.lineId;
    JDOBusLineDetail *lineDetail = _busLine.lineDetailPair[_busLine.showingIndex];
    NSString *lineStatus = [lineDetail.direction isEqualToString:@"下行"]?@"1":@"2";
    
    NSString *soapMessage = [NSString stringWithFormat:GetBusLineStatus_MSG,stationId,busLineId,lineStatus];
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
//    NSString *XML = [[NSString alloc] initWithBytes:[_webData mutableBytes] length:[_webData length] encoding:NSUTF8StringEncoding];
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
            if (_busIndexSet.count>0) {
                [_busIndexSet removeAllObjects];
                [self.tableView reloadData];
            }
        }else{
            _realBusList = [_jsonResult objectFromJSONString];
            if (!_realBusList) {
                [JDOUtils showHUDText:@"实时数据JSON格式错误" inView:self.view];
            }else{
                [self redrawBus];
            }
        }
    }
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError{
    [JDOUtils showHUDText:[NSString stringWithFormat:@"解析实时数据XML错误：%@",parseError] inView:self.view];
}

- (void) redrawBus{
    NSMutableSet *oldIndexSet;
    if (!_busIndexSet) {
        _busIndexSet = [NSMutableSet new];
    }else{
        oldIndexSet = [NSMutableSet setWithSet:_busIndexSet];
        [_busIndexSet removeAllObjects];
    }
    
    for (int i=0; i<_realBusList.count; i++){
        NSDictionary *dict = _realBusList[i];
        JDOBusModel *bus = [[JDOBusModel alloc] initWithDictionary:dict];
        int stationIndex = -1;
        for (int j=0; j<_stations.count; j++) {
            JDOStationModel *aStation = _stations[j];
            if ([aStation.fid isEqualToString:bus.toStationId]) {
                stationIndex = j;
                break;
            }
        }
        if (stationIndex >=0) {
            [_busIndexSet addObject:[NSIndexPath indexPathForRow:stationIndex inSection:0]];
        }
    }
    
    if (!oldIndexSet) {
        [self.tableView reloadData];
    }else{  // 对比可视范围内索引有变化才刷新
        NSArray *visibleCells = [self.tableView visibleCells];
        
        NSMutableSet *toKeep = [NSMutableSet setWithSet:oldIndexSet];
        [toKeep intersectSet:_busIndexSet];
        NSMutableSet *toAdd = [NSMutableSet setWithSet:_busIndexSet];
        [toAdd minusSet:toKeep];
        NSMutableSet *toRemove = [NSMutableSet setWithSet:oldIndexSet];
        [toRemove minusSet:_busIndexSet];
        
        NSMutableSet *toRefresh = [NSMutableSet set];
        for (int i=0; i<visibleCells.count; i++) {
            JDORealTimeCell *cell = visibleCells[i];
            NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
            if ([toAdd containsObject:indexPath] || [toRemove containsObject:indexPath] ) {
                [toRefresh addObject:indexPath];
            }
            if ([toRemove containsObject:indexPath] && cell.popTipView) {
                [cell.popTipView dismissAnimated:true];
                cell.popTipView = nil;
            }
        }
        [self.tableView reloadRowsAtIndexPaths:[toRefresh allObjects]  withRowAnimation:UITableViewRowAnimationNone];
    }
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"toRealtimeMap"]) {
        JDORealTimeMapController *rt = segue.destinationViewController;
        rt.stations = _stations;
        JDOStationModel *startStation;
        if(selectedStartStation){
            startStation = selectedStartStation;
        }else if(_busLine.nearbyStationPair.count>0 && _busLine.nearbyStationPair[_busLine.showingIndex]!=[NSNull null]) {
            startStation = _busLine.nearbyStationPair[_busLine.showingIndex];
        }else{
            return;
        }
        startStation.start = true;
        
        rt.stationId = startStation.fid;
        rt.lineId = _busLine.lineId;
        JDOBusLineDetail *lineDetail = _busLine.lineDetailPair[_busLine.showingIndex];
        rt.lineStatus = [lineDetail.direction isEqualToString:@"下行"]?@"1":@"2";
    }
}

- (IBAction)changeDirection:(id)sender{
    if (_busLine.lineDetailPair.count !=2 ) {
        [JDOUtils showHUDText:@"该条线路为单向线路" inView:self.view];
        return;
    }
    
    _busLine.showingIndex = (_busLine.showingIndex==0?1:0);
    _topBackground.backgroundColor=(_busLine.showingIndex==0?[UIColor colorWithHex:@"d2ebed"]:[UIColor colorWithHex:@"d2eddb"]);
    [self loadCurrentLineInfoAndAllStations];
    [self setFavorBtnState];
    [_timer fire];

    // 若换向前有手动选中的站点，则换向后查找同名站点并选中
    if (selectedStartStation){
        JDOStationModel *converseStation;
        for(int i=0; i<_stations.count; i++){
            JDOStationModel *aStation = _stations[i];
            if([aStation.name isEqualToString:selectedStartStation.name]){
                converseStation = aStation;
                break;
            }
        }
        if(converseStation){
            selectedStartStation = converseStation;
        }
    }
    [self scrollToTargetStation:true];
}

- (void) scrollToTargetStation:(BOOL) animated{
    JDOStationModel *station;
    if (selectedStartStation){
        station = selectedStartStation;
    }else if (_busLine.nearbyStationPair[_busLine.showingIndex] == [NSNull null]) {
//        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:_stations.count-1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:animated];
    }else{
        station = _busLine.nearbyStationPair[_busLine.showingIndex];
    }
    
    if(station){
        NSUInteger index = [_stations indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
            if ([((JDOStationModel *)obj).fid isEqualToString:station.fid]) {
                return true;
            }
            return false;
        }];
        if (index != NSNotFound) {
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:animated];
        }
    }
}

- (IBAction)clickFavor:(UIButton *)sender{
    NSMutableArray *favorLineIds = [[[NSUserDefaults standardUserDefaults] arrayForKey:@"favor_line"] mutableCopy];
    if(!favorLineIds){
        favorLineIds = [NSMutableArray new];
    }
    JDOBusLineDetail *lineDetail = _busLine.lineDetailPair[_busLine.showingIndex];
    sender.selected = !sender.selected;
    if (sender.selected) {
        [favorLineIds addObject:lineDetail.detailId];
    }else{
        [favorLineIds removeObject:lineDetail.detailId];
    }
    [[NSUserDefaults standardUserDefaults] setObject:favorLineIds forKey:@"favor_line"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"favor_line_changed" object:nil];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_stations count];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 320, 15)];
    iv.image = [UIImage imageNamed:@"表格圆角上"];
    return iv;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 320, 15)];
    iv.image = [UIImage imageNamed:@"表格圆角下"];
    return iv;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    JDORealTimeCell *cell = [tableView dequeueReusableCellWithIdentifier:@"lineStation" forIndexPath:indexPath];
    cell.controller = self;
    JDOStationModel *station = _stations[indexPath.row];
    station.start = false;
    
    if(selectedStartStation){
        if ([station.fid isEqualToString:selectedStartStation.fid]) {
            station.start = true;
        }else{
            station.start = false;
        }
    }else if(_busLine.nearbyStationPair.count>0 && _busLine.nearbyStationPair[_busLine.showingIndex]!=[NSNull null]){
        JDOStationModel *startStation = _busLine.nearbyStationPair[_busLine.showingIndex];
        if ([station.fid isEqualToString:startStation.fid]) {
            station.start = true;
        }else{
            station.start = false;
        }
    }else{
        // 从线路进入，则无法预知起点，默认将终点站设置为参考站点
//        if (indexPath.row == _stations.count-1){
//            station.start = true;
//        }else{
            station.start = false;
//        }
    }
    
    if (station.isStart) {
        cell.stationIcon.image = [self imageAtPosition:indexPath.row selected:true];
        cell.stationSeq.textColor = [UIColor whiteColor];
        cell.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"表格选中背景"]];
    }else{
        cell.stationIcon.image = [self imageAtPosition:indexPath.row selected:false];
        cell.stationSeq.textColor = GrayColor;
        cell.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"表格圆角中"]];
    }
    
    [cell.stationName setText:station.name];
    [cell.stationSeq setText:[NSString stringWithFormat:@"%d",indexPath.row+1]];
    CGRect stationFrame = cell.stationName.frame;
    
    if (_busIndexSet && [_busIndexSet containsObject:indexPath]) {
        cell.arrivedBus.hidden = false;
        int busNumInSameStation = 0;    // 检查是否超过1辆车
        for (int i=0; i<_realBusList.count; i++){
            NSDictionary *dict = _realBusList[i];
            JDOBusModel *bus = [[JDOBusModel alloc] initWithDictionary:dict];
            if([bus.toStationId isEqualToString:station.fid]){
                busNumInSameStation++;
            }
        }
        if (busNumInSameStation > 1) {
            cell.busNumLabel.hidden = cell.busNumBorder.hidden = false;
            cell.busNumLabel.text = [NSString stringWithFormat:@"%d",busNumInSameStation];
            stationFrame.size.width = 205;
            cell.stationName.frame = stationFrame;
        }else{
            cell.busNumLabel.hidden = cell.busNumBorder.hidden = true;
            stationFrame.size.width = 223;
            cell.stationName.frame = stationFrame;
        }
    }else{
        cell.arrivedBus.hidden = true;
        cell.busNumLabel.hidden = cell.busNumBorder.hidden = true;
        stationFrame.size.width = 250;
        cell.stationName.frame = stationFrame;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    selectedStartStation = _stations[indexPath.row];
    [tableView reloadData];
    [_timer fire];
}

- (UIImage *) imageAtPosition:(int)pos selected:(BOOL)selected{
    NSString *imageName;
    if (pos == 0) {
        imageName = selected?@"起点选中":@"起点";
    }else if(pos ==_stations.count-1){
        imageName = selected?@"终点选中":@"终点";
    }else{
        imageName = selected?@"中间选中":@"中间";
    }
    return [UIImage imageNamed:imageName];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)dealloc{
    if (dbObserver) {
        [[NSNotificationCenter defaultCenter] removeObserver:dbObserver];
    }
}

- (void)showBusMenu:(JDORealTimeCell *)cell{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    JDOStationModel *station = _stations[indexPath.row];
    
    int count = 0;
    UIView *contentView = [[UIView alloc] initWithFrame:CGRectZero];
    contentView.backgroundColor = [UIColor clearColor];
    
    for (int i=0; i<_realBusList.count; i++){
        NSDictionary *dict = _realBusList[i];
        JDOBusModel *bus = [[JDOBusModel alloc] initWithDictionary:dict];
        if ([station.fid isEqualToString:bus.toStationId]) {
            UILabel *busNo = [[UILabel alloc] initWithFrame:CGRectMake(10, count*40+8, 120, 24)];
            busNo.text = [NSString stringWithFormat:@"车牌号:%@",bus.busNo];
            busNo.textColor = [UIColor whiteColor];
            busNo.font = [UIFont systemFontOfSize:14];
            [contentView addSubview:busNo];
            
            double distance = 0;
            for (NSInteger j=indexPath.row+1; j<_stations.count; j++) {
                JDOStationModel *aStation = _stations[j];
                if (j == indexPath.row+1) {
                    CLLocationCoordinate2D busPos = BMKCoorDictionaryDecode(BMKConvertBaiduCoorFrom(CLLocationCoordinate2DMake(bus.gpsY.doubleValue, bus.gpsX.doubleValue),BMK_COORDTYPE_GPS));
                    CLLocationCoordinate2D stationPos = CLLocationCoordinate2DMake(aStation.gpsY.doubleValue, aStation.gpsX.doubleValue);
                    distance+=BMKMetersBetweenMapPoints(BMKMapPointForCoordinate(busPos),BMKMapPointForCoordinate(stationPos));
                }else{
                    JDOStationModel *stationB = _stations[j-1];
                    CLLocationCoordinate2D stationAPos = BMKCoorDictionaryDecode(BMKConvertBaiduCoorFrom(CLLocationCoordinate2DMake(aStation.gpsY.doubleValue, aStation.gpsX.doubleValue),BMK_COORDTYPE_GPS));
                    CLLocationCoordinate2D stationBPos = CLLocationCoordinate2DMake(stationB.gpsY.doubleValue, stationB.gpsX.doubleValue);
                    distance+=BMKMetersBetweenMapPoints(BMKMapPointForCoordinate(stationAPos),BMKMapPointForCoordinate(stationBPos));
                }
                if (aStation.isStart) {
                    break;
                }
            }
            UILabel *distanceLabel =[[UILabel alloc] initWithFrame:CGRectMake(140, count*40+8, 120, 24)];
            if (distance>999) {    //%.Ng代表N位有效数字(包括小数点前面的)，%.Nf代表N位小数位
                distanceLabel.text = [NSString stringWithFormat:@"距离：%.1f公里",distance/1000];
            }else{
                distanceLabel.text = [NSString stringWithFormat:@"距离：%d米",[@(distance) intValue]];
            }
            distanceLabel.textColor = [UIColor whiteColor];
            distanceLabel.font = [UIFont systemFontOfSize:14];
            [contentView addSubview:distanceLabel];
            
            count++;
        }
    }
    contentView.frame = CGRectMake(0, 0, 300, count*40);
    
    CMPopTipView *popTipView = [[CMPopTipView alloc] initWithCustomView:contentView];
    cell.popTipView = popTipView;
    popTipView.delegate = self;
    popTipView.disableTapToDismiss = true;
    popTipView.preferredPointDirection = PointDirectionUp;
    popTipView.hasGradientBackground = NO;
    popTipView.cornerRadius = 0.0f;
    popTipView.sidePadding = 10.0f;
    popTipView.topMargin = 0.0f;
    popTipView.pointerSize = 6.0f;
    popTipView.hasShadow = NO;
    popTipView.backgroundColor = [UIColor colorWithRed:75/255.0f green:77/255.0f blue:88/255.0f alpha:1.0f];
    popTipView.textColor = [UIColor whiteColor];
    popTipView.animation = CMPopTipAnimationPop;
    popTipView.has3DStyle = false;
    popTipView.dismissTapAnywhere = YES;
    
    [popTipView presentPointingAtView:cell.arrivedBus inView:self.view animated:YES];
    [self.visiblePopTipViews addObject:popTipView];
    
//    self.currentPopTipViewTarget = sender;
    
}

- (void)popTipViewWasDismissedByUser:(CMPopTipView *)popTipView{
    [self.visiblePopTipViews removeObject:popTipView];
//    self.currentPopTipViewTarget = nil;
}

@end
