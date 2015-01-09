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
#import "JDOConstants.h"

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
    self.tableView.bounces = false;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 10)];
    self.tableView.tableFooterView.backgroundColor = [UIColor colorWithHex:@"dfded9"];
    
    _db = [JDODatabase sharedDB];
    if (_db) {
        [self loadData];
    }else{
        dbObserver = [[NSNotificationCenter defaultCenter] addObserverForName:@"db_finished" object:nil queue:nil usingBlock:^(NSNotification *note) {
            _db = [JDODatabase sharedDB];
            [self loadData];
        }];
    }
    
    favorObserver = [[NSNotificationCenter defaultCenter] addObserverForName:@"favor_line_changed" object:nil queue:nil usingBlock:^(NSNotification *note) {
        [self loadFavorLines];
        [self.tableView reloadData];
    }];
}

-(void)viewWillAppear:(BOOL)animated {
    [MobClick beginLogPageView:@"route"];
    [MobClick event:@"route"];
    [MobClick beginEvent:@"route"];
}

-(void)viewWillDisappear:(BOOL)animated {
    [MobClick endLogPageView:@"route"];
    [MobClick endEvent:@"route"];
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
//        int number1 = [line1.lineName intValue];
//        int number2 = [line2.lineName intValue];
//        if (number1 == 0) {
//            return NSOrderedDescending;
//        }
//        if (number2 == 0) {
//            return NSOrderedAscending;
//        }
//        if (number1 < number2) {
//            return NSOrderedAscending;
//        }
//        return NSOrderedDescending;
        return [line1.lineName compare:line2.lineName options:NSNumericSearch];
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

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 45;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    return 6;    // storyboard中不能定义小数
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 320, 45)];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont boldSystemFontOfSize:16.0];
    label.backgroundColor = [UIColor clearColor];
    if (section == 0 && _filterFavorLines.count>0) {
        iv.image = [UIImage imageNamed:@"收藏线路顶部"];
        label.text = @"收藏线路";
    }else{
        iv.image = [UIImage imageNamed:@"所有线路顶部"];
        label.text = @"所有线路";
    }
    [label sizeToFit];
    CGRect f = label.frame;
    f.origin.x = (320-f.size.width)/2;
    f.origin.y = iv.frame.size.height-f.size.height-10;
    label.frame = f;
    [iv addSubview:label];
    return iv;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 320, 6)];
    iv.image = [UIImage imageNamed:@"线路底部"];
    return iv;
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
    if (indexPath.row%2==0) {
        cell.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"线路单元格背景"]];
    }else{
        cell.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"线路单元格背景灰"]];
    }
    
    JDOBusLine *busLine;
    NSString *barImgName, *p1ImgName, *p2ImgName;
    if (indexPath.section == 0 && _filterFavorLines.count>0) {
        busLine =  (JDOBusLine *)_filterFavorLines[indexPath.row];
        barImgName = @"路牌-收藏";
        p1ImgName = @"始";
        p2ImgName = @"终";
    }else{
        busLine =  (JDOBusLine *)_filterAllLines[indexPath.row];
        barImgName = @"路牌-线路";
        p1ImgName = @"线路圆点";
        p2ImgName = @"线路圆点";
    }
    [(UILabel *)[cell viewWithTag:1001] setText:busLine.lineName];
    [(UILabel *)[cell viewWithTag:1002] setText:(busLine.stationA==nil?@"未知站点":busLine.stationA)];
    [(UILabel *)[cell viewWithTag:1003] setText:(busLine.stationB==nil?@"未知站点":busLine.stationB)];
    [(UIImageView *)[cell viewWithTag:1004] setImage:[UIImage imageNamed:barImgName]];
    [(UIImageView *)[cell viewWithTag:1005] setImage:[UIImage imageNamed:p1ImgName]];
    [(UIImageView *)[cell viewWithTag:1006] setImage:[UIImage imageNamed:p2ImgName]];
    
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
