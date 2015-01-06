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
    [self.tableView reloadRowsAtIndexPaths:@[self.indexPath] withRowAnimation:UITableViewRowAnimationRight];
}

- (void) startAnimationWithDelay:(CGFloat) delayTime{
    self.transform = CGAffineTransformMakeTranslation(320, 0);
    [UIView animateWithDuration:1 delay:delayTime usingSpringWithDamping:0.6f initialSpringVelocity:0 options:0 animations:^{
        self.transform = CGAffineTransformIdentity;
    } completion:nil];
}

@end

@interface JDONearByController () <BMKLocationServiceDelegate,CLLocationManagerDelegate> {
    BMKLocationService *_locService;
    BMKUserLocation *currentUserLocation;
    NSMutableArray *_nearbyStations;
    FMDatabase *_db;
    NSMutableArray *_linesInfo;
    id distanceObserver;
    id dbObserver;
    int distanceRadius;
    MBProgressHUD *hud;
    NSMutableSet *animationIndexPath;
    UILabel *hintLabel;
    UIImageView *hintImage;
    UILabel *noDataLabel;
    UIImageView *noDataImage;
    CLLocationManager *locationManger;
}

@end

@implementation JDONearByController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItem.enabled = false;
    self.tableView.backgroundColor = [UIColor colorWithHex:@"dfded9"];
    self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 5)];   // 填充边距
//    self.tableView.showsVerticalScrollIndicator = false;
    hintLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 10, 280, 80)];
    hintLabel.backgroundColor = [UIColor clearColor];
    hintLabel.font = [UIFont systemFontOfSize:15];
    hintLabel.numberOfLines = 4;
    hintImage = [[UIImageView alloc] initWithFrame:CGRectMake(61, 140, 197, 180)];
    noDataLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 10, 280, 100)];
    noDataLabel.backgroundColor = [UIColor clearColor];
    noDataLabel.font = [UIFont systemFontOfSize:15];
    noDataLabel.textColor = [UIColor colorWithHex:@"5f5e59"];
    noDataLabel.text = @"很抱歉，“烟台公交”仅覆盖烟台市辖区范围内的公交数据，您的位置附近没有找到公交线路和站点信息。若您在烟台市区范围内，请尝试在“更多->系统设置->附近半径”中增加查询范围。";
    noDataLabel.numberOfLines = 5;
    noDataLabel.hidden = true;
    [self.tableView addSubview:noDataLabel];
    noDataImage = [[UIImageView alloc] initWithFrame:CGRectMake(61, 140, 197, 180)];
    noDataImage.image = [UIImage imageNamed:@"超出范围"];
    noDataImage.hidden = true;
    [self.tableView addSubview:noDataImage];
    
    // 另外启用一个定位服务，因为百度定位无法获取授权状态变化的回调
    locationManger = [[CLLocationManager alloc]init];
    locationManger.delegate = self;
    if (After_iOS8) {
        [locationManger requestWhenInUseAuthorization];
    }
//    [locationManger startUpdatingLocation];
    
    _locService = [[BMKLocationService alloc] init];
    _nearbyStations = [[NSMutableArray alloc] init];
    animationIndexPath = [NSMutableSet set];
    distanceRadius = [[NSUserDefaults standardUserDefaults] integerForKey:@"nearby_distance"];
    if (distanceRadius == 0) {
        distanceRadius = 1000;
    }
    
    _db = [JDODatabase sharedDB];
    if (!_db) {
        dbObserver = [[NSNotificationCenter defaultCenter] addObserverForName:@"db_finished" object:nil queue:nil usingBlock:^(NSNotification *note) {
            _db = [JDODatabase sharedDB];
            [self refreshData];
        }];
    }
    distanceObserver = [[NSNotificationCenter defaultCenter] addObserverForName:@"nearby_distance_changed" object:nil queue:nil usingBlock:^(NSNotification *note) {
        distanceRadius = [[NSUserDefaults standardUserDefaults] integerForKey:@"nearby_distance"];
        [self refreshData];
    }];
    
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if(![CLLocationManager locationServicesEnabled]){
        [_linesInfo removeAllObjects];
        [self.tableView reloadData];
        self.navigationItem.rightBarButtonItem.enabled = false;
        
        hintLabel.text = @"您当前已关闭定位服务，请按以下顺序操作以开启定位服务：设置->隐私->定位服务->开启。";
        hintLabel.textColor = [UIColor colorWithHex:@"5f5e59"];
        hintImage.image = [UIImage imageNamed:@"关闭定位"];
        [self.tableView addSubview:hintLabel];
        [self.tableView addSubview:hintImage];
    }else if([CLLocationManager authorizationStatus]==kCLAuthorizationStatusDenied || [CLLocationManager authorizationStatus]==kCLAuthorizationStatusNotDetermined){
        [_linesInfo removeAllObjects];
        [self.tableView reloadData];
        self.navigationItem.rightBarButtonItem.enabled = false;
        
        hintLabel.text = @"您尚未允许“烟台公交”使用定位服务，请按以下顺序操作以开启定位:设置->隐私->定位服务->烟台公交->选择“使用应用程序期间”。";
        hintLabel.textColor = [UIColor colorWithHex:@"8f8e89"];
        hintImage.image = [UIImage imageNamed:@"不允许使用定位"];
        [self.tableView addSubview:hintLabel];
        [self.tableView addSubview:hintImage];
    }else{
        self.navigationItem.rightBarButtonItem.enabled = true;
        
        [hintLabel removeFromSuperview];
        [hintImage removeFromSuperview];
        [self refreshData];
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
        nm.myselfLocation = currentUserLocation;
        nm.nearbyStations = _nearbyStations;
        self.navigationItem.backBarButtonItem.title = @"返回";
    }
}

-(void)viewWillAppear:(BOOL)animated {
    [MobClick beginLogPageView:@"nearby"];
    [MobClick event:@"nearby"];
    [MobClick beginEvent:@"nearby"];
    _locService.delegate = self;
    [_locService startUserLocationService];
}

-(void)viewWillDisappear:(BOOL)animated {
    [MobClick endLogPageView:@"nearby"];
    [MobClick endEvent:@"nearby"];
    [_locService stopUserLocationService];
    _locService.delegate = nil;
}

- (void)didFailToLocateUserWithError:(NSError *)error {
    NSLog(@"location error:%@",error);
    if (error.code == kCLErrorLocationUnknown) {
        if (!hud && _linesInfo.count==0 ) {
            hud = [MBProgressHUD showHUDAddedTo:self.view animated:true];
            hud.minShowTime = 1.0f;
            hud.labelText = @"定位中,请稍候...";
        }
    }else if (error.code == kCLErrorDenied){    // 启动的时候不允许，或运行过程中从系统设置里关闭
        NSLog(@"didFailToLocateUserWithError：kCLErrorDenied");
    }
}

- (void)didUpdateBMKUserLocation:(BMKUserLocation *)userLocation
{
    if (hud) {
        [hud hide:true];
        hud = nil;
    }
    
    if (currentUserLocation) {
        // 每次startUserLocationService都会触发一次忽略位移的定位，若两次viewWillAppear调用之间若距离变化不足则不刷新
        double moveDistance = [userLocation.location distanceFromLocation:currentUserLocation.location];
        // currentUserLocation为nil时返回-1
        if (moveDistance != -1 && moveDistance < Location_Auto_Refresh_Distance/2) {
//            NSLog(@"移动距离%g，不足刷新条件",moveDistance);
            return;
        }
    }
    
    currentUserLocation = userLocation;
    
    [self refreshData];
}

- (void) refreshData{
    if (!_db) {
        return;
    }
    if (!currentUserLocation) {
        return;
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
    CLLocationCoordinate2D currentCoor = currentUserLocation.location.coordinate;
    NSArray *argu = @[@(currentCoor.longitude-longitudeDelta),@(currentCoor.longitude+longitudeDelta),@(currentCoor.latitude-latitudeDelta),@(currentCoor.latitude+latitudeDelta)];
    FMResultSet *s = [_db executeQuery:sql withArgumentsInArray:argu];
    while ([s next]) {
        JDOStationModel *station = [JDOStationModel new];
        station.fid = [NSString stringWithFormat:@"%d",[s intForColumn:@"ID"]];
        station.name = [s stringForColumn:@"STATIONNAME"];
        station.direction = [s stringForColumn:@"GEOGRAPHICALDIRECTION"];
        station.gpsX = [NSNumber numberWithDouble:[s doubleForColumn:@"GPSX2"]];
        station.gpsY = [NSNumber numberWithDouble:[s doubleForColumn:@"GPSY2"]];
        
        // 对比与当前地理位置的距离小于1000的站点
        CLLocationCoordinate2D bdStation = CLLocationCoordinate2DMake(station.gpsY.doubleValue, station.gpsX.doubleValue);
        // gps坐标转百度坐标
        //        CLLocationCoordinate2D bdStation = BMKCoorDictionaryDecode(BMKConvertBaiduCoorFrom(CLLocationCoordinate2DMake(station.gpsY.doubleValue, station.gpsX.doubleValue),BMK_COORDTYPE_GPS));
        // 转化为直角坐标测距
        CLLocationDistance distance = BMKMetersBetweenMapPoints(BMKMapPointForCoordinate(currentCoor),BMKMapPointForCoordinate(bdStation));
        if (distance < distanceRadius) {  // 附近站点
            station.distance = @(distance);
            [_nearbyStations addObject:station];
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
    
    // 测试超出烟台范围无公交站点的情况
    //    [_nearbyStations removeAllObjects];
    
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
    [animationIndexPath removeAllObjects];
    [self.tableView reloadData];
    if (_linesInfo.count>0) {
        noDataLabel.hidden = true;
        noDataImage.hidden = true;
        self.navigationItem.rightBarButtonItem.enabled = true;
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:false];
    }else{
        noDataLabel.hidden = false;
        noDataImage.hidden = false;
        self.navigationItem.rightBarButtonItem.enabled = false;
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

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    if (After_iOS7) {
        JDONearByCell *nearbyCell = (JDONearByCell *)cell;
        if (![animationIndexPath containsObject:indexPath]) {
            [nearbyCell startAnimationWithDelay:(indexPath.row*0.06f)];
            [animationIndexPath addObject:indexPath];
        }
    }
}

-(void)dealloc{
    if (distanceObserver) {
        [[NSNotificationCenter defaultCenter] removeObserver:distanceObserver];
    }
    if (dbObserver) {
        [[NSNotificationCenter defaultCenter] removeObserver:dbObserver];
    }
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
}


@end
