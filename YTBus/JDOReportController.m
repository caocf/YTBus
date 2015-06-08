//
//  JDOReportController.m
//  YTBus
//
//  Created by zhang yi on 15-2-9.
//  Copyright (c) 2015年 胶东在线. All rights reserved.
//

#import "JDOReportController.h"
#import "SSTextView.h"
#import "JDOConstants.h"
#import "IQKeyboardManager.h"
#import "JSONKit.h"

#define TextColor [UIColor colorWithRed:100/255.0f green:100/255.0f blue:100/255.0f alpha:1.0f]

@interface JDOReportController () <UITextFieldDelegate,UITextViewDelegate,NSXMLParserDelegate>

@end

@implementation JDOReportController{
    NSString *_station;
    NSString *_direction;
    NSString *_stationId;
    NSString *_lineId;
    NSString *_lineDirection;
    
    UITextField *line4Label;
    SSTextView *line5Label;
    
    NSURLConnection *_connection;
    NSMutableData *_webData;
    NSMutableString *_jsonResult;
    BOOL isRecording;
}

- (id)init{
    self = [super init];
    if (self){
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"地图-关闭"] style:UIBarButtonItemStylePlain target:self action:@selector(cancelButtonClickHandler:)];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"纠错-对勾"] style:UIBarButtonItemStylePlain target:self action:@selector(publishButtonClickHandler:)];
        self.title = @"我要纠错";
    }
    return self;
}

-(id)initWithStation:(NSString *)station direction:(NSString *)direction stationId:(NSString *)stationId lineId:(NSString *)lineId lineDirection:(NSString *)lineDirection{
    self = [self init];
    if (self){
        _station = station;
        _direction = direction;
        _stationId = stationId;
        _lineId = lineId;
        _lineDirection = lineDirection;
    }
    return self;
}

-(void)loadView{
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.view = scrollView;
}

- (void)viewWillAppear:(BOOL)animated{
    [[IQKeyboardManager sharedManager] setEnable:true];
}

- (void)viewWillDisappear:(BOOL)animated{
    [[IQKeyboardManager sharedManager] setEnable:false];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (After_iOS7){
        [self setExtendedLayoutIncludesOpaqueBars:NO];
    }
    self.view.backgroundColor = [UIColor colorWithHex:@"dfded9"];
    
    // line1
    int deltaY = 10;
//    UIImageView *line1BG = [[UIImageView alloc] initWithFrame:CGRectMake(10, deltaY, 300, 40)];
//    line1BG.image = [[UIImage imageNamed:@"纠错-输入框"] stretchableImageWithLeftCapWidth:3 topCapHeight:3];
//    [self.view addSubview:line1BG];
    UIImageView *icon1 = [[UIImageView alloc] initWithFrame:CGRectMake(20, deltaY+6.5f, 22, 17)];
    icon1.image = [UIImage imageNamed:@"纠错-时间"];
    [self.view addSubview:icon1];
    UILabel *line1Label = [[UILabel alloc] initWithFrame:CGRectMake(50, deltaY, 260, 30)];
    line1Label.backgroundColor = [UIColor clearColor];
    line1Label.font = [UIFont systemFontOfSize:14];
    line1Label.textColor = TextColor;
    line1Label.text = [JDOUtils formatDate:[NSDate date] withFormatter:DateFormatYMDHM];
    [self.view addSubview:line1Label];
    
    // line2
    deltaY += 30;
//    UIImageView *line2BG = [[UIImageView alloc] initWithFrame:CGRectMake(10, deltaY, 300, 40)];
//    line2BG.image = [[UIImage imageNamed:@"纠错-输入框"] stretchableImageWithLeftCapWidth:3 topCapHeight:3];
//    [self.view addSubview:line2BG];
    UIImageView *icon2 = [[UIImageView alloc] initWithFrame:CGRectMake(20, deltaY+6.5f, 22, 17)];
    icon2.image = [UIImage imageNamed:@"纠错-线路"];
    [self.view addSubview:icon2];
    UILabel *line2Label = [[UILabel alloc] initWithFrame:CGRectMake(50, deltaY, 260, 30)];
    line2Label.backgroundColor = [UIColor clearColor];
    line2Label.font = [UIFont systemFontOfSize:14];
    line2Label.textColor = TextColor;
    line2Label.text = _direction;
    [self.view addSubview:line2Label];
    
    // line3
    if (_station) {
        deltaY += 30;
//        UIImageView *line3BG = [[UIImageView alloc] initWithFrame:CGRectMake(10, deltaY, 300, 40)];
//        line3BG.image = [[UIImage imageNamed:@"纠错-输入框"] stretchableImageWithLeftCapWidth:3 topCapHeight:3];
//        [self.view addSubview:line3BG];
        UIImageView *icon3 = [[UIImageView alloc] initWithFrame:CGRectMake(20, deltaY+6.5f, 22, 17)];
        icon3.image = [UIImage imageNamed:@"纠错-定位"];
        [self.view addSubview:icon3];
        UILabel *line3Label = [[UILabel alloc] initWithFrame:CGRectMake(50, deltaY, 260, 30)];
        line3Label.backgroundColor = [UIColor clearColor];
        line3Label.font = [UIFont systemFontOfSize:14];
        line3Label.textColor = TextColor;
        line3Label.text = _station;
        [self.view addSubview:line3Label];
    }
    
    //line4
    deltaY += 40;
    UIImageView *line4BG = [[UIImageView alloc] initWithFrame:CGRectMake(10, deltaY, 300, 40)];
    line4BG.image = [[UIImage imageNamed:@"纠错-输入框"] stretchableImageWithLeftCapWidth:3 topCapHeight:3];
    [self.view addSubview:line4BG];
    UIImageView *icon4 = [[UIImageView alloc] initWithFrame:CGRectMake(20, deltaY+11.5f, 22, 17)];
    icon4.image = [UIImage imageNamed:@"纠错-电话"];
    [self.view addSubview:icon4];
    line4Label = [[UITextField alloc] initWithFrame:CGRectMake(50, deltaY, 260, 40)];
    line4Label.backgroundColor = [UIColor clearColor];
    line4Label.font = [UIFont systemFontOfSize:14];
    line4Label.textColor = TextColor;
    line4Label.placeholder = @"请输入手机号码[可选]";
    line4Label.keyboardType = UIKeyboardTypeNumberPad;
    [self.view addSubview:line4Label];
    
    //line5
    deltaY += 50;
    UIImageView *line5BG = [[UIImageView alloc] initWithFrame:CGRectMake(10, deltaY, 300, 120)];
    line5BG.image = [[UIImage imageNamed:@"纠错-输入框"] stretchableImageWithLeftCapWidth:3 topCapHeight:3];
    [self.view addSubview:line5BG];
    UIImageView *icon5 = [[UIImageView alloc] initWithFrame:CGRectMake(20, deltaY+11.5f, 22, 17)];
    icon5.image = [UIImage imageNamed:@"纠错-输入"];
    [self.view addSubview:icon5];
    line5Label = [[SSTextView alloc] initWithFrame:CGRectMake(45, deltaY+3, 265, 117)];
    line5Label.backgroundColor = [UIColor clearColor];
    line5Label.font = [UIFont systemFontOfSize:14];
    line5Label.textColor = TextColor;
    line5Label.placeholder = @"请填写纠错内容[必填]";
    line5Label.placeholderTextColor = [UIColor colorWithWhite:0.8f alpha:1.0f];
    [self.view addSubview:line5Label];
    
    deltaY += 130;
    UILabel *psLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, deltaY, 298, 60)];
    psLabel.backgroundColor = [UIColor clearColor];
    psLabel.numberOfLines = 3;
    psLabel.font = [UIFont systemFontOfSize:14];
    psLabel.textColor = TextColor;
    NSString *originalText=@"注：本功能仅供用户对线路、站点、车辆等数据的相关问题进行上报，若您有其他方面的意见和建议，请访问“更多”->“意见反馈”。";
    if (After_iOS6) {
        NSMutableAttributedString * attrString = [[NSMutableAttributedString alloc] initWithString:originalText];
        NSMutableParagraphStyle * paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        [paragraphStyle setLineSpacing:4];
        [attrString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, [originalText length])];
        psLabel.attributedText = attrString;
    }else{
        psLabel.text = originalText;
    }
    [self.view addSubview:psLabel];
}

- (void)cancelButtonClickHandler:(id)sender{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)publishButtonClickHandler:(id)sender{
    [line4Label resignFirstResponder];
    [line5Label resignFirstResponder];
    if (![JDOUtils isEmptyString:line4Label.text] && ![JDOUtils checkTelephone:line4Label.text]) {
        [JDOUtils showHUDText:@"手机号格式错误" inView:self.view];
        return;
    }
    if ([JDOUtils isEmptyString:line5Label.text]) {
        [JDOUtils showHUDText:@"请输入纠错内容" inView:self.view];
        return;
    }
    if ([line5Label.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length<10) {
        [JDOUtils showHUDText:@"纠错内容最少输入10个字符" inView:self.view];
        return;
    }
    
    self.navigationItem.rightBarButtonItem.enabled = false;
    NSString *time = [JDOUtils formatDate:[NSDate date] withFormatter:DateFormatYMDHM];
    NSString *soapMessage = [NSString stringWithFormat:SubmmitFeedback_SOAP_MSG,time,_lineId,_lineDirection,line5Label.text, _station, line4Label.text];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:SubmmitFeedback_SOAP_URL] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:URL_Request_Timeout];
    [request addValue:@"text/xml; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [request addValue:[NSString stringWithFormat:@"%lu",(unsigned long)[soapMessage length]] forHTTPHeaderField:@"Content-Length"];
    [request addValue:@"http://service.epf/feedBack" forHTTPHeaderField:@"SOAPAction"];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[soapMessage dataUsingEncoding:NSUTF8StringEncoding]];
    
    if (_connection) {
        [_connection cancel];
    }
    _connection = [NSURLConnection connectionWithRequest:request delegate:self];
    _webData = [NSMutableData data];
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    [_webData appendData:data];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection{
    NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData: _webData];
    [xmlParser setDelegate: self];
    [xmlParser parse];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    self.navigationItem.rightBarButtonItem.enabled = true;
    [JDOUtils showHUDText:[NSString stringWithFormat:@"连接服务器异常:%ld",(long)error.code] inView:self.view];
    NSLog(@"error:%@",error);
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
        self.navigationItem.rightBarButtonItem.enabled = true;
        isRecording = false;
        if ([_jsonResult isEqualToString:@"1"]) {
            [JDOUtils showHUDText:@"提交成功，感谢您的参与！" inView:self.view];
            [self performSelector:@selector(cancelButtonClickHandler:) withObject:nil afterDelay:1.0f];
        }else if([_jsonResult isEqualToString:@"0"]){
            [JDOUtils showHUDText:@"提交失败，请稍后再试。" inView:self.view];
        }else{
            [JDOUtils showHUDText:@"提交失败：未知状态" inView:self.view];
        }
    }
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError{
    self.navigationItem.rightBarButtonItem.enabled = true;
    [JDOUtils showHUDText:[NSString stringWithFormat:@"解析XML错误:%ld",(long)parseError.code] inView:self.view];
    NSLog(@"Error:%@",parseError);
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
