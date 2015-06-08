//
//  JDOInterChangeController.m
//  YTBus
//
//  Created by zhang yi on 14-11-25.
//  Copyright (c) 2014年 胶东在线. All rights reserved.
//

#import "JDOInterChangeController.h"
#import "BMapKit.h"
#import "JDOConstants.h"
#import "JDORouteMapController.h"
#import "MBProgressHUD.h"
#import "JDOHttpClient.h"
#import "JSONKit.h"
#import "JDOLocationMapController.h"

#define Suggestion_Rowheight 40.0f
#define Green_Color [UIColor colorWithRed:55/255.0f green:170/255.0f blue:50/255.0f alpha:1.0f]
#define Red_Color [UIColor colorWithRed:240/255.0f green:50/255.0f blue:50/255.0f alpha:1.0f]


@interface JDOPoiSearch : BMKPoiSearch

@property (nonatomic,strong) UITextField *tf;

@end

@implementation JDOPoiSearch

@end

@interface JDOInterChangeModel : NSObject

@property (nonatomic,assign) int type;
@property (nonatomic,strong) NSMutableString *busChangeInfo;
@property (nonatomic,assign) int busStationNumber;
@property (nonatomic,strong) NSString *distance;
@property (nonatomic,strong) NSString *duration;

@end

@implementation JDOInterChangeModel

@end

@interface JDOInterChangeCell : UITableViewCell

@property (nonatomic,weak) IBOutlet UIImageView *seqBg;
@property (nonatomic,weak) IBOutlet UILabel *seqLabel;
@property (nonatomic,weak) IBOutlet UILabel *busLabel;
@property (nonatomic,weak) IBOutlet UILabel *descLabel;

@end

@implementation JDOInterChangeCell

@end

@interface JDOInterChangeController () <BMKRouteSearchDelegate,BMKPoiSearchDelegate,UITableViewDataSource,UITableViewDelegate,UITextFieldDelegate>

@property (nonatomic,weak) IBOutlet UITableView *tableView;
@property (nonatomic,weak) IBOutlet UIButton *changeBtn;
@property (nonatomic,weak) IBOutlet UIButton *searchBtn;
@property (nonatomic,weak) IBOutlet UIButton *startBtn;
@property (nonatomic,weak) IBOutlet UIButton *endBtn;
@property (nonatomic,weak) IBOutlet UIButton *changeType0;
@property (nonatomic,weak) IBOutlet UIButton *changeType1;
@property (nonatomic,weak) IBOutlet UIButton *changeType2;

- (IBAction)directionChanged:(UIButton *)sender;
- (IBAction)doSearch:(UIButton *)sender;
- (IBAction)typeChanged:(UIButton *)sender;
- (IBAction)setLocation:(UIButton *)sender;

@end

@implementation JDOInterChangeController{
    BMKRouteSearch *_routeSearch;
    BMKTransitPolicy transitPolicy;
    NSMutableArray *_list;
    NSMutableArray *_plans;
    MBProgressHUD *hud;
    
    JDOPoiSearch *_locSearch1;
    JDOPoiSearch *_locSearch2;
    UITableView *_dropDown1;
    UITableView *_dropDown2;
    NSMutableArray *_locations1;
    NSMutableArray *_locations2;
    UITextField *_currentTf;
    BOOL isDropDown1Show;
    BOOL isDropDown2Show;
    NSDate *lastSearchTime;
    UIView *_background;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 定义呈现视图的上下文
//    self.definesPresentationContext = true;
    
    _routeSearch = [[BMKRouteSearch alloc] init];
    _routeSearch.delegate = self;
    
    _locSearch1 = [[JDOPoiSearch alloc] init];
    _locSearch1.tf = _startField;
    _locSearch1.delegate = self;
    _locSearch2 = [[JDOPoiSearch alloc] init];
    _locSearch2.tf = _endField;
    _locSearch2.delegate = self;
    
    _list = [NSMutableArray new];
    _plans= [NSMutableArray new];
    _locations1 = [NSMutableArray new];
    _locations2 = [NSMutableArray new];
    
//    _startField.text = @"广电大厦";
//    _endField.text = @"万达广场";
    _startField.delegate = self;
    _endField.delegate = self;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textChanged:) name:UITextFieldTextDidChangeNotification object:_startField];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textChanged:) name:UITextFieldTextDidChangeNotification object:_endField];
    transitPolicy = BMK_TRANSIT_TIME_FIRST;
    
    _dropDown1 = [[UITableView alloc] initWithFrame:CGRectZero];
    _dropDown1.rowHeight = Suggestion_Rowheight;
    _dropDown1.separatorStyle = UITableViewCellSeparatorStyleNone;
    _dropDown1.dataSource = self;
    _dropDown1.delegate = self;
    
    _dropDown2 = [[UITableView alloc] initWithFrame:CGRectZero];
    _dropDown2.rowHeight = Suggestion_Rowheight;
    _dropDown2.separatorStyle = UITableViewCellSeparatorStyleNone;
    _dropDown2.dataSource = self;
    _dropDown2.delegate = self;
    
    _background = [[UIView alloc] initWithFrame:self.view.bounds];
    _background.backgroundColor = [UIColor colorWithWhite:0 alpha:0];
    UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closeDropDownList)];
    [_background addGestureRecognizer:gesture];
    
    self.tableView.backgroundColor = [UIColor colorWithHex:@"dfded9"];

}

-(void)viewWillAppear:(BOOL)animated {
    [MobClick beginLogPageView:@"transfer"];
    [MobClick event:@"transfer"];
    [MobClick beginEvent:@"transfer"];
}

-(void)viewWillDisappear:(BOOL)animated {
    [MobClick endLogPageView:@"transfer"];
    [MobClick endEvent:@"transfer"];
}

- (IBAction)directionChanged:(UIButton *)sender {
    NSString *tmp = _startField.text;
    _startField.text = _endField.text;
    _endField.text = tmp;
}

- (IBAction)doSearch:(UIButton *)sender {
    [self.startField resignFirstResponder];
    [self.endField resignFirstResponder];
    
    if ([JDOUtils isEmptyString:_startField.text]) {
        [JDOUtils showHUDText:@"请输入起点" inView:self.view];
        return;
    }
    if ([JDOUtils isEmptyString:_endField.text]) {
        [JDOUtils showHUDText:@"请输入终点" inView:self.view];
        return;
    }
    
    // 有坐标的优先使用坐标，没有的使用文本
    BMKPlanNode *start = [BMKPlanNode new];
    if (_startPoi && [_startPoi.name isEqualToString:_startField.text]) {
        start.pt = _startPoi.pt;
    }else{
        start.name = _startField.text;
    }
    BMKPlanNode *end = [BMKPlanNode new];
    if (_endPoi && [_endPoi.name isEqualToString:_endField.text]) {
        end.pt = _endPoi.pt;
    }else{
        end.name = _endField.text;
    }
    
    BMKTransitRoutePlanOption *transitRouteSearchOption = [BMKTransitRoutePlanOption new];
    transitRouteSearchOption.city = @"烟台市";
    transitRouteSearchOption.transitPolicy = transitPolicy;
    transitRouteSearchOption.from = start;
    transitRouteSearchOption.to = end;
    
    BOOL flag = [_routeSearch transitSearch:transitRouteSearchOption];
    
    if(!flag){
        [JDOUtils showHUDText:@"检索请求失败" inView:self.view];
    }else{
        hud = [MBProgressHUD showHUDAddedTo:self.view animated:true];
//        hud.minShowTime = 1.0f;
        hud.labelText = @"正在检索";
//        self.searchBtn.enabled = false;
    }
}

- (void)doSuggestionSearch:(UITextField *)tf{
    if (tf == _startField) {
//        [_locations1 removeAllObjects];
        [_locSearch1 poiSearchInCity:[self createPoiOptionArea:@"烟台" keyword:tf.text]];
    }else{
//        [_locations2 removeAllObjects];
        [_locSearch2 poiSearchInCity:[self createPoiOptionArea:@"烟台" keyword:tf.text]];
    }
}

- (BMKCitySearchOption *) createPoiOptionArea:(NSString *)area keyword:(NSString *)keyword{
    BMKCitySearchOption *option = [[BMKCitySearchOption alloc] init];
    option.city = area;
    option.pageIndex = 0;
    option.pageCapacity = 10;
    option.keyword = [@"烟台" stringByAppendingString:keyword];// 区域限制不起作用,加城市前缀
    return option;
}

- (void)onGetPoiResult:(BMKPoiSearch *)searcher result:(BMKPoiResult *)poiResultList errorCode:(BMKSearchErrorCode)error{
    UITextField *tf = ((JDOPoiSearch *)searcher).tf;
    if (![tf isFirstResponder]) {
        return;
    }
    NSMutableArray *locations;
    UITableView *dropDown;
    if (tf == _startField) {
        locations = _locations1;
        dropDown = _dropDown1;
    }else if (tf == _endField){
        locations = _locations2;
        dropDown = _dropDown2;
    }
    if (error == BMK_SEARCH_NO_ERROR) {
        [locations removeAllObjects];
        for (int i=0; i<poiResultList.poiInfoList.count; i++) {
            [locations addObject:poiResultList.poiInfoList[i]];
        }
        // 公交站排在最前面
        [locations sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            BMKPoiInfo *info1 = obj1;
            BMKPoiInfo *info2 = obj2;
            return info1.epoitype>=info2.epoitype?NSOrderedAscending:NSOrderedDescending;
        }];
        [dropDown reloadData];
        if(locations.count > 0){
            [self animateDropDownList:dropDown show:true];
            [dropDown scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionNone animated:false];
        }else{
            [self animateDropDownList:dropDown show:false];
        }
    }else if(error == BMK_SEARCH_RESULT_NOT_FOUND){
        [dropDown reloadData];
        if(locations.count > 0){
            [self animateDropDownList:dropDown show:true];
        }else{
            [self animateDropDownList:dropDown show:false];
        }
    }
}

- (void)textFieldDidBeginEditing:(UITextField *)textField{
    _currentTf = textField;
    if (![JDOUtils isEmptyString:textField.text]) {
        [self doSuggestionSearch:textField];
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField{
    _currentTf = nil;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(doSuggestionSearch:) object:textField];
    if (textField == _startField && isDropDown1Show) {
        [self animateDropDownList:_dropDown1 show:false];
    }else if(textField == _endField && isDropDown2Show){
        [self animateDropDownList:_dropDown2 show:false];
    }
}

- (void)textChanged:(NSNotification *)noti{
    UITextField *textField = (UITextField *)noti.object;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(doSuggestionSearch:) object:textField];
    if ([JDOUtils isEmptyString:textField.text]) {
        if (textField == _startField) {
            [self animateDropDownList:_dropDown1 show:false];
        }else{
            [self animateDropDownList:_dropDown2 show:false];
        }
    }else{
        [self performSelector:@selector(doSuggestionSearch:) withObject:textField afterDelay:1];
    }
}

- (void)animateDropDownList:(UITableView *)dropDown show:(BOOL) show{
    CGPoint point;
    if (dropDown == _dropDown1) {
        point = CGPointMake(25, CGRectGetMaxY(_startField.frame)+1);
        if (show && !isDropDown1Show) {
            [self.view addSubview:_background];
            _dropDown1.frame = CGRectMake(point.x, point.y, 270, 0);
            [self.view addSubview:_dropDown1];
        }
    }else{
        point = CGPointMake(25, CGRectGetMaxY(_endField.frame)+1);
        if (show && !isDropDown2Show) {
            [self.view addSubview:_background];
            _dropDown2.frame = CGRectMake(point.x, point.y, 270, 0);
            [self.view addSubview:_dropDown2];
        }
    }
    
    if (show) {
        int row = [dropDown numberOfRowsInSection:0];
        float height = row>3?dropDown.rowHeight*3:dropDown.rowHeight*row;
        
        [UIView animateWithDuration:0.2 animations:^{
            dropDown.frame = CGRectMake(point.x, point.y, 270, height);
        } completion:^(BOOL finished) {
            if (dropDown == _dropDown1) {
                isDropDown1Show = true;
            }else{
                isDropDown2Show = true;
            }
        }];
    }else{
        [_background removeFromSuperview];
        [UIView animateWithDuration:0.2 animations:^{
            dropDown.frame = CGRectMake(point.x, point.y, 270, 0);
        } completion:^(BOOL finished) {
            [dropDown removeFromSuperview];
            if (dropDown == _dropDown1) {
                isDropDown1Show = false;
            }else{
                isDropDown2Show = false;
            }
        }];
    }
    
}

- (void) closeDropDownList{
    [_startField resignFirstResponder];
    [_endField resignFirstResponder];
    [_dropDown1 removeFromSuperview];
    [_dropDown2 removeFromSuperview];
    [_background removeFromSuperview];
}

- (IBAction)typeChanged:(UIButton *)sender {
    [_changeType0 setImage:(sender==_changeType0?[UIImage imageNamed:@"圆点"]:[UIImage imageNamed:@"圆点灰"]) forState:UIControlStateNormal];
    [_changeType1 setImage:(sender==_changeType1?[UIImage imageNamed:@"圆点"]:[UIImage imageNamed:@"圆点灰"]) forState:UIControlStateNormal];
    [_changeType2 setImage:(sender==_changeType2?[UIImage imageNamed:@"圆点"]:[UIImage imageNamed:@"圆点灰"]) forState:UIControlStateNormal];
    transitPolicy = sender==_changeType0?BMK_TRANSIT_TIME_FIRST:(sender==_changeType1?BMK_TRANSIT_TRANSFER_FIRST:BMK_TRANSIT_WALK_FIRST);
}

- (IBAction)setLocation:(UIButton *)sender{
    [self performSegueWithIdentifier:@"toLocationMap" sender:sender];
}

- (void)onGetTransitRouteResult:(BMKRouteSearch *)searcher result:(BMKTransitRouteResult *)result errorCode:(BMKSearchErrorCode)error{
//    self.searchBtn.enabled = true;
    [hud hide:true];
    
    if (error != BMK_SEARCH_NO_ERROR) {
        NSString *errorInfo;
        switch (error) {
            case BMK_SEARCH_AMBIGUOUS_KEYWORD:  errorInfo = @"检索词有岐义";  break;
            case BMK_SEARCH_AMBIGUOUS_ROURE_ADDR:  errorInfo = @"检索地址有岐义";  break;
            case BMK_SEARCH_RESULT_NOT_FOUND:  errorInfo = @"没有找到检索结果";  break;
            case BMK_SEARCH_ST_EN_TOO_NEAR:  errorInfo = @"起终点太近";  break;
            default:    errorInfo = @"服务器错误";   break;
        }
        [JDOUtils showHUDText:errorInfo inView:self.view];
        return;
    }
    
    [_list removeAllObjects];
    [_plans removeAllObjects];
    for (int i=0; i<result.routes.count; i++) {
        BMKTransitRouteLine *plan = (BMKTransitRouteLine *)result.routes[i];
        [_plans addObject:plan];
        JDOInterChangeModel *model = [JDOInterChangeModel new];
        [_list addObject:model];
        
        if (plan.distance>999) {    //%.Ng代表N位有效数字(包括小数点前面的)，%.Nf代表N位小数位
            model.distance = [NSString stringWithFormat:@"%.1f公里",plan.distance/1000.0f];
        }else{
            model.distance = [NSString stringWithFormat:@"%d米",plan.distance];
        }
        if (plan.duration.hours!=0) {
            model.duration = [NSString stringWithFormat:@"%d小时%d分",plan.duration.hours,plan.duration.minutes];
        }else{
            model.duration = [NSString stringWithFormat:@"%d分钟",plan.duration.minutes];
        }
        
        int busChangeNum=0;
        for (int j=0; j<plan.steps.count; j++) {
            BMKTransitStep *aStep = plan.steps[j];
            if (aStep.stepType == BMK_BUSLINE) {
                busChangeNum++;
                NSString *busName = aStep.vehicleInfo.title;
                int stationNumber = aStep.vehicleInfo.passStationNum;
                if (model.busChangeInfo == nil) {
                    model.busChangeInfo = [NSMutableString stringWithString:busName];
                }else{
                    [model.busChangeInfo appendFormat:@" -> %@",busName];
                }
                model.busStationNumber += stationNumber;
            }
        }
        model.type = busChangeNum>1?1:0;    // 0:直达,1:转乘
    }
    [self.tableView reloadData];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (tableView == _tableView) {
//        [self performSegueWithIdentifier:@"toRouteMap" sender:indexPath];
    }else if(tableView == _dropDown1){
        _startPoi = _locations1[indexPath.row];
        _startField.text = _startPoi.name;
        [_startField resignFirstResponder];
    }else if(tableView == _dropDown2){
        _endPoi = _locations2[indexPath.row];
        _endField.text = _endPoi.name;
        [_endField resignFirstResponder];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"toRouteMap"]) {
        JDORouteMapController *controller = segue.destinationViewController;
//        int index = [(NSIndexPath *)sender row];
        int index = [_tableView indexPathForCell:(JDOInterChangeCell *)sender].row;
        controller.route = _plans[index];
        JDOInterChangeModel *model = _list[index];
        controller.lineTitle = model.busChangeInfo;
    }else if([segue.identifier isEqualToString:@"toLocationMap"]){
        JDOLocationMapController *controller = segue.destinationViewController;
        controller.parentVC = self;
        if (sender == _startBtn) {
            controller.startOrEnd = 0;
            controller.initialPoi = _startPoi;
//            [controller.navigationBar.items[0] setTitle:@"请选择起点"];
        }else{
            controller.startOrEnd = 1;
            controller.initialPoi = _endPoi;
//            [controller.navigationBar.items[0] setTitle:@"请选择终点"];
        }
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == _tableView) {
        return _list.count;
    }else if(tableView == _dropDown1){
        return _locations1.count;
    }else if(tableView == _dropDown2){
        return _locations2.count;
    }
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    if (tableView == _tableView && _list.count>0) {
        return 15;
    }
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    if (tableView == _tableView && _list.count>0) {
        return 15;
    }
    return 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    if (tableView == _tableView) {
        UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 320, 15)];
        iv.image = [UIImage imageNamed:@"表格圆角上"];
        return iv;
    }
    return nil;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    if (tableView == _tableView) {
        UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 320, 15)];
        iv.image = [UIImage imageNamed:@"表格圆角下"];
        return iv;
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == _tableView) {
        JDOInterChangeCell *cell = [tableView dequeueReusableCellWithIdentifier:@"routeIdentifier"];
        cell.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"表格圆角中"]];
        
        JDOInterChangeModel *model = _list[indexPath.row];
//        cell.seqBg.image = [UIImage imageNamed:model.type==0?@"标签1":@"标签2"];
        cell.seqLabel.text = [NSString stringWithFormat:@"%02d",indexPath.row+1];
        cell.busLabel.text = model.busChangeInfo;
        [[cell viewWithTag:1003] setHidden:(indexPath.row == _list.count-1)];
        
        NSString *desc = [NSString stringWithFormat:@"共%d站 / 距离%@ / 耗时%@",model.busStationNumber,model.distance,model.duration];
        if (After_iOS6) {
            NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:desc];
            NSRange range = [desc rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet]];
            while (range.location != NSNotFound) {
                [attrString addAttribute:NSForegroundColorAttributeName value:[UIColor lightGrayColor] range:range];
                [attrString addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:13] range:range];
                int location = range.location+range.length;
                int length = desc.length-location;
                range = [desc rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet] options:0 range:NSMakeRange(location, length)];
            }
            cell.descLabel.attributedText = attrString;
        }else{
            cell.descLabel.text = desc;
        }
        return cell;
    }else{
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"locationCell"];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"locationCell"];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.contentView.backgroundColor = [UIColor clearColor];
            UIImageView *bg = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 270, Suggestion_Rowheight)];
            bg.image = [UIImage imageNamed:@"地址搜索1"];
            [cell.contentView addSubview:bg];
            [cell.textLabel setTextColor:[UIColor colorWithHex:@"37aa32"]];
            [cell.textLabel setFont:[UIFont systemFontOfSize:14.0f]];
            [cell.detailTextLabel setTextColor:[UIColor colorWithHex:@"969696"]];
        }
        BMKPoiInfo *poiInfo ;
        if (tableView == _dropDown1) {
            poiInfo = _locations1[indexPath.row];
        }else{
            poiInfo = _locations2[indexPath.row];
        }
        cell.textLabel.text = poiInfo.name;
        cell.detailTextLabel.text = poiInfo.address;
        
        return cell;
    }
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextFieldTextDidChangeNotification object:_startField];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextFieldTextDidChangeNotification object:_endField];
}

@end
