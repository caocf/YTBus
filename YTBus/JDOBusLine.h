//
//  JDOBusLine.h
//  YTBus
//
//  Created by zhang yi on 14-10-30.
//  Copyright (c) 2014年 胶东在线. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JDOStationModel.h"
#import "JDOBusLineDetail.h"

@interface JDOBusLine : NSObject

@property(nonatomic,strong) NSString *lineId;
@property(nonatomic,strong) NSString *lineName;
@property(nonatomic,strong) NSMutableArray *lineDetailPair;
@property(nonatomic,strong) NSMutableArray *nearbyStationPair;
@property(nonatomic,assign) int showingIndex;

@end
