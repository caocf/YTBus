//
//  JDORouteMapController.m
//  YTBus
//
//  Created by zhang yi on 14-11-25.
//  Copyright (c) 2014年 胶东在线. All rights reserved.
//

#import "JDORouteMapController.h"
#import "JDOConstants.h"

@interface JDORouteMapController () <BMKMapViewDelegate,UITableViewDelegate,UITableViewDataSource>

@property (nonatomic,weak) IBOutlet BMKMapView *mapView;
@property (nonatomic,weak) IBOutlet UITableView *tableView;

@end

@implementation JDORouteMapController

- (void)viewDidLoad {
    [super viewDidLoad];
}


-(void)viewWillAppear:(BOOL)animated {
    [MobClick beginLogPageView:@"transfermap"];
    [MobClick event:@"transfermap"];
    [MobClick beginEvent:@"transfermap"];
    
    _mapView.delegate = self;
    [_mapView viewWillAppear];
}

-(void)viewWillDisappear:(BOOL)animated {
    [MobClick endLogPageView:@"transfermap"];
    [MobClick endEvent:@"transfermap"];
    
    [_mapView viewWillDisappear];
    _mapView.delegate = nil;
}

@end
