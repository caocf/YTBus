//
//  JDOStationMapController.m
//  YTBus
//
//  Created by zhang yi on 14-11-18.
//  Copyright (c) 2014年 胶东在线. All rights reserved.
//

#import "JDOStationMapController.h"
#import "BMapKit.h"

@interface JDOStationMapController () <BMKMapViewDelegate,UITableViewDataSource,UITableViewDelegate>

@property (nonatomic,assign) IBOutlet BMKMapView *mapView;
@property (nonatomic,assign) IBOutlet UITableView *tableView;

@end

@implementation JDOStationMapController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
