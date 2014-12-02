//
//  JDONearByTableController.m
//  YTBus
//
//  Created by zhang yi on 14-10-21.
//  Copyright (c) 2014年 胶东在线. All rights reserved.
//

#import "JDONearByController.h"
#import "JDORealTimeController.h"
#import "BMapKit.h"
#import "JDOStationModel.h"
#import "JDOBusLineDetail.h"
#import "JDOBusLine.h"
#import "JDONearMapController.h"
#import "JDODatabase.h"
#import "MBProgressHUD.h"
#import "JDOConstants.h"

@interface JDONearByCell : UITableViewCell

@property (nonatomic,strong) JDOBusLine *busLine;

@property (nonatomic,assign) UITableView *tableView;
@property (nonatomic,strong) NSIndexPath *indexPath;

@property (nonatomic,assign) IBOutlet UILabel *lineNameLabel;
@property (nonatomic,assign) IBOutlet UILabel *lineDetailLabel;
@property (nonatomic,assign) IBOutlet UILabel *stationLabel;
@property (nonatomic,assign) IBOutlet UILabel *distanceLabel;
@property (nonatomic,assign) IBOutlet UIButton *switchDirection;

- (IBAction) onSwitchClicked:(UIButton *)btn;

@end

@implementation JDONearByCell

- (IBAction) onSwitchClicked:(UIButton *)btn{
    self.busLine.showingIndex = self.busLine.showingIndex==0?1:0;
    
    [self.tableView reloadRowsAtIndexPaths:@[self.indexPath] withRowAnimation:UITableViewRowAnimationFade];
}

@end

@interface JDONearByController () <BMKLocationServiceDelegate> {
    BMKLocationService *_locService;
    CLLocationCoordinate2D lastSearchCoor;
    CLLocationCoordinate2D currentPosCoor;
    BOOL isFirstPosition;
    NSMutableArray *_nearbyStations;
    FMDatabase *_db;
    NSMutableArray *_linesInfo;
    id distanceObserver;
    id dbObserver;
    int distanceRadius;
    MBProgressHUD *hud;
}

@end

@implementation JDONearByController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItem.enabled = false;
    self.tableView.backgroundColor = [UIColor colorWithHex:@"dfded9"];
    self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 5)];   // 填充边距
//    self.tableView.showsVerticalScrollIndicator = false;
    
    
    if(![CLLocationManager locationServicesEnabled]){
        // TODO 界面上提示
        NSLog(@"请开启定位:设置 > 隐私 > 位置 > 定位服务");
    }else if([CLLocationManager authorizationStatus]==kCLAuthorizationStatusDenied){
        NSLog(@"定位失败，请开启定位:设置 > 隐私 > 位置 > 定位服务 下 XX应用");
    }else{
        _locService = [[BMKLocationService alloc] init];
        isFirstPosition = true;
        _nearbyStations = [[NSMutableArray alloc] init];
        distanceRadius = [[NSUserDefaults standardUserDefaults] integerForKey:@"nearby_distance"];
        if (distanceRadius == 0) {
            distanceRadius = 1000;
        }
        
        _db = [JDODatabase sharedDB];
        if (!_db) {
            dbObserver = [[NSNotificationCenter defaultCenter] addObserverForName:@"db_finished" object:nil queue:nil usingBlock:^(NSNotification *note) {
                _db = [JDODatabase sharedDB];
            }];
        }
        
        distanceObserver = [[NSNotificationCenter defaultCenter] addObserverForName:@"nearby_distance_changed" object:nil queue:nil usingBlock:^(NSNotification *note) {
            isFirstPosition = true;
            distanceRadius = [[NSUserDefaults standardUserDefaults] integerForKey:@"nearby_distance"];
        }];
    }
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"toRealtimeFromNearby"]) {
        JDORealTimeController *rt = segue.destinationViewController;
        JDONearByCell *cell = (JDONearByCell *)sender;
        rt.busLine = cell.busLine;
        self.navigationItem.backBarButtonItem.title = @"附近";
    }else if([segue.identifier isEqualToString:@"toNearMap"]){
        JDONearMapController *nm = segue.destinationViewController;
        nm.myselfCoor = currentPosCoor;
        nm.nearbyStations = _nearbyStations;
        self.navigationItem.backBarButtonItem.title = @"返回";
    }
}

-(void)viewWillAppear:(BOOL)animated {
    if (_locService) {
        _locService.delegate = self;
        [_locService startUserLocationService];
    }
}

-(void)viewWillDisappear:(BOOL)animated {
    if (_locService) {
        [_locService stopUserLocationService];
        _locService.delegate = nil;
    }
}

- (void)willStartLocatingUser{

}
- (void)didStopLocatingUser{

}

- (void)didUpdateUserLocation:(BMKUserLocation *)userLocation
{
    if (hud) {
        [hud hide:true];
        hud = nil;
    }
    if (!_db) {
        return;
    }
    
    currentPosCoor = userLocation.location.coordinate;
    self.navigationItem.rightBarButtonItem.enabled = true;
    
    if (isFirstPosition) {
        lastSearchCoor = currentPosCoor;
        isFirstPosition = false;
    }else{
        CLLocationDistance distance = BMKMetersBetweenMapPoints(BMKMapPointForCoordinate(lastSearchCoor),BMKMapPointForCoordinate(currentPosCoor));
//        NSLog(@"与上一个查询点的距离是:%g",distance);
        if (distance > 100) {
            NSLog(@"位移离上一次定位点超过100米");
            lastSearchCoor = currentPosCoor;
        }else{
            return;
        }
    }
    [_nearbyStations removeAllObjects];
    
    // 先根据经纬度缩小范围，圈定一个以当前坐标为中心的正方形区域
    // 因为地图坐标不能转到GPS坐标，所以地图坐标必须在数据库里有字段保存
    // 另外一个解决方案是，使用CLLocationManager，不使用百度定位
    // 经度1度 = 85.39km    经度1分 = 1.42km   经度1秒 = 23.6m
    // 纬度1度 = 大约111km    纬度1分 = 大约1.85km 纬度1秒 = 大约30.9m
    
    double longitudeDelta = distanceRadius/85390.0;
    double latitudeDelta = distanceRadius/111000.0;
    // stationname like '%广播电视台%' or stationname like '%汽车东站%' or stationname like '%体育公园%'
    NSString *sql = @"select * from STATION where gpsx2>? and gpsx2<? and gpsy2>? and gpsy2<? and stationname not like 't_%'";
    NSArray *argu = @[@(currentPosCoor.longitude-longitudeDelta),@(currentPosCoor.longitude+longitudeDelta),@(currentPosCoor.latitude-latitudeDelta),@(currentPosCoor.latitude+latitudeDelta)];
    FMResultSet *s = [_db executeQuery:sql withArgumentsInArray:argu];
    while ([s next]) {
        JDOStationModel *station = [JDOStationModel new];
        station.fid = [NSString stringWithFormat:@"%d",[s intForColumn:@"ID"]];
        station.name = [s stringForColumn:@"STATIONNAME"];
        station.direction = [s stringForColumn:@"GEOGRAPHICALDIRECTION"];
        station.gpsX = [NSNumber numberWithDouble:[s doubleForColumn:@"GPSX2"]];
        station.gpsY = [NSNumber numberWithDouble:[s doubleForColumn:@"GPSY2"]];
//        NSLog(@"%@ gps2原始 x=%@,y=%@",station.name,station.gpsX,station.gpsY);
        
        // 对比与当前地理位置的距离小于1000的站点
        CLLocationCoordinate2D bdStation = CLLocationCoordinate2DMake(station.gpsY.doubleValue, station.gpsX.doubleValue);
        // gps坐标转百度坐标
//        CLLocationCoordinate2D bdStation = BMKCoorDictionaryDecode(BMKConvertBaiduCoorFrom(CLLocationCoordinate2DMake(station.gpsY.doubleValue, station.gpsX.doubleValue),BMK_COORDTYPE_GPS));
        // 转化为直角坐标测距
        CLLocationDistance distance = BMKMetersBetweenMapPoints(BMKMapPointForCoordinate(currentPosCoor),BMKMapPointForCoordinate(bdStation));
//        NSLog(@"distance:%g",distance);
        
        if (distance < distanceRadius) {  // 附近站点
            station.distance = @(distance);
            [_nearbyStations addObject:station];
        }else{
//            NSLog(@"%@:距离超过1000米",station.name);
        }
    }
    
    // 按距离由近及远排序
    [_nearbyStations sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        JDOStationModel *station1 = (JDOStationModel *)obj1;
        JDOStationModel *station2 = (JDOStationModel *)obj2;
        if (station1.distance.doubleValue < station2.distance.doubleValue) {
            return NSOrderedAscending;
        }
        return NSOrderedDescending;
    }];
    
    // 将同一线路的上下行两个方向分别离当前最近的站点合并成一个数组，距离近的在前，保存在busLine的nearbyStation中
    _linesInfo = [[NSMutableArray alloc] init];
    for (int i=0; i<_nearbyStations.count; i++) {
        JDOStationModel *station = _nearbyStations[i];
        FMResultSet *rs = [_db executeQuery:GetLinesByStation,station.fid];
        while ([rs next]) {
            NSString *lineId = [rs stringForColumn:@"LINEID"];
            
            JDOBusLine *busLine;
            for (int i=0; i<_linesInfo.count; i++) {
                JDOBusLine *aLine = _linesInfo[i];
                if ([aLine.lineId isEqualToString:lineId]) {
                    busLine = aLine;
                    break;
                }
            }

            if(!busLine) {
                busLine = [JDOBusLine new];
                busLine.lineId = lineId;
                busLine.lineName = [rs stringForColumn:@"LINENAME"];
                busLine.runTime = [rs stringForColumn:@"RUNTIME"];
                
                busLine.lineDetailPair = [[NSMutableArray alloc] initWithCapacity:2];
                JDOBusLineDetail *lineDetail = [JDOBusLineDetail new];
                lineDetail.detailId = [rs stringForColumn:@"LINEDETAILID"];
                lineDetail.lineDetail = [rs stringForColumn:@"LINEDETAIL"];
                lineDetail.direction = [rs stringForColumn:@"LINEDIRECTION"];
                [busLine.lineDetailPair addObject:lineDetail];
                
                busLine.nearbyStationPair = [[NSMutableArray alloc] initWithCapacity:2];
                [busLine.nearbyStationPair addObject:station];
                
                [_linesInfo addObject:busLine];
            }else{
                if (busLine.lineDetailPair.count == 2) {
                    continue;
                }
                // stationPair中的第二个必须保证跟前一个是对向站点。并且上下行的两个站点不一定同名，也就是说，离当前位置最近的两侧站点可能分别是前后两站
                JDOBusLineDetail *preLineDetail = busLine.lineDetailPair[0];
                NSString *detailId = [rs stringForColumn:@"LINEDETAILID"];
                if ([preLineDetail.detailId isEqualToString:detailId]) {
                    continue;
                }
                
                JDOBusLineDetail *lineDetail = [JDOBusLineDetail new];
                lineDetail.detailId = [rs stringForColumn:@"LINEDETAILID"];
                lineDetail.lineDetail = [rs stringForColumn:@"LINEDETAIL"];
                lineDetail.direction = [rs stringForColumn:@"LINEDIRECTION"];
                [busLine.lineDetailPair addObject:lineDetail];
                
                [busLine.nearbyStationPair addObject:station];
            }
        }
    }
    
    [self.tableView reloadData];
}

- (void)didFailToLocateUserWithError:(NSError *)error {
    if (error.code == kCLErrorLocationUnknown) {
        if (!hud && _linesInfo.count==0 ) {
            hud = [MBProgressHUD showHUDAddedTo:self.view animated:true];
            hud.minShowTime = 1.0f;
            hud.labelText = @"定位中,请稍后...";
        }
    }else{
        NSLog(@"location error:%@",error);
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _linesInfo.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    JDONearByCell *cell = [tableView dequeueReusableCellWithIdentifier:@"busLine" forIndexPath:indexPath];
    if(!cell.backgroundView){
        cell.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"公交车列表"]];
        cell.backgroundColor = [UIColor clearColor];
        cell.contentView.backgroundColor = [UIColor clearColor];
    }
    
    JDOBusLine *busLine = _linesInfo[indexPath.row];
    cell.indexPath = indexPath;
    cell.tableView = self.tableView;
    cell.busLine = busLine;
    
    [cell.lineNameLabel setText:busLine.lineName];
    
    JDOBusLineDetail *lineDetail = busLine.lineDetailPair[busLine.showingIndex];
    [cell.lineDetailLabel setText:lineDetail.lineDetail];
    
    JDOStationModel *station = busLine.nearbyStationPair[busLine.showingIndex];
    [cell.stationLabel setText:[NSString stringWithFormat:@"%@ [%@]",station.name,station.direction]];
    [cell.distanceLabel setText:[NSString stringWithFormat:@"%d米",[station.distance intValue]]];
    
    cell.switchDirection.hidden = (busLine.lineDetailPair.count==1);
    
    return cell;
}

//- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
//    UIView *bg = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 50)];
//    bg.backgroundColor = [UIColor lightGrayColor];
//    
//    JDOStationModel *model = (JDOStationModel *)_nearbyStations[section];
//    UILabel *stationName  = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, 240, 30)];
//    stationName.text = model.name;
//    [bg addSubview:stationName];
//    
//    UILabel *distance = [[UILabel alloc] initWithFrame:CGRectMake(260, 10, 50, 30)];
//    distance.text = [NSString stringWithFormat:@"%d米",[model.distance intValue]];
//    [bg addSubview:distance];
//    
//    return bg;
//}

//- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
//    return 50;
//}

-(void)dealloc{
    if (distanceObserver) {
        [[NSNotificationCenter defaultCenter] removeObserver:distanceObserver];
    }
    if (dbObserver) {
        [[NSNotificationCenter defaultCenter] removeObserver:dbObserver];
    }
}


@end
