//
//  JDONearMapController.h
//  YTBus
//
//  Created by zhang yi on 14-10-30.
//  Copyright (c) 2014年 胶东在线. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BMapKit.h"

@interface JDONearMapController : UIViewController

@property (nonatomic,assign) CLLocationCoordinate2D centerCoor;
@property (nonatomic,strong) NSArray *nearbyStations;
@property (nonatomic,strong) NSArray *linesInfo;

@property (nonatomic,weak) IBOutlet BMKMapView *mapView;

@end
