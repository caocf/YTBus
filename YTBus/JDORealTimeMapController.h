//
//  JDORealTimeMapController.h
//  YTBus
//
//  Created by zhang yi on 14-11-10.
//  Copyright (c) 2014年 胶东在线. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BMapKit.h"

@interface JDORealTimeMapController : UIViewController

@property (nonatomic,strong) NSArray *stations;
@property (nonatomic,strong) NSMutableArray *realBusList;
// 以下3个是请求实时数据参数
@property (nonatomic,strong) NSString *stationId;
@property (nonatomic,strong) NSString *lineId;
@property (nonatomic,strong) NSString *lineStatus;

@property (nonatomic,weak) IBOutlet BMKMapView *mapView;

@end
