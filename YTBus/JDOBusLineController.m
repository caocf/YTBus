//
//  JDOBusLineController.m
//  YTBus
//
//  Created by zhang yi on 14-11-13.
//  Copyright (c) 2014年 胶东在线. All rights reserved.
//

#import "JDOBusLineController.h"
#import "JDOUtils.h"
#import "JDODatabase.h"
#import "JDOBusLine.h"
#import "JDORealTimeController.h"

@interface JDOBusLineController () <UISearchBarDelegate> {
    NSMutableArray *_favorLines;
    NSMutableArray *_allLines;
    NSMutableArray *_filterFavorLines;
    NSMutableArray *_filterAllLines;
    FMDatabase *_db;
    id dbObserver;
    id favorObserver;
    NSIndexPath *selectedIndexPath;
}

@end

@implementation JDOBusLineController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 增加搜索框
    UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320, 40)];
    searchBar.placeholder = @"搜索线路";
    searchBar.delegate = self;
    self.tableView.tableHeaderView = searchBar;
    
    _db = [JDODatabase sharedDB];
    if (_db) {
        [self loadData];
    }
    dbObserver = [[NSNotificationCenter defaultCenter] addObserverForName:@"db_changed" object:nil queue:nil usingBlock:^(NSNotification *note) {
        _db = [JDODatabase sharedDB];
        [self loadData];
    }];
    favorObserver = [[NSNotificationCenter defaultCenter] addObserverForName:@"favor_line_changed" object:nil queue:nil usingBlock:^(NSNotification *note) {
        [self loadFavorLines];
        [self.tableView reloadData];
    }];
}

- (void)loadData{
    [self loadFavorLines];
    [self loadAllLines];
    
    [self.tableView reloadData];
}

- (void)loadFavorLines{
    _favorLines = [NSMutableArray new];
    // 从NSUserDefault获取收藏线路的id
    NSArray *favorLineIds = [[NSUserDefaults standardUserDefaults] arrayForKey:@"favor_line"];
    NSString *ids = [favorLineIds componentsJoinedByString:@","];
    if(ids){
        FMResultSet *rs = [_db executeQuery:[GetLineById stringByReplacingOccurrencesOfString:@"?" withString:ids]];
        while ([rs next]) {
            JDOBusLine *busLine = [JDOBusLine new];
            busLine.lineId = [rs stringForColumn:@"ID"];
            busLine.lineName = [rs stringForColumn:@"BUSLINENAME"];
            busLine.stationA = [rs stringForColumn:@"STATIONANAME"];
            busLine.stationB = [rs stringForColumn:@"STATIONBNAME"];
            [_favorLines addObject:busLine];
        }
    }
    [self sortLines:_favorLines];
    _filterFavorLines = [_favorLines copy];
}

- (void)loadAllLines{
    _allLines = [NSMutableArray new];
    FMResultSet *rs = [_db executeQuery:GetAllLines];
    while ([rs next]) {
        JDOBusLine *busLine = [JDOBusLine new];
        busLine.lineId = [rs stringForColumn:@"ID"];
        busLine.lineName = [rs stringForColumn:@"BUSLINENAME"];
        busLine.stationA = [rs stringForColumn:@"STATIONANAME"];
        busLine.stationB = [rs stringForColumn:@"STATIONBNAME"];
        [_allLines addObject:busLine];
    }
    [self sortLines:_allLines];
    _filterAllLines = [_allLines copy];
}

- (void) sortLines:(NSMutableArray *) lines{
    // 按线路数字顺序排序，非数字开头的排在最后
    [lines sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        JDOBusLine *line1 = (JDOBusLine *)obj1;
        JDOBusLine *line2 = (JDOBusLine *)obj2;
        int number1 = [line1.lineName intValue];
        int number2 = [line2.lineName intValue];
        if (number1 == 0) {
            return NSOrderedDescending;
        }
        if (number2 == 0) {
            return NSOrderedAscending;
        }
        if (number1 < number2) {
            return NSOrderedAscending;
        }
        return NSOrderedDescending;
    }];
}

#pragma mark - Navigation

// cell点击引起的segue转换发生在willSelectRowAtIndexPath之后，didSelectRowAtIndexPath之前
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"toRealtimeFromLine"]) {
        JDORealTimeController *rt = segue.destinationViewController;
        if (selectedIndexPath.section == 0 && _filterFavorLines.count>0) {
            rt.busLine = _filterFavorLines[selectedIndexPath.row];
        }else{
            rt.busLine = _filterAllLines[selectedIndexPath.row];
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
    int sectionNum = 0;
    if (_filterFavorLines.count>0) {
        sectionNum++;
    }
    if (_filterAllLines.count>0) {
        sectionNum++;
    }
    return sectionNum;
}

//- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
//    
//}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    if (section == 0 && _filterFavorLines.count>0) {
        return @"收藏线路";
    }
    return @"所有线路";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0 && _filterFavorLines.count>0) {
        return _filterFavorLines.count;
    }
    return _filterAllLines.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"busLine";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
    
    JDOBusLine *busLine;
    if (indexPath.section == 0 && _filterFavorLines.count>0) {
        busLine =  (JDOBusLine *)_filterFavorLines[indexPath.row];
    }else{
        busLine =  (JDOBusLine *)_filterAllLines[indexPath.row];
    }
    [(UILabel *)[cell viewWithTag:1001] setText:busLine.lineName];
    [(UILabel *)[cell viewWithTag:1002] setText:busLine.stationA];
    [(UILabel *)[cell viewWithTag:1003] setText:busLine.stationB];
    
    return cell;
}


- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText{
    _filterFavorLines = [_favorLines mutableCopy];
    _filterAllLines = [_allLines mutableCopy];
    if ([searchBar.text isEqualToString:@""]) {
        [self.tableView reloadData];
        return;
    }
    
    // 执行过滤
    NSMutableIndexSet *deleteFavorIndex = [NSMutableIndexSet indexSet];
    for(int i=0; i<_filterFavorLines.count; i++){
        JDOBusLine *line = _filterFavorLines[i];
        if(![line.lineName containsString:searchText]){
            [deleteFavorIndex addIndex:i];
        }
    }
    [_filterFavorLines removeObjectsAtIndexes:deleteFavorIndex];
    
    NSMutableIndexSet *deleteAllIndex = [NSMutableIndexSet indexSet];
    for(int i=0; i<_filterAllLines.count; i++){
        JDOBusLine *line = _filterAllLines[i];
        if(![line.lineName containsString:searchBar.text]){
            [deleteAllIndex addIndex:i];
        }
    }
    [_filterAllLines removeObjectsAtIndexes:deleteAllIndex];
    
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
    if (favorObserver) {
        [[NSNotificationCenter defaultCenter] removeObserver:favorObserver];
    }
}

@end
