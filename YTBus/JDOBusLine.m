//
//  JDOBusLine.m
//  YTBus
//
//  Created by zhang yi on 14-10-30.
//  Copyright (c) 2014年 胶东在线. All rights reserved.
//

#import "JDOBusLine.h"

@implementation JDOBusLine

// 防止在实时界面换向后影响showingIndex导致附近界面方向反了
-(id)copyWithZone:(NSZone *)zone{
    JDOBusLine *clone = [[JDOBusLine allocWithZone:zone] init];
    clone.lineId = self.lineId;
    clone.lineName = self.lineName;
    clone.runTime = self.runTime;
    clone.stationA = self.stationA;
    clone.stationB = self.stationB;
    clone.lineDetailPair = [self.lineDetailPair mutableCopy];
    clone.nearbyStationPair = [self.nearbyStationPair mutableCopy];
    clone.showingIndex = self.showingIndex;
    return clone;
}

@end
