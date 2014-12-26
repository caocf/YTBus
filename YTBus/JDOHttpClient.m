//
//  JDOHttpClient.m
//  YTBus
//
//  Created by zhang yi on 14-10-31.
//  Copyright (c) 2014年 胶东在线. All rights reserved.
//

#import "JDOHttpClient.h"
#import "JDOConstants.h"


@implementation JDOHttpClient 

+ (JDOHttpClient *)sharedDFEClient {
    static JDOHttpClient *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[JDOHttpClient alloc] initWithBaseURL:[NSURL URLWithString:DFE_Server_URL]];
    });
    return _sharedClient;
}

+ (JDOHttpClient *)sharedJDOClient {
    static JDOHttpClient *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[JDOHttpClient alloc] initWithBaseURL:[NSURL URLWithString:JDO_Server_URL]];
    });
    return _sharedClient;
}

- (NSMutableURLRequest *)requestWithMethod:(NSString *)method
                                      path:(NSString *)path
                                parameters:(NSDictionary *)parameters{
    NSMutableURLRequest *request = [super requestWithMethod:method path:path parameters:parameters];
    request.timeoutInterval = 10.0;
    request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    return request;
}

- (void)requestGBKWebPage:(NSString *)urlString{
    NSURL *URL = [NSURL URLWithString:urlString];   //@"http://ip.zdaye.com"
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    AFHTTPRequestOperation *op = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [op setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSData *data = (NSData *)responseObject;
        NSStringEncoding gbkEncoding =CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
        NSString *pageSource = [[NSString alloc] initWithData:data encoding:gbkEncoding];
        NSLog(@"%@",pageSource);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
    [self.operationQueue addOperation:op];
}

@end
