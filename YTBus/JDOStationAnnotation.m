//
//  JDOStationAnnotation.m
//  YTBus
//
//  Created by zhang yi on 14-11-7.
//  Copyright (c) 2014年 胶东在线. All rights reserved.
//

#import "JDOStationAnnotation.h"

@implementation JDOStationAnnotation

- (NSUInteger)hash
{
    NSString *toHash = [NSString stringWithFormat:@"%.5F%.5F", self.coordinate.latitude, self.coordinate.longitude];
    return [toHash hash];
}

- (BOOL)isEqual:(id)object
{
    return [self hash] == [object hash];
}

@end
