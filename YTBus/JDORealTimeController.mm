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
#import "JDORealTimeCell.h"
#import "JDORealTimeMapController.h"
#import "JDOConstants.h"
#import "JSONKit.h"

@interface JDORealTimeController () <NSXMLParserDelegate> {
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
}

@property (nonatomic,assign) IBOutlet UILabel *lineDetail;
@property (nonatomic,assign) IBOutlet UILabel *startTime;
@property (nonatomic,assign) IBOutlet UILabel *endTime;
@property (nonatomic,assign) IBOutlet UILabel *price;
@property (nonatomic,assign) IBOutlet UIButton *directionBtn;
@property (nonatomic,assign) IBOutlet UIButton *favorBtn;
@property (nonatomic,assign) IBOutlet UITableView *tableView;

- (IBAction)changeDirection:(id)sender;
- (IBAction)clickFavor:(id)sender;

@end

@implementation JDORealTimeController

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
}

- (void)loadData{
    // 从线路进入时，没有lineDetail；或者从附近进入但双向线路不全，都需要从数据库加载
    if(!_busLine.lineDetailPair || _busLine.lineDetailPair.count<2){
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
        if (_busLine.lineDetailPair.count == 1 && lineDetails.count == 2) {
            JDOBusLineDetail *d1 = _busLine.lineDetailPair[0];
            JDOBusLineDetail *d2 = lineDetails[0];
            if ([d1.detailId isEqualToString:d2.detailId]) {
                _busLine.showingIndex = 0;
            }else{
                _busLine.showingIndex = 1;
            }
        }else{
            _busLine.showingIndex = 0;
        }
        _busLine.lineDetailPair = lineDetails;
    }
    
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
    [_tableView reloadData];
    self.navigationItem.rightBarButtonItem.enabled = true;
    
    // 收藏标志
    NSArray *favorLineIds = [[NSUserDefaults standardUserDefaults] arrayForKey:@"favor_line"];
    if (favorLineIds) {
        for (int i=0; i<favorLineIds.count; i++) {
            NSString *lineId = favorLineIds[i];
            if([_busLine.lineId isEqualToString:lineId]){
                [_favorBtn setTitle:@"已收藏" forState:UIControlStateNormal];
                break;
            }
        }
    }
    
    isLoadFinised = true;   // 站点加载完成后timer可以开始获取实时数据，在这之前获取到也没有地方进行绘制
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    _timer = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(refreshData:) userInfo:nil repeats:true];
    [_timer fire];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    if ( _timer && _timer.valid) {
        [_timer invalidate];
        _timer = nil;
    }
}

- (void) refreshData:(NSTimer *)timer{
    // 双向站点列表未加载完成
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
//        return;
        _busLine.nearbyStationPair = [@[[_stations lastObject]] mutableCopy];
    }
    NSString *busLineId = _busLine.lineId;
    JDOBusLineDetail *lineDetail = _busLine.lineDetailPair[_busLine.showingIndex];
    NSString *lineStatus = [lineDetail.direction isEqualToString:@"下行"]?@"1":@"2";
    JDOStationModel *startStation = _busLine.nearbyStationPair[_busLine.showingIndex];
    NSString *stationId = startStation.fid;
    
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
        [self redrawBus];
    }
}

- (void) redrawBus{
    // 清空之前绘制的bus图标
    NSArray *list = [_jsonResult objectFromJSONString];
    _busIndexSet = [NSMutableSet new];
    for (int i=0; i<list.count; i++){
        NSDictionary *dict = list[i];
        NSString *stationId = [dict objectForKey:@"站"];
        int stationIndex = -1;
        for (int j=0; j<_stations.count; j++) {
            JDOStationModel *aStation = _stations[j];
            if ([aStation.fid isEqualToString:stationId]) {
                stationIndex = j;
                break;
            }
        }
        if (stationIndex >=0) {
            [_busIndexSet addObject:[NSIndexPath indexPathForRow:stationIndex inSection:0]];
        }
    }
    [self.tableView reloadData];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"toRealtimeMap"]) {
        JDORealTimeMapController *rt = segue.destinationViewController;
        rt.stations = _stations;
    }
}

- (IBAction)changeDirection:(id)sender{
    
}

- (IBAction)clickFavor:(id)sender{
    NSString *title = [sender titleForState:UIControlStateNormal];
    NSMutableArray *favorLineIds = [[[NSUserDefaults standardUserDefaults] arrayForKey:@"favor_line"] mutableCopy];
    if(!favorLineIds){
        favorLineIds = [NSMutableArray new];
    }
    if ([title isEqualToString:@"收藏"]) {
        [favorLineIds addObject:_busLine.lineId];
        [_favorBtn setTitle:@"已收藏" forState:UIControlStateNormal];
    }else{
        [favorLineIds removeObject:_busLine.lineId];
        [_favorBtn setTitle:@"收藏" forState:UIControlStateNormal];
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


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    JDORealTimeCell *cell = [tableView dequeueReusableCellWithIdentifier:@"lineStation" forIndexPath:indexPath];
    JDOStationModel *station = _stations[indexPath.row];

    [cell.stationName setText:station.name];
    
    if(_busLine.nearbyStationPair.count>0){
        JDOStationModel *startStation = _busLine.nearbyStationPair[_busLine.showingIndex];
        if ([station.fid isEqualToString:startStation.fid]) {
            cell.stationIcon.image = [UIImage imageNamed:@"first"];
            station.start = true;
        }else{
            cell.stationIcon.image = [UIImage imageNamed:@"second"];
        }
    }else{  // 从线路进入，则无法预知起点
        cell.stationIcon.image = [UIImage imageNamed:@"second"];
    }
    
    if (_busIndexSet && [_busIndexSet containsObject:indexPath]) {
        cell.arrivingBus.image = [UIImage imageNamed:@"近"];
    }else{
        cell.arrivingBus.image = nil;
    }
    
    return cell;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)dealloc{
    if (dbObserver) {
        [[NSNotificationCenter defaultCenter] removeObserver:dbObserver];
    }
}

@end
