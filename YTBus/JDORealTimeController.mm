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
#import <ShareSDK/ShareSDK.h>
#import "JDOShareController.h"
#import "AppDelegate.h"
#import <QZoneConnection/ISSQZoneApp.h>
#import "JDOReportController.h"
#import "MBProgressHUD.h"

#define GrayColor [UIColor colorWithRed:110/255.0f green:110/255.0f blue:110/255.0f alpha:1.0f]
// TODO 原来的颜色太重了，换个浅一点的
//#define PopViewColor [UIColor colorWithRed:75/255.0f green:77/255.0f blue:88/255.0f alpha:1.0f]
#define PopViewColor [UIColor colorWithRed:150/255.0f green:154/255.0f blue:176/255.0f alpha:1.0f]
#define LineHeight 32

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

- (void)awakeFromNib{
    [super awakeFromNib];
    [self.stationSeq addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onStationClicked:)]];
    [self.stationName addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onStationClicked:)]];
}

- (IBAction)onBusClicked:(id)sender{
    [self.controller showBusMenu:self];
}

- (void)onStationClicked:(id)sender{
    [self.controller showStationMenu:self];
}

- (void)prepareForReuse{
    [super prepareForReuse];
}

@end

@interface JDOClockButton : UIButton

@property (nonatomic,strong) NSString *busNo;
@property (nonatomic,strong) NSString *stationId;

@end

@implementation JDOClockButton

@end

@interface JDOSetStartButton : UIButton

@property (nonatomic,assign) NSInteger row;
@property (nonatomic,weak) CMPopTipView *popView;

@end

@implementation JDOSetStartButton

@end

@interface JDOToMapButton : UIButton

@property (nonatomic,weak) CMPopTipView *popView;

@end

@implementation JDOToMapButton

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
    UIImage *screenImage;
    JDORealTimeCell *_currentPopTipViewCell;
    NSIndexPath *_currentPopTipViewIndexPath;
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
@property (nonatomic,assign) IBOutlet UIButton *dropDownBtn;

@property (nonatomic,strong) NSMutableArray *realBusList;


- (IBAction)changeDirection:(id)sender;
- (IBAction)clickFavor:(id)sender;
- (IBAction)toggleMenu:(id)sender;
- (IBAction)clickReport:(id)sender;
- (IBAction)clickShare:(id)sender;

@end

@implementation JDORealTimeController{
    BOOL isMenuHidden;
    MBProgressHUD *hud;
    BOOL isFirstRefreshData;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = _busLine.lineName;
    self.navigationItem.rightBarButtonItem.enabled = false;
    isLoadFinised = false;
    isMenuHidden = true;
    _isInit = true;
    
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
}

- (void) toggleMenu:(UIButton *)sender {
//    if (isMenuHidden) {
//        UIGraphicsBeginImageContextWithOptions([UIScreen mainScreen].bounds.size, YES, 0);
//        AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
//        [appDelegate.window.rootViewController.view.layer renderInContext:UIGraphicsGetCurrentContext()];
//        screenImage = UIGraphicsGetImageFromCurrentImageContext();
//        UIGraphicsEndImageContext();
//    }
    
    [UIView animateWithDuration:0.25f delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        CGRect menuFrame = self.menu.frame;
        menuFrame.origin.y = isMenuHidden?0:-69;
        self.dropDownBtn.transform = isMenuHidden?CGAffineTransformMakeRotation(M_PI):CGAffineTransformMakeRotation(2*M_PI);
        self.menu.frame = menuFrame;
    } completion:^(BOOL finished) {
        isMenuHidden = !isMenuHidden;
        if (isMenuHidden) {
            self.dropDownBtn.transform = CGAffineTransformIdentity;
        }
    }];
}

- (void)loadData{
    [self loadBothDirectionLineDetailAndTargetStation];
    [self loadCurrentLineInfoAndAllStations];
    
    self.navigationItem.rightBarButtonItem.enabled = true;
    [self setFavorBtnState];
    
    [self scrollToTargetStation:false];
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
    
    [self resetTimer];
    
    if (_isInit) {
        if (isLoadFinised) {
            [self scrollToTargetStation:false];
        }
        _isInit = false;
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetTimer) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void) resetTimer {
    int interval = [[NSUserDefaults standardUserDefaults] integerForKey:@"refresh_interval"]?:10;
    if (_timer && [_timer isValid]) {
        [_timer invalidate];
    }
    isFirstRefreshData = true;
    _timer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(refreshData:) userInfo:nil repeats:true];
    [_timer fire];
    
}

- (void)viewWillDisappear:(BOOL)animated{
    [MobClick endLogPageView:@"realtime"];
    [MobClick endEvent:@"realtime"];
    
    if ( _timer && [_timer isValid]) {
        [_timer invalidate];
        _timer = nil;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
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
        [JDOUtils showHUDText:@"请选择上车站点" inView:self.view];
        [_timer invalidate];
        _timer= nil;
        return;
    }else{
        startStation = _busLine.nearbyStationPair[_busLine.showingIndex];
    }
    
    if (isFirstRefreshData) {
        hud = [MBProgressHUD showHUDAddedTo:self.view animated:true];
        hud.mode = MBProgressHUDModeIndeterminate;
        hud.minShowTime = 0.5f;
        isFirstRefreshData = false;
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
    if (hud) {
        hud.mode = MBProgressHUDModeText;
        hud.labelText = [NSString stringWithFormat:@"网络连接异常:%ld",error.code];
        [hud hide:true afterDelay:1.0f];
        hud = nil;
    }else{
        [JDOUtils showHUDText:[NSString stringWithFormat:@"网络连接异常:%ld",error.code] inView:self.view];
        NSLog(@"error:%@",error);
    }
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
        // TODO 确定提示信息是否能区分开
        if (_jsonResult.length==0 || [_jsonResult isEqualToString:@"[]"]) {
            NSString *info;
            if (_jsonResult.length==0) {
                info = @"无法获取实时数据";
            }else{
                info = @"没有下一班次数据";
            }
            if (hud) {
                hud.mode = MBProgressHUDModeText;
                hud.labelText = info;
                [hud hide:true afterDelay:1.0f];
                hud = nil;
            }else{
                [JDOUtils showHUDText:info inView:self.view];
            }
            // 删除掉已经绘制的所有车辆，可能发生的情景是：最后一辆车开过参考站点，则要删除该车辆
            if (_busIndexSet.count>0) {
                [_busIndexSet removeAllObjects];
                [self.tableView reloadData];
            }
        }else{
            _realBusList = [_jsonResult objectFromJSONString];
            if (!_realBusList) {
                if (hud) {
                    hud.mode = MBProgressHUDModeText;
                    hud.labelText = @"实时数据格式错误";
                    [hud hide:true afterDelay:1.0f];
                    hud = nil;
                }else{
                    [JDOUtils showHUDText:@"实时数据格式错误" inView:self.view];
                }
            }else{
                if (hud) {
                    [hud hide:true];
                    hud = nil;
                }
                [self redrawBus];
            }
        }
    }
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError{
    if (hud) {
        hud.mode = MBProgressHUDModeText;
        hud.labelText = [NSString stringWithFormat:@"解析XML错误:%ld",parseError.code];
        [hud hide:true afterDelay:1.0f];
        hud = nil;
    }else{
        [JDOUtils showHUDText:[NSString stringWithFormat:@"解析XML错误:%ld",parseError.code] inView:self.view];
        NSLog(@"Error:%@",parseError);
    }
    
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
        NSMutableSet *toKeep = [NSMutableSet setWithSet:oldIndexSet];
        [toKeep intersectSet:_busIndexSet];
        NSMutableSet *toAdd = [NSMutableSet setWithSet:_busIndexSet];
        [toAdd minusSet:toKeep];
        NSMutableSet *toRemove = [NSMutableSet setWithSet:oldIndexSet];
        [toRemove minusSet:_busIndexSet];
        NSMutableSet *toRefresh = [NSMutableSet set];
        
        NSArray *visibleCells = [self.tableView visibleCells];
        for (int i=0; i<visibleCells.count; i++) {
            JDORealTimeCell *cell = visibleCells[i];
            NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
            if ([toAdd containsObject:indexPath] || [toRemove containsObject:indexPath] || [toKeep containsObject:indexPath]) {
                // toKeep也要刷新，因为有可能车辆从1辆变成2辆
                [toRefresh addObject:indexPath];
            }
//            cell有可能在上一次刷新的时候在同一个indexPath被替换过，所有目前indexPath位置上的cell不一定是弹出popView的cell
            if ([toRemove containsObject:indexPath] && _currentPopTipViewIndexPath == indexPath) {
                [_currentPopTipViewCell.popTipView dismissAnimated:true];
                _currentPopTipViewCell.popTipView = nil;
                _currentPopTipViewCell = nil;
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
        
        // 将当前车辆实时位置数据传递到地图中，避免地图界面第一次获取数据时间较长时没有车辆信息
        if (_realBusList && _realBusList.count>0) {
            rt.realBusList = [NSMutableArray arrayWithArray:_realBusList];
        }
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
    [self resetTimer];
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

- (JDOStationModel *) getStartStation{
    if(selectedStartStation){
        return selectedStartStation;
    }else if(_busLine.nearbyStationPair.count>0 && _busLine.nearbyStationPair[_busLine.showingIndex]!=[NSNull null]) {
        return _busLine.nearbyStationPair[_busLine.showingIndex];
    }
    return nil;
}

- (IBAction)clickReport:(id)sender{
    JDOStationModel *startStation = [self getStartStation];
    NSString *direction = [NSString stringWithFormat:@"%@ 开往 %@ 方向",self.busLine.lineName,[[_stations lastObject] name]];
    
    JDOReportController *vc = [[JDOReportController alloc] initWithStation:startStation.name direction:direction];
    UINavigationController *naVC = [[UINavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:naVC animated:true completion:nil];
}

- (IBAction)clickShare:(id)sender{
    NSString *content;
    JDOStationModel *startStation = [self getStartStation];
    
    if (startStation) {
        NSMutableArray *stationIds = [NSMutableArray new];
        for (int i=0; i<_stations.count; i++) {
            [stationIds addObject:[_stations[i] fid]];
        }
        NSUInteger maxIndex = 0;
        for (int i=0; i<_realBusList.count; i++){
            NSDictionary *dict = _realBusList[i];
            JDOBusModel *bus = [[JDOBusModel alloc] initWithDictionary:dict];
            NSUInteger index = [stationIds indexOfObject:bus.toStationId];
            if (index != NSNotFound && index > maxIndex) {
                maxIndex = index;
            }
        }
        if (maxIndex>0) {
            NSUInteger startIndex = [stationIds indexOfObject:startStation.fid];
            content = [NSString stringWithFormat:@"实时:%@公交开往\"%@\"方向，距离\"%@\"还有%lu站。",self.busLine.lineName,[[_stations lastObject] name], startStation.name,(startIndex-maxIndex)];
        }else{
            content = [NSString stringWithFormat:@"实时:%@公交开往\"%@\"方向，在\"%@\"之前尚未发车。",self.busLine.lineName,[[_stations lastObject] name], startStation.name];
        }
    }else{
        content = [NSString stringWithFormat:@"我正在查询%@公交车的实时位置，你也来试试吧。",self.busLine.lineName];
    }
    
    //构造分享内容，这里的content和titile提供给非微博类平台使用，微信好友使用titile、content不能超过26个字，朋友圈只使用title，图片使用logo。
    id<ISSContent> publishContent = [ShareSDK content:content
                                       defaultContent:nil
                                                image:[ShareSDK jpegImageWithImage:[UIImage imageNamed:@"分享80"] quality:1.0]
                                                title:@"“烟台公交”上线啦！等车不再捉急，到点准时来接你。"
                                                  url:@"http://m.jiaodong.net"
                                          description:content
                                            mediaType:SSPublishContentMediaTypeNews];
    //QQ使用title和content(大概26个字以内)，但能显示字数更少。
    [publishContent addQQUnitWithType:INHERIT_VALUE content:[NSString stringWithFormat:@"我正在查询%@车的实时位置,你也来试试吧!",self.busLine.lineName] title:@"“烟台公交”上线啦！" url:INHERIT_VALUE image:INHERIT_VALUE];
    [publishContent addQQSpaceUnitWithTitle:@"“烟台公交”上线啦！" url:INHERIT_VALUE site:@"胶东在线" fromUrl:@"http://www.jiaodong.net" comment:nil summary:content image:INHERIT_VALUE type:INHERIT_VALUE playUrl:INHERIT_VALUE nswb:INHERIT_VALUE];
    
    id<ISSQZoneApp> app =(id<ISSQZoneApp>)[ShareSDK getClientWithType:ShareTypeQQSpace];
    NSObject *qZone;
    if (app.isClientInstalled) {
        qZone = SHARE_TYPE_NUMBER(ShareTypeQQSpace);
    }else{
        qZone = [self getShareItem:ShareTypeQQSpace content:content];
    }
    
    NSArray *shareList = [ShareSDK customShareListWithType:SHARE_TYPE_NUMBER(ShareTypeWeixiSession),SHARE_TYPE_NUMBER(ShareTypeWeixiTimeline),SHARE_TYPE_NUMBER(ShareTypeQQ),qZone,[self getShareItem:ShareTypeSinaWeibo content:content],[self getShareItem:ShareTypeRenren content:content],nil];
    
    [ShareSDK showShareActionSheet:nil shareList:shareList content:publishContent statusBarTips:NO authOptions:nil shareOptions:nil result:^(ShareType type, SSResponseState state, id<ISSPlatformShareInfo> statusInfo, id<ICMErrorInfo> error, BOOL end) {
            if (state == SSResponseStateSuccess){
                NSLog(@"分享成功");
            }else if (state == SSResponseStateFail){
                [JDOUtils showHUDText:[NSString stringWithFormat:@"分享失败:%ld",(long)[error errorCode]] inView:self.view];
            }
        }
     ];
}

- (id<ISSShareActionSheetItem>) getShareItem:(ShareType) type content:(NSString *)content{
    return [ShareSDK shareActionSheetItemWithTitle:[ShareSDK getClientNameWithType:type] icon:[ShareSDK getClientIconWithType:type] clickHandler:^{
        JDOShareController *vc = [[JDOShareController alloc] initWithImage:screenImage content:content type:type];
        UINavigationController *naVC = [[UINavigationController alloc] initWithRootViewController:vc];
        [self presentViewController:naVC animated:true completion:nil];
    }];
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

//- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
//}

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

- (void)showStationMenu:(JDORealTimeCell *)cell{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
//    JDOStationModel *station = _stations[indexPath.row];
    
    if (![self getStartStation]) {  // 尚未选择上车站点的时候，单击直接选中
        selectedStartStation = _stations[indexPath.row];
        [_busIndexSet removeAllObjects];
        [self.tableView reloadData];
        [self resetTimer];
        return;
    }
    
    UIView *contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 300, LineHeight)];
    contentView.backgroundColor = [UIColor clearColor];
    
    JDOSetStartButton *setStartBtn = [JDOSetStartButton buttonWithType:UIButtonTypeCustom];
    setStartBtn.frame = CGRectMake(15, 0, 115, LineHeight);
    setStartBtn.row = indexPath.row;
    setStartBtn.titleLabel.font = [UIFont systemFontOfSize:14];
    [setStartBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [setStartBtn setTitle:@"选为上车站点" forState:UIControlStateNormal];
    [setStartBtn addTarget:self action:@selector(setToStartStation:) forControlEvents:UIControlEventTouchUpInside];
    [setStartBtn setImage:[UIImage imageNamed:@"圆点"] forState:UIControlStateNormal];
    [setStartBtn setTitleEdgeInsets:UIEdgeInsetsMake(0, 10, 0, 0)];
    [setStartBtn setImageEdgeInsets:UIEdgeInsetsMake(0, 1, 0, 99)];
    [contentView addSubview:setStartBtn];
    
    JDOToMapButton *toMapBtn = [JDOToMapButton buttonWithType:UIButtonTypeCustom];
    toMapBtn.frame = CGRectMake(170, 0, 115, LineHeight);
    toMapBtn.titleLabel.font = [UIFont systemFontOfSize:14];
    [toMapBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [toMapBtn setTitle:@"查看站点详情" forState:UIControlStateNormal];
    [toMapBtn addTarget:self action:@selector(showStationDetail:) forControlEvents:UIControlEventTouchUpInside];
    [toMapBtn setImage:[UIImage imageNamed:@"圆点"] forState:UIControlStateNormal];
    [toMapBtn setTitleEdgeInsets:UIEdgeInsetsMake(0, 10, 0, 0)];
    [toMapBtn setImageEdgeInsets:UIEdgeInsetsMake(0, 1, 0, 99)];
    [contentView addSubview:toMapBtn];
    
    CMPopTipView *popTipView = [[CMPopTipView alloc] initWithCustomView:contentView];
//    popTipView.delegate = self;
    popTipView.disableTapToDismiss = true;
    popTipView.preferredPointDirection = PointDirectionUp;
    popTipView.hasGradientBackground = NO;
    popTipView.cornerRadius = 0.0f;
    popTipView.sidePadding = 10.0f;
    popTipView.topMargin = 3.0f;
    popTipView.pointerSize = 3.0f;
    popTipView.hasShadow = true;
    popTipView.backgroundColor = PopViewColor;
    popTipView.textColor = [UIColor whiteColor];
    popTipView.animation = CMPopTipAnimationPop;
    popTipView.has3DStyle = false;
    popTipView.dismissTapAnywhere = YES;
    popTipView.borderWidth = 0;
    
    [popTipView presentPointingAtView:cell.stationSeq inView:self.view animated:YES];
    setStartBtn.popView = popTipView;
    toMapBtn.popView = popTipView;
}

- (void) setToStartStation:(JDOSetStartButton *)btn{
    [btn.popView dismissAnimated:true];
    selectedStartStation = _stations[btn.row];
    [_busIndexSet removeAllObjects];
    [self.tableView reloadData];
    [self resetTimer];
}

- (void) showStationDetail:(JDOToMapButton *)btn{
    [btn.popView dismissAnimated:false];
    // TODO
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
            UILabel *busNo = [[UILabel alloc] initWithFrame:CGRectMake(15, count*LineHeight+5, 120, 22)];
            busNo.text = [NSString stringWithFormat:@"车牌号：%@",bus.busNo];
            busNo.textColor = [UIColor whiteColor];
            busNo.backgroundColor = [UIColor clearColor];
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
                    CLLocationCoordinate2D stationAPos = CLLocationCoordinate2DMake(aStation.gpsY.doubleValue, aStation.gpsX.doubleValue);
                    CLLocationCoordinate2D stationBPos = CLLocationCoordinate2DMake(stationB.gpsY.doubleValue, stationB.gpsX.doubleValue);
                    distance+=BMKMetersBetweenMapPoints(BMKMapPointForCoordinate(stationAPos),BMKMapPointForCoordinate(stationBPos));
                }
                if (aStation.isStart) {
                    break;
                }
            }
            UILabel *distanceLabel =[[UILabel alloc] initWithFrame:CGRectMake(155, count*LineHeight+5, 105, 22)];
            if (distance>999) {    //%.Ng代表N位有效数字(包括小数点前面的)，%.Nf代表N位小数位
                distanceLabel.text = [NSString stringWithFormat:@"距离：%.1f公里",distance/1000];
            }else{
                distanceLabel.text = [NSString stringWithFormat:@"距离：%d米",[@(distance) intValue]];
            }
            distanceLabel.textColor = [UIColor whiteColor];
            distanceLabel.backgroundColor = [UIColor clearColor];
            distanceLabel.font = [UIFont systemFontOfSize:14];
            [contentView addSubview:distanceLabel];
            
            JDOClockButton *clock = [JDOClockButton buttonWithType:UIButtonTypeCustom];
            clock.frame = CGRectMake(267, count*LineHeight, LineHeight, LineHeight);
            clock.busNo = bus.busNo;
            clock.stationId = [self getStartStation].fid;
            clock.imageEdgeInsets = UIEdgeInsetsMake(8, 6, 7, 8);
            [clock setImage:[UIImage imageNamed:@"闹钟1"] forState:UIControlStateNormal];
            [clock setImage:[UIImage imageNamed:@"闹钟2"] forState:UIControlStateSelected];
            [clock addTarget:self action:@selector(setClock:) forControlEvents:UIControlEventTouchUpInside];
            [contentView addSubview:clock];
            
            count++;
        }
    }
    contentView.frame = CGRectMake(0, 0, 300, count*LineHeight);
    
    CMPopTipView *popTipView = [[CMPopTipView alloc] initWithCustomView:contentView];
    cell.popTipView = popTipView;
    popTipView.delegate = self;
    popTipView.disableTapToDismiss = true;
    popTipView.preferredPointDirection = PointDirectionUp;
    popTipView.hasGradientBackground = NO;
    popTipView.cornerRadius = 0.0f;
    popTipView.sidePadding = 10.0f;
    popTipView.topMargin = -3.0f;
    popTipView.pointerSize = 3.0f;
    popTipView.hasShadow = true;
    popTipView.backgroundColor = PopViewColor;
    popTipView.textColor = [UIColor whiteColor];
    popTipView.animation = CMPopTipAnimationPop;
    popTipView.has3DStyle = false;
    popTipView.dismissTapAnywhere = YES;
    popTipView.borderWidth = 0;
    
    [popTipView presentPointingAtView:cell.arrivedBus inView:self.view animated:YES];
    _currentPopTipViewCell = cell;
    _currentPopTipViewIndexPath = indexPath;
    
}

- (void)setClock:(JDOClockButton *)btn{
    // TODO 后台设置上次提醒
    if (btn.stationId) {
        if (btn.isSelected) {
//            [JDOUtils showHUDText:@"已取消上车提醒" inView:self.view];
        }else{
//            [JDOUtils showHUDText:@"已设置上车提醒" inView:self.view];
            [JDOUtils showHUDText:@"到站提醒暂不可用" inView:self.view];
        }
        btn.selected = !btn.isSelected;
    }else{
        [JDOUtils showHUDText:@"请选择上车站点" inView:self.view];
    }
}

- (void)popTipViewWasDismissedByUser:(CMPopTipView *)popTipView{
    _currentPopTipViewCell.popTipView = nil;
    _currentPopTipViewCell = nil;
    _currentPopTipViewIndexPath = nil;
}

@end
