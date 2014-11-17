//
//  JDOStationController.m
//  YTBus
//
//  Created by zhang yi on 14-11-14.
//  Copyright (c) 2014年 胶东在线. All rights reserved.
//

#import "JDOStationController.h"
#import "JDOUtils.h"
#import "JDODatabase.h"
#import "JDOStationModel.h"
#import "JDORealTimeController.h"

@interface JDOStationController () <UISearchBarDelegate> {
    NSMutableArray *_allStations;
    NSMutableArray *_filterAllStations;
    NSMutableArray *_historyStations;
    FMDatabase *_db;
    id dbObserver;
    NSIndexPath *selectedIndexPath;
    UIButton *clearHisBtn;
}

@end

@implementation JDOStationController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 增加搜索框
    UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320, 40)];
    searchBar.placeholder = @"搜索站点";
    searchBar.delegate = self;
    self.tableView.tableHeaderView = searchBar;
    
    // 清除历史记录
    clearHisBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [clearHisBtn setFrame:CGRectMake((320-150)/2, 0, 150, 44)];
    [clearHisBtn setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
    [clearHisBtn setContentHorizontalAlignment:UIControlContentHorizontalAlignmentCenter];
    [clearHisBtn setTitle:@"清除搜索历史记录" forState:UIControlStateNormal];
    
    _db = [JDODatabase sharedDB];
    if (_db) {
        [self loadData];
    }
    dbObserver = [[NSNotificationCenter defaultCenter] addObserverForName:@"db_changed" object:nil queue:nil usingBlock:^(NSNotification *note) {
        _db = [JDODatabase sharedDB];
        [self loadData];
    }];
}

- (void)loadData{
    // 加载所有站点
    _allStations = [NSMutableArray new];
    FMResultSet *rs = [_db executeQuery:GetAllStationsWithLine];
    JDOStationModel *preStation;
    while ([rs next]) {
        JDOStationModel *station;
        NSString *stationId = [rs stringForColumn:@"ID"];
        if (preStation && [stationId isEqualToString:preStation.fid]) {
            station = preStation;
        }else{
            station = [JDOStationModel new];
            station.fid = stationId;
            station.name = [rs stringForColumn:@"STATIONNAME"];
            station.direction = [rs stringForColumn:@"GEOGRAPHICALDIRECTION"];
            station.passLines = [NSMutableArray new];
            [_allStations addObject:station];
            preStation = station;
        }
//        JDOBusLine *busLine = [JDOBusLine new];
//        busLine.lineName = [rs stringForColumn:@"BUSLINENAME"];
        [station.passLines addObject:[rs stringForColumn:@"BUSLINENAME"]];
    }
    _filterAllStations = [_allStations copy];
    
//    _historyStations = [NSMutableArray new];
//    NSArray *hisStationIds = [[NSUserDefaults standardUserDefaults] arrayForKey:@"history_station"];
//    NSString *ids = [hisStationIds componentsJoinedByString:@","];
//    if(ids){
//        FMResultSet *rs = [_db executeQuery:[GetLineById stringByReplacingOccurrencesOfString:@"?" withString:ids]];
//        while ([rs next]) {
//            JDOBusLine *busLine = [JDOBusLine new];
//            busLine.lineId = [rs stringForColumn:@"ID"];
//            busLine.lineName = [rs stringForColumn:@"BUSLINENAME"];
//            busLine.stationA = [rs stringForColumn:@"STATIONANAME"];
//            busLine.stationB = [rs stringForColumn:@"STATIONBNAME"];
//            [_favorLines addObject:busLine];
//        }
//    }
//    [self sortLines:_favorLines];
//    _filterFavorLines = [_favorLines copy];
//    
//    [self.tableView reloadData];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"toStatinMap"]) {
//        JDORealTimeController *rt = segue.destinationViewController;
//        if (selectedIndexPath.section == 0 && _filterFavorStations.count>0) {
//            rt.busLine = _filterFavorStations[selectedIndexPath.row];
//        }else{
//            rt.busLine = _filterAllStations[selectedIndexPath.row];
//        }
    }
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    selectedIndexPath = indexPath;
    return indexPath;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _filterAllStations.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"busStation";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
    
    JDOStationModel *station = (JDOStationModel *)_filterAllStations[indexPath.row];
    [(UILabel *)[cell viewWithTag:1001] setText:station.name];
    NSString *desc;
    if (station.passLines.count <= 3) {
        desc = [NSString stringWithFormat:@"%@经过",[station.passLines componentsJoinedByString:@"、"]];
    }else{
        desc = [NSString stringWithFormat:@"%@等%d条线路经过",station.passLines[0],station.passLines.count];
    }
    [(UILabel *)[cell viewWithTag:1002] setText:desc];

    return cell;
}


- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText{
    _filterAllStations = [_allStations mutableCopy];
    if ([searchBar.text isEqualToString:@""]) {
        [self.tableView reloadData];
        return;
    }
    
    NSMutableIndexSet *deleteAllIndex = [NSMutableIndexSet indexSet];
    for(int i=0; i<_filterAllStations.count; i++){
        JDOStationModel *station = _filterAllStations[i];
        if(![station.name containsString:searchBar.text]){
            [deleteAllIndex addIndex:i];
        }
    }
    [_filterAllStations removeObjectsAtIndexes:deleteAllIndex];
    
    [self.tableView reloadData];
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {
    searchBar.showsCancelButton = YES;
    return YES;
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    searchBar.showsCancelButton = NO;
    [searchBar resignFirstResponder];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    searchBar.showsCancelButton = NO;
    [searchBar resignFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    searchBar.text = @"";
    searchBar.showsCancelButton = NO;
    [self searchBar:searchBar textDidChange:nil];
    [searchBar resignFirstResponder];
}

-(void)dealloc{
    if (dbObserver) {
        [[NSNotificationCenter defaultCenter] removeObserver:dbObserver];
    }
}

@end
