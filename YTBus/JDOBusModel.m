//
//  JDOBusModel.m
//  YTBus
//
//  Created by zhang yi on 14-12-4.
//  Copyright (c) 2014年 胶东在线. All rights reserved.
//

#import "JDOBusModel.h"

@implementation JDOBusModel

- (id)initWithDictionary:(NSDictionary *)dictionary{
    self = [self init];
    if (self == nil) return nil;
    
    _busId = [dictionary objectForKey:@"ID"];
    _busNo = [dictionary objectForKey:@"车牌"];
    _toStationId = [dictionary objectForKey:@"站"];
    _gpsX = [NSNumber numberWithDouble:[(NSString *)[dictionary objectForKey:@"GPSX"] doubleValue]];
    _gpsY = [NSNumber numberWithDouble:[(NSString *)[dictionary objectForKey:@"GPSY"] doubleValue]];
    _state = [NSNumber numberWithInt:[(NSString *)[dictionary objectForKey:@"站内外"] intValue]];
    
    return self;
}

@end
