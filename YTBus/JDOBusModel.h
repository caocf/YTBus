//
//  JDOBusModel.h
//  YTBus
//
//  Created by zhang yi on 14-12-4.
//  Copyright (c) 2014年 胶东在线. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JDOBusModel : NSObject

/* {"ID":"735","车牌":"鲁F12826","站":"809","GPSX":"121.442923","GPSY":"37.49883"} */
@property(nonatomic,strong) NSString *busId;
@property(nonatomic,strong) NSString *busNo;
@property(nonatomic,strong) NSString *toStationId;
@property(nonatomic,strong) NSNumber *gpsX;
@property(nonatomic,strong) NSNumber *gpsY;

@end
