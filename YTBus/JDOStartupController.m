//
//  JDOStartupController.m
//  YTBus
//
//  Created by zhang yi on 15-4-9.
//  Copyright (c) 2015年 胶东在线. All rights reserved.
//

#import "JDOStartupController.h"
#import "JDODatabase.h"
#import "AFNetworking.h"
#import "SSZipArchive.h"
#import "MBProgressHUD.h"
#import "JDOConstants.h"
#import "JDOHttpClient.h"
#import "AppDelegate.h"
#import "JSONKit.h"
#import "JDOAlertTool.h"


@interface JDOStartupController () <SSZipArchiveDelegate,NSXMLParserDelegate> {
    MBProgressHUD *hud;
    NSURLConnection *_connection;
    NSMutableData *_webData;
    NSMutableString *_jsonResult;
    BOOL isRecording;
    int remoteDBVersion;
    __strong JDOAlertTool *alert;
}

@end

@implementation JDOStartupController

- (void)checkDBInfo {
    if (![JDODatabase isDBExistInDocument]) {   // 若document中不存在数据库文件，则下载数据库文件
        hud = [MBProgressHUD showHUDAddedTo:self.view animated:true];
        hud.minShowTime = 1.0f;
        hud.labelText = @"下载最新数据";
        [self downloadSQLite_ifFailedUse:1];
    }else{
        //检查是否有数据更新
        hud = [MBProgressHUD showHUDAddedTo:self.view animated:true];
        hud.minShowTime = 1.0f;
        hud.labelText = @"检查数据更新";
        
        NSString *soapMessage = GetDbVersion_SOAP_MSG;
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:GetDbVersion_SOAP_URL] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:URL_Request_Timeout];
        [request addValue:@"text/xml; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
        [request addValue:[NSString stringWithFormat:@"%ld",[soapMessage length]] forHTTPHeaderField:@"Content-Length"];
        [request addValue:@"http://service.epf/getAppVersion" forHTTPHeaderField:@"SOAPAction"];
        [request setHTTPMethod:@"POST"];
        [request setHTTPBody:[soapMessage dataUsingEncoding:NSUTF8StringEncoding]];
        
        _connection = [NSURLConnection connectionWithRequest:request delegate:self];
        _webData = [NSMutableData data];
    }
}

- (void)downloadSQLite_ifFailedUse:(int) which{
    [[JDOHttpClient sharedDFEClient] getPath:Download_Action parameters:@{@"method":@"downloadDb"} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"下载完成，开始保存");
        NSData *zipData = (NSData *)responseObject;
        BOOL success = [JDODatabase saveZipFile:zipData];
        if ( success) { // 解压缩文件
            NSLog(@"保存完成，开始解压");
            BOOL result = [JDODatabase unzipDBFile:self];
            if (!result) {  // 正在解压
                [self hideHUDWithError:@"解压数据出错" useWhich:which];
            }
        }else{
            [self hideHUDWithError:@"保存数据出错" useWhich:which];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self hideHUDWithError:@"连接服务器出错" useWhich:which];
    }];
}

- (void)hideHUDWithError:(NSString *)info useWhich:(int) which{
    [hud hide:true];
    
    alert = [[JDOAlertTool alloc] init];
    [alert showAlertView:self title:info message:@"将使用历史数据包，数据可能不准确。" cancelTitle:@"确定" otherTitle1:nil otherTitle2:nil cancelAction:^{
        [self enterMainStoryboard:false];
    } otherAction1:nil otherAction2:nil];

    [JDODatabase openDB:which];
}

- (void) enterMainStoryboard:(BOOL) delay{
    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    if (delay) {
        [hud hide:true afterDelay:1.0f];
        [delegate performSelector:@selector(enterMainStoryboard) withObject:nil afterDelay:1.0f];
    }else{
        [hud hide:true];
        [delegate enterMainStoryboard];
    }
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    [_webData appendData:data];
}


//TODO 服务器错误的格式
/*
 <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><soap:Body><soap:Fault><faultcode>soap:Client</faultcode><faultstring>Fault: java.lang.NullPointerException</faultstring></soap:Fault></soap:Body></soap:Envelope>
*/
-(void)connectionDidFinishLoading:(NSURLConnection *)connection{
    NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData: _webData];
    [xmlParser setDelegate: self];
    [xmlParser parse];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    hud.mode = MBProgressHUDModeText;
    hud.labelText = @"连接服务器出错";
    hud.detailsLabelText = error.localizedDescription;
    
    [JDODatabase openDB:2];
    [self enterMainStoryboard:true];
}

-(void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *) namespaceURI qualifiedName:(NSString *)qName attributes: (NSDictionary *)attributeDict{
    if( [elementName isEqualToString:@"ns1:out"]){
        _jsonResult = [[NSMutableString alloc] init];
        isRecording = true;
    }
}

-(void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string{
    if( isRecording ){
        [_jsonResult appendString: string];
    }
}

-(void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName{
    if( [elementName isEqualToString:@"ns1:out"]){
        isRecording = false;
        NSDictionary *dict = [_jsonResult objectFromJSONString];
        NSNumber *version = [dict objectForKey:@"dbVersion"];
        NSNumber *dbSize = [dict objectForKey:@"dbSize"];
        remoteDBVersion = [version intValue];
        [self compareDBVersion:dbSize];
    }
}

- (void)compareDBVersion:(NSNumber *)dbSize{
    [JDODatabase openDB:2];
    
    long ignoreVersion = [[NSUserDefaults standardUserDefaults] integerForKey:@"JDO_Ignore_Version"];
    if (ignoreVersion >= remoteDBVersion) {
        [self enterMainStoryboard:true];
        return;
    }
    
    FMDatabase *db = [JDODatabase sharedDB];
//    BOOL success = [db executeUpdate:@"update version set versioncode = 264"];  // 测试对比新版本
    FMResultSet *rs = [db executeQuery:@"select versioncode from version"];
    if ([rs next]) {
        int version = [rs intForColumn:@"versioncode"];
        if (version < remoteDBVersion) {
            alert = [[JDOAlertTool alloc] init];
            [alert showAlertView:self title:@"发现新数据" message:[NSString stringWithFormat:@"当前版本:%d，最新版本:%d，\r\n升级数据包容量:%.2fM",version,remoteDBVersion,[dbSize longValue]/1000.0f/1000.0f] cancelTitle:@"跳过该版本" otherTitle1:@"下载" otherTitle2:@"忽略" cancelAction:^{
                [[NSUserDefaults standardUserDefaults] setInteger:remoteDBVersion forKey:@"JDO_Ignore_Version"];
                [[NSUserDefaults standardUserDefaults] synchronize];
                [self enterMainStoryboard:false];
            } otherAction1:^{
                hud.labelText = @"下载最新数据";
                [self downloadSQLite_ifFailedUse:2];
            } otherAction2:^{
                [self enterMainStoryboard:false];
            }];
        }else{
            [self enterMainStoryboard:true];
        }
    }
    [rs close];
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError{
    hud.mode = MBProgressHUDModeText;
    hud.labelText = @"解析版本出错";
    hud.detailsLabelText = parseError.localizedDescription;
    
    [JDODatabase openDB:2 force:true];
    [self enterMainStoryboard:true];
}

- (void)zipArchiveDidUnzipArchiveAtPath:(NSString *)path zipInfo:(unz_global_info)zipInfo unzippedPath:(NSString *)unzippedPath{
    NSLog(@"解压完成，打开数据库:%@",[NSDate date]);
    [[NSUserDefaults standardUserDefaults] setBool:false forKey:@"JDO_GPS_Transformed"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [JDODatabase openDB:2 force:true];
//    [self checkGPSInfo];
    
    [self enterMainStoryboard:true];
}

- (void)zipArchiveProgressEvent:(NSInteger)loaded total:(NSInteger)total{
    NSLog(@"解压进度:%g",loaded*1.0/total);
}


- (void)checkGPSInfo{   // 检查坐标是否已经转换
    if ( ![[NSUserDefaults standardUserDefaults] boolForKey:@"JDO_GPS_Transformed"] ) {
        if ([self transfromGPS]) {
            [self enterMainStoryboard:false];
        }else{
            alert = [[JDOAlertTool alloc] init];
            [alert showAlertView:self title:@"坐标纠偏出错" message:[[JDODatabase sharedDB] lastErrorMessage] cancelTitle:@"跳过" otherTitle1:@"重试" otherTitle2:nil cancelAction:^{
                [hud hide:true];
                [self enterMainStoryboard:false];
            } otherAction1:^{
                [self transfromGPS];
            } otherAction2:nil];
        }
    }
}

- (BOOL) transfromGPS{  // 转换GPS坐标 地球坐标->百度坐标
    FMDatabase *db = [JDODatabase sharedDB];
    [db beginTransaction];
    FMResultSet *rs = [db executeQuery:@"select id,gpsx2,gpsy2 from station where gpsx2>1 and gpsy2>1"];
    while ([rs next]) {
        NSString *stationId = [NSString stringWithFormat:@"%d",[rs intForColumn:@"ID"]];
        NSNumber *gpsX = [NSNumber numberWithDouble:[rs doubleForColumn:@"GPSX2"]];
        NSNumber *gpsY = [NSNumber numberWithDouble:[rs doubleForColumn:@"GPSY2"]];
        CLLocationCoordinate2D bdStation = BMKCoorDictionaryDecode(BMKConvertBaiduCoorFrom(CLLocationCoordinate2DMake(gpsY.doubleValue, gpsX.doubleValue),BMK_COORDTYPE_GPS));
        BOOL success = [db executeUpdate:@"update station set GPSX2=?, GPSY2=? where id=?",@(bdStation.longitude),@(bdStation.latitude),stationId];
        if (!success) {
            [db rollback];
            return false;
        }
    }
    [rs close];
    [db commit];
    [[NSUserDefaults standardUserDefaults] setBool:true forKey:@"JDO_GPS_Transformed"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    NSLog(@"完成坐标转换:%@",[NSDate date]);
    return true;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
