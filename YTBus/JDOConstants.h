//
//  JDOConstants.h
//  YTBus
//
//  Created by zhang yi on 14-11-19.
//  Copyright (c) 2014年 胶东在线. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UIColor+SSToolkitAdditions.h"

#define After_iOS7 [[[UIDevice currentDevice] systemVersion] floatValue]>=7.0
#define DB_Download_URL @"http://218.56.32.7:1030/SynBusSoftWebservice/DownloadServlet?method=downloadDb"
#define GetBusLineStatus_URL @"http://218.56.32.7:4999/BusPosition.asmx"
#define GetBusLineStatus_MSG @"<v:Envelope xmlns:i=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:d=\"http://www.w3.org/2001/XMLSchema\" xmlns:c=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:v=\"http://schemas.xmlsoap.org/soap/envelope/\"><v:Header /><v:Body><GetBusLineStatus xmlns=\"http://www.dongfang-china.com/\" id=\"o0\" c:root=\"1\"><stationID i:type=\"d:int\">%@</stationID><lineID i:type=\"d:int\">%@</lineID><lineStatus i:type=\"d:int\">%@</lineStatus></GetBusLineStatus></v:Body></v:Envelope>"
#define Bus_Refresh_Interval 10

@interface JDOConstants : NSObject

@end
