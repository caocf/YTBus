//
//  JDOConstants.h
//  YTBus
//
//  Created by zhang yi on 14-11-19.
//  Copyright (c) 2014年 胶东在线. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UIColor+SSToolkitAdditions.h"
#import "JDOUtils.h"

typedef enum {
    ViewStatusNormal = 0,   //显示正常视图
    ViewStatusNoNetwork,    //网络可不用
    ViewStatusLogo,         //初始化页面(网站Logo)
    ViewStatusLoading,      //视图加载中
    ViewStatusRetry,        //服务器错误,点击重试
} ViewStatusType;   //需要从网络加载的视图的几种状态变化

#define After_iOS6 [[[UIDevice currentDevice] systemVersion] floatValue]>=6.0
#define After_iOS7 [[[UIDevice currentDevice] systemVersion] floatValue]>=7.0
#define DFE_Server_URL @"http://218.56.32.7:1030"
#define JDO_Server_URL @"http://p.jiaodong.net/mobileQuery/V11"
#define JDO_RESOURCE_URL @"http://p.jiaodong.net/jdmsys/"
#define Download_Action @"SynBusSoftWebservice/DownloadServlet"
#define DB_Download_URL @"http://218.56.32.7:1030/SynBusSoftWebservice/DownloadServlet?method=downloadDb"
#define GetBusLineStatus_URL @"http://218.56.32.7:4999/BusPosition.asmx"
#define GetBusLineStatus_MSG @"<v:Envelope xmlns:i=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:d=\"http://www.w3.org/2001/XMLSchema\" xmlns:c=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:v=\"http://schemas.xmlsoap.org/soap/envelope/\"><v:Header /><v:Body><GetBusLineStatus xmlns=\"http://www.dongfang-china.com/\" id=\"o0\" c:root=\"1\"><stationID i:type=\"d:int\">%@</stationID><lineID i:type=\"d:int\">%@</lineID><lineStatus i:type=\"d:int\">%@</lineStatus></GetBusLineStatus></v:Body></v:Envelope>"
#define Bus_Refresh_Interval 10


#define Headline_Height 176.0f
#define News_Cell_Image_Height 100.0f
#define Adv_Cell_Height 60.0f
#define News_Cell_Height 70.0f
#define Review_Font_Size 14

// From here to end of file added by Injection Plugin //
//#ifdef DEBUG
//#define INJECTION_ENABLED
//#endif
//
//#import "/Users/zhangyi/Library/Application Support/Developer/Shared/Xcode/Plug-ins/InjectionPlugin.xcplugin/Contents/Resources/BundleInterface.h"

@interface JDOConstants : NSObject

@end

/*  
同名站点2个以上：
 孔家滩北站
 德利环保（中炬建安）
 新世界百货
 烟台人才市场场站
 烟台国际
 福山高新产业区管委
 西山华庭
 高新区南寨公交场站
 东林
 东泊子
 体育公园
 冰轮芝罘工业园
 刘家埠
 南寨
 南苑街
 双河东路
 官庄
 容大东海岸
 帝景苑小区
 恒源路
 烟大路
 莱山区政府
 马山
 高新区公交场站
 高新区管委
 黄海城市花园
 */