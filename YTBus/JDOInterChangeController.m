//
//  JDOInterChangeController.m
//  YTBus
//
//  Created by zhang yi on 14-11-25.
//  Copyright (c) 2014年 胶东在线. All rights reserved.
//

#import "JDOInterChangeController.h"
#import "BMapKit.h"
#import "JDOUtils.h"
#import "JDORouteMapController.h"

@interface JDOInterChangeModel : NSObject

@property (nonatomic,strong) NSMutableString *busChangeInfo;
@property (nonatomic,assign) int busStationNumber;
@property (nonatomic,strong) NSString *distance;
@property (nonatomic,strong) NSString *duration;

@end

@implementation JDOInterChangeModel

@end

@interface JDOInterChangeController () <BMKRouteSearchDelegate,UITableViewDataSource,UITableViewDelegate>

@property (nonatomic,assign) IBOutlet UITableView *tableView;
@property (nonatomic,assign) IBOutlet UIButton *changeBtn;
@property (nonatomic,assign) IBOutlet UIButton *searchBtn;
@property (nonatomic,assign) IBOutlet UITextField *startField;
@property (nonatomic,assign) IBOutlet UITextField *endField;
@property (nonatomic,assign) IBOutlet UISegmentedControl *changeTypeSeg;

- (IBAction)directionChanged:(UIButton *)sender;
- (IBAction)doSearch:(UIButton *)sender;
- (IBAction)typeChanged:(UISegmentedControl *)sender;
@end

@implementation JDOInterChangeController{
    BMKRouteSearch *_routesearch;
    NSMutableArray *_list;
    NSMutableArray *_plans;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _routesearch = [[BMKRouteSearch alloc] init];
    _routesearch.delegate = self;
    
    _list = [NSMutableArray new];
    _plans= [NSMutableArray new];
    
    _startField.text = @"广电大厦";
    _endField.text = @"万达广场";
}

- (IBAction)directionChanged:(UIButton *)sender {
    NSString *tmp = _startField.text;
    _startField.text = _endField.text;
    _endField.text = tmp;
}

- (IBAction)doSearch:(UIButton *)sender {
    BMKPlanNode *start = [BMKPlanNode new];
    start.name = _startField.text;
    BMKPlanNode *end = [BMKPlanNode new];
    end.name = _endField.text;
    
    BMKTransitRoutePlanOption *transitRouteSearchOption = [BMKTransitRoutePlanOption new];
    transitRouteSearchOption.city = @"烟台市";
    transitRouteSearchOption.transitPolicy = BMK_TRANSIT_TIME_FIRST;
    transitRouteSearchOption.from = start;
    transitRouteSearchOption.to = end;
    
    BOOL flag = [_routesearch transitSearch:transitRouteSearchOption];
    
    if(!flag){
        [JDOUtils showHUDText:@"检索请求失败" inView:self.view];
    }
}

- (IBAction)typeChanged:(UISegmentedControl *)sender {
    
}

- (void)onGetTransitRouteResult:(BMKRouteSearch *)searcher result:(BMKTransitRouteResult *)result errorCode:(BMKSearchErrorCode)error{
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
        model.distance = [NSString stringWithFormat:@"%d米",plan.distance];
        model.duration = [NSString stringWithFormat:@"%d小时%d分",plan.duration.hours,plan.duration.minutes];
        for (int j=0; j<plan.steps.count; j++) {
            BMKTransitStep *aStep = plan.steps[j];
            if (aStep.stepType == BMK_BUSLINE) {
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
    }
    [self.tableView reloadData];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [self performSegueWithIdentifier:@"toRouteMap" sender:indexPath];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"toRouteMap"]) {
        JDORouteMapController *controller = segue.destinationViewController;
        int index = [(NSIndexPath *)sender row];
        controller.route = _plans[index];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _list.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"cellIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if( cell == nil){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        UILabel *lineLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, 300, 20)];
        lineLabel.font = [UIFont systemFontOfSize:14];
        lineLabel.minimumFontSize = 12;
        lineLabel.adjustsFontSizeToFitWidth = true;
        lineLabel.textColor = [UIColor colorWithRed:110/255.0f green:110/255.0f blue:110/255.0f alpha:1];
        lineLabel.tag = 3001;
        [cell addSubview:lineLabel];
        
        UILabel *stationNumLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 20, 300, 20)];
        stationNumLabel.font = [UIFont systemFontOfSize:14];
        stationNumLabel.minimumFontSize = 12;
        stationNumLabel.adjustsFontSizeToFitWidth = true;
        stationNumLabel.textColor = [UIColor colorWithRed:110/255.0f green:110/255.0f blue:110/255.0f alpha:1];
        stationNumLabel.tag = 3002;
        [cell addSubview:stationNumLabel];
        
//        UIImageView *nearIcon = [[UIImageView alloc] initWithFrame:CGRectMake(0, 1, 15, 39)];
//        nearIcon.image = [UIImage imageNamed:@"近"];
//        nearIcon.tag = 3002;
//        [cell addSubview:nearIcon];
    }
    if (indexPath.row%2 == 0) {
        cell.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"弹出列表02"]];
    }else{
        cell.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"弹出列表03"]];
    }
    
    UILabel *lineLabel = (UILabel *)[cell viewWithTag:3001];
    UILabel *stationNumLabel = (UILabel *)[cell viewWithTag:3002];
    
    JDOInterChangeModel *model = _list[indexPath.row];
    lineLabel.text = model.busChangeInfo;
    stationNumLabel.text = [NSString stringWithFormat:@"共%d站,距离%@,耗时%@",model.busStationNumber,model.distance,model.duration];
    
    return cell;
}

@end
