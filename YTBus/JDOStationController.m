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
#import "JDOConstants.h"
#import "JDOStationMapController.h"

@interface JDOStationController () <UISearchBarDelegate> {
    NSMutableArray *_allStations;
    NSMutableArray *_filterAllStations;
    NSMutableArray *_historyStations;
    FMDatabase *_db;
    id dbObserver;
    NSIndexPath *selectedIndexPath;
    UISearchBar *_searchBar;
    UIButton *_clearHisBtn;
}

@end

@implementation JDOStationController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 增加搜索框
    _searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320, 40)];
    _searchBar.placeholder = @"搜索站点";
    _searchBar.delegate = self;
    self.tableView.tableHeaderView = _searchBar;
    
    // 清除历史记录
    _clearHisBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_clearHisBtn setFrame:CGRectMake(0, 0, 320, 44)];
    [_clearHisBtn setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
    [_clearHisBtn setContentHorizontalAlignment:UIControlContentHorizontalAlignmentCenter];
    [_clearHisBtn setTitle:@"清除浏览历史记录" forState:UIControlStateNormal];
    [_clearHisBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [_clearHisBtn addTarget:self action:@selector(clearHistory:) forControlEvents:UIControlEventTouchUpInside];
    
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

- (void) clearHistory:(UIButton *)btn{
    [_historyStations removeAllObjects];
    [self.tableView reloadData];
    [[NSUserDefaults standardUserDefaults] setObject:[NSMutableArray new] forKey:@"history_station"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    self.tableView.tableFooterView = nil;
}

- (void)loadData{
    // 加载所有站点
    _allStations = [NSMutableArray new];
    FMResultSet *rs = [_db executeQuery:GetAllStationsWithLine];
    JDOStationModel *preStation;
    while ([rs next]) {
        JDOStationModel *station;
        // 相同名称的站点聚合到一起
        NSString *stationName = [rs stringForColumn:@"STATIONNAME"];
        if (preStation && [stationName isEqualToString:preStation.name]) {
            station = preStation;
        }else{
            station = [JDOStationModel new];
            station.fid = [rs stringForColumn:@"STATIONID"];
            station.name = [rs stringForColumn:@"STATIONNAME"];
//            station.direction = [rs stringForColumn:@"GEOGRAPHICALDIRECTION"];
            station.passLinesName = [NSMutableArray new];
            [_allStations addObject:station];
            preStation = station;
        }
        NSString *lineName = [rs stringForColumn:@"BUSLINENAME"];
        if(![station.passLinesName containsObject:lineName]) {
            [station.passLinesName addObject:lineName];
        }
    }
    
    // 加载历史搜索记录
    _historyStations = [[[NSUserDefaults standardUserDefaults] arrayForKey:@"history_station"] mutableCopy];
    if(!_historyStations) {
        _historyStations = [NSMutableArray new];
    }
    // 没有历史记录则搜索框获得焦点
    if (_historyStations.count == 0) {
//        [_searchBar becomeFirstResponder];
    }else{
        self.tableView.tableFooterView = _clearHisBtn;
        [self.tableView reloadData];
    }
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"toStationMap"]) {
        UITableViewCell *cell = sender;
        NSString *stationName = [(UILabel *)[cell viewWithTag:1001] text];
        
        JDOStationMapController *controller = segue.destinationViewController;
        controller.stationName = stationName;
        
        // 加入历史记录
        _historyStations = [[[NSUserDefaults standardUserDefaults] arrayForKey:@"history_station"] mutableCopy];
        if(!_historyStations){
            _historyStations = [NSMutableArray new];
        }
        if (![_historyStations containsObject:stationName]) {
            [_historyStations addObject:stationName];
            [[NSUserDefaults standardUserDefaults] setObject:_historyStations forKey:@"history_station"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        
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
    if([_searchBar.text isEqualToString:@""]){
        return _historyStations.count;
    }
    return _filterAllStations.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"busStation";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
    
    if([_searchBar.text isEqualToString:@""]){
        NSString *station = _historyStations[indexPath.row];
        [(UILabel *)[cell viewWithTag:1001] setText:station];
        [(UILabel *)[cell viewWithTag:1002] setText:@""];
    }else{
        JDOStationModel *station = (JDOStationModel *)_filterAllStations[indexPath.row];
        [(UILabel *)[cell viewWithTag:1001] setText:station.name];
        NSString *desc;
        if (station.passLinesName.count <= 3) {
            desc = [NSString stringWithFormat:@"%@经过",[station.passLinesName componentsJoinedByString:@"、"]];
        }else{
            desc = [NSString stringWithFormat:@"%@等%d条线路经过",station.passLinesName[0],station.passLinesName.count];
        }
        [(UILabel *)[cell viewWithTag:1002] setText:desc];
    }
    return cell;
}


- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText{
    if ([searchBar.text isEqualToString:@""]) {
        if (_historyStations.count>0) {
            self.tableView.tableFooterView = _clearHisBtn;
        }
        [self.tableView reloadData];
        return;
    }
    
    _filterAllStations = [_allStations mutableCopy];
    NSMutableIndexSet *deleteAllIndex = [NSMutableIndexSet indexSet];
    for(int i=0; i<_filterAllStations.count; i++){
        JDOStationModel *station = _filterAllStations[i];
        if(![station.name containsString:searchBar.text]){
            [deleteAllIndex addIndex:i];
        }
    }
    [_filterAllStations removeObjectsAtIndexes:deleteAllIndex];
    self.tableView.tableFooterView = nil;
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
