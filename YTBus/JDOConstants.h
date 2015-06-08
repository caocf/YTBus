//
//  JDOConstants.h
//  YTBus
//
//  Created by zhang yi on 14-11-19.
//  Copyright (c) 2014年 胶东在线. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UIColor+SSToolkitAdditions.h"
#import "NSString+SSToolkitAdditions.h"
#import "JDOUtils.h"
#import "MobClick.h"

typedef enum {
    ViewStatusNormal = 0,   //显示正常视图
    ViewStatusNoNetwork,    //网络可不用
    ViewStatusLogo,         //初始化页面(网站Logo)
    ViewStatusLoading,      //视图加载中
    ViewStatusRetry,        //服务器错误,点击重试
} ViewStatusType;   //需要从网络加载的视图的几种状态变化

// 当前站点范围121.23495  121.598595  37.341312   37.62461
#define YT_MIN_X 121.1
#define YT_MAX_X 121.7
#define YT_MIN_Y 37.2
#define YT_MAX_Y 37.7

#define Main_Background_Color @"f0f0f0"
#define URL_Request_Timeout 8.0f    //超时时间应该小于自动刷新时间，不然每次取消掉前面的connection就不能走didFinishConnection了
#define Advertise_Cache_File @"advertise"
#define Advertise_Cache_File2 @"advertise_busline"
#define Redirect_Url @"http://m.jiaodong.net/gongjiao"
#define After_iOS6 [[[UIDevice currentDevice] systemVersion] floatValue]>=6.0
#define After_iOS7 [[[UIDevice currentDevice] systemVersion] floatValue]>=7.0
#define After_iOS8 [[[UIDevice currentDevice] systemVersion] floatValue]>=8.0
#define DFE_Server_URL @"http://ytbus.jiaodong.cn:4998"
#define JDO_Server_URL @"http://p.jiaodong.net/mobileQuery/V12"
#define JDO_RESOURCE_URL @"http://p.jiaodong.net/jdmsys/"
#define JDO_Bus_Server @"http://p.jiaodong.net/ytbus/V10"
#define Download_Action @"SynBusSoftWebservice/DownloadServlet"

#define Default_Realtime_Port @"4990"
#define GetBusLineStatus_SOAP_URL @"http://ytbus.jiaodong.cn:%@/BusPosition.asmx"
#define GetBusLineStatus_SOAP_MSG @"<?xml version=\"1.0\" encoding=\"utf-8\"?>"                                            @"<soap:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\">"                                                                       @"  <soap:Body>"                                                                                                                    @"      <GetBusLineStatus xmlns=\"http://www.dongfang-china.com/\">"                                                                    @"          <stationID>%@</stationID>"                                                                                                  @"          <lineID>%@</lineID>"                                                                                                                @"          <lineStatus>%@</lineStatus>"                                                                                                        @"          <userRole>0</userRole>"                                                                                                             @"      </GetBusLineStatus>"                                                                                                                @"  </soap:Body>"                                                                                                                       @"</soap:Envelope>"

#define GetDbVersion_SOAP_URL @"http://ytbus.jiaodong.cn:4998/SynBusSoftWebservice/services/SynBusSoft"
#define GetDbVersion_SOAP_MSG @"<?xml version=\"1.0\" encoding=\"utf-8\"?>"                                                                                                             @"<soap:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\">"                                                                                                                          @"  <soap:Body>"                                                                                                                                                    @"      <getDbVersion>"                                                                                                                                               @"      </getDbVersion>"                                                                                                                                    @"  </soap:Body>"                                                                                                                                                           @"</soap:Envelope>"

#define SubmmitFeedback_SOAP_URL @"http://ytbus.jiaodong.cn:4998/SynBusSoftWebservice/services/FeedBackService"
#define SubmmitFeedback_SOAP_MSG @"<?xml version=\"1.0\" encoding=\"utf-8\"?>"                                                          @"<soap:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\">"                                                                              @"  <soap:Body>"                                                                                                                    @"      <feedBack>"                                                                                                                 @"          <in0>%@</in0>"                                                                                                      @"          <in1>%@</in1>"                                                                                                                @"          <in2>%@</in2>"                                                                                                        @"          <in3>%@</in3>"                                                                                                              @"          <in4>%@</in4>"                                                                                                                          @"          <in5>%@</in5>"                                                                                                           @"      </feedBack>"                                                                                                                @"  </soap:Body>"                                                                                                                       @"</soap:Envelope>"

#define Headline_Height 176.0f
#define News_Cell_Image_Height 100.0f
#define Adv_Cell_Height 60.0f
#define News_Cell_Height 70.0f
#define Review_Font_Size 14

#define Screen_Height [[UIScreen mainScreen] bounds].size.height
#define Screen_Width [[UIScreen mainScreen] bounds].size.width

#define App_Height ([[[UIDevice currentDevice] systemVersion] floatValue]>=7.0 ? [UIScreen mainScreen].bounds.size.height :[UIScreen mainScreen].applicationFrame.size.height)

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