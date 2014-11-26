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

#define Green_Color [UIColor colorWithRed:55/255.0f green:170/255.0f blue:50/255.0f alpha:1.0f]
#define Red_Color [UIColor colorWithRed:240/255.0f green:50/255.0f blue:50/255.0f alpha:1.0f]

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
@property (nonatomic,weak) IBOutlet UILabel *typeLabel;
@property (nonatomic,weak) IBOutlet UILabel *busLabel;
@property (nonatomic,weak) IBOutlet UILabel *descLabel;

@end

@implementation JDOInterChangeCell

@end

@interface JDOInterChangeController () <BMKRouteSearchDelegate,UITableViewDataSource,UITableViewDelegate>

@property (nonatomic,weak) IBOutlet UITableView *tableView;
@property (nonatomic,weak) IBOutlet UIButton *changeBtn;
@property (nonatomic,weak) IBOutlet UIButton *searchBtn;
@property (nonatomic,weak) IBOutlet UITextField *startField;
@property (nonatomic,weak) IBOutlet UITextField *endField;
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
    BMKRouteSearch *_routesearch;
    BMKTransitPolicy transitPolicy;
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
    transitPolicy = BMK_TRANSIT_TIME_FIRST;
    
    self.tableView.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"矩形下"]];
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
    transitRouteSearchOption.transitPolicy = transitPolicy;
    transitRouteSearchOption.from = start;
    transitRouteSearchOption.to = end;
    
    BOOL flag = [_routesearch transitSearch:transitRouteSearchOption];
    
    if(!flag){
        [JDOUtils showHUDText:@"检索请求失败" inView:self.view];
    }
}

- (IBAction)typeChanged:(UIButton *)sender {
    [_changeType0 setImage:(sender==_changeType0?[UIImage imageNamed:@"圆点"]:[UIImage imageNamed:@"圆点灰"]) forState:UIControlStateNormal];
    [_changeType1 setImage:(sender==_changeType1?[UIImage imageNamed:@"圆点"]:[UIImage imageNamed:@"圆点灰"]) forState:UIControlStateNormal];
    [_changeType2 setImage:(sender==_changeType2?[UIImage imageNamed:@"圆点"]:[UIImage imageNamed:@"圆点灰"]) forState:UIControlStateNormal];
    transitPolicy = sender==_changeType0?BMK_TRANSIT_TIME_FIRST:(sender==_changeType1?BMK_TRANSIT_TRANSFER_FIRST:BMK_TRANSIT_WALK_FIRST);
}

- (IBAction)setLocation:(UIButton *)sender{
    
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
    
    JDOInterChangeCell *cell = [tableView dequeueReusableCellWithIdentifier:@"routeIdentifier"];
    
    JDOInterChangeModel *model = _list[indexPath.row];
    cell.seqBg.image = [UIImage imageNamed:model.type==0?@"标签1":@"标签2"];
    cell.seqLabel.text = [NSString stringWithFormat:@"%2d",indexPath.row+1];
    cell.typeLabel.text = model.type==0?@"直达":@"换乘";
    cell.typeLabel.textColor = model.type==0?Green_Color:Red_Color;
    cell.busLabel.text = model.busChangeInfo;
    cell.descLabel.text = [NSString stringWithFormat:@"共%d站,距离%@,耗时%@",model.busStationNumber,model.distance,model.duration];
    
    return cell;
}

@end
