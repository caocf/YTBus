//
//  JDOHttpClient.m
//  YTBus
//
//  Created by zhang yi on 14-10-31.
//  Copyright (c) 2014年 胶东在线. All rights reserved.
//

#import "JDOHttpClient.h"


@implementation JDOHttpClient 

+ (JDOHttpClient *)sharedClient {
    static JDOHttpClient *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[JDOHttpClient alloc] initWithBaseURL:[NSURL URLWithString:@""]];
    });
    return _sharedClient;
}

- (NSMutableURLRequest *)requestWithMethod:(NSString *)method
                                      path:(NSString *)path
                                parameters:(NSDictionary *)parameters{
    NSMutableURLRequest *request = [super requestWithMethod:method path:path parameters:parameters];
    request.timeoutInterval = 15.0;
    request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    return request;
}

@end
