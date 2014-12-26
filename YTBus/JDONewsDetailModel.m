//
//  JDONewsDetailModel.m
//  JiaodongOnlineNews
//
//  Created by zhang yi on 13-6-4.
//  Copyright (c) 2013年 胶东在线. All rights reserved.
//

#import "JDONewsDetailModel.h"
#import "ICUTemplateMatcher.h"

@implementation JDONewsDetailModel

+ (MGTemplateEngine *) sharedTemplateEngine{
    static MGTemplateEngine *_sharedEngine = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedEngine = [MGTemplateEngine templateEngine] ;
    });
    return _sharedEngine;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        self.id = [aDecoder decodeObjectForKey:@"id"];
        self.title = [aDecoder decodeObjectForKey:@"title"];
        self.subtitle = [aDecoder decodeObjectForKey:@"subtitle"];
        self.summary = [aDecoder decodeObjectForKey:@"summary"];
        self.source = [aDecoder decodeObjectForKey:@"source"];
        self.content = [aDecoder decodeObjectForKey:@"content"];
        self.author = [aDecoder decodeObjectForKey:@"author"];
        self.commentCount = [aDecoder decodeObjectForKey:@"commentCount"];
        self.mpic = [aDecoder decodeObjectForKey:@"mpic"];
        self.channelid = [aDecoder decodeObjectForKey:@"channelid"];
        self.addtime = [aDecoder decodeObjectForKey:@"addtime"];
        self.clicknum = [aDecoder decodeObjectForKey:@"clicknum"];
        self.relates = [aDecoder decodeObjectForKey:@"relates"];
        self.tinyurl = [aDecoder decodeObjectForKey:@"tinyurl"];
        self.advs = [aDecoder decodeObjectForKey:@"advs"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.id forKey:@"id"];
    [aCoder encodeObject:self.title forKey:@"title"];
    [aCoder encodeObject:self.subtitle forKey:@"subtitle"];
    [aCoder encodeObject:self.summary forKey:@"summary"];
    [aCoder encodeObject:self.source forKey:@"source"];
    [aCoder encodeObject:self.content forKey:@"content"];
    [aCoder encodeObject:self.author forKey:@"author"];
    [aCoder encodeObject:self.commentCount forKey:@"commentCount"];
    [aCoder encodeObject:self.mpic forKey:@"mpic"];
    [aCoder encodeObject:self.channelid forKey:@"channelid"];
    [aCoder encodeObject:self.murl forKey:@"murl"];
    [aCoder encodeObject:self.addtime forKey:@"addtime"];
    [aCoder encodeObject:self.clicknum forKey:@"clicknum"];
    [aCoder encodeObject:self.relates forKey:@"relates"];
    [aCoder encodeObject:self.tinyurl forKey:@"tinyurl"];
    [aCoder encodeObject:self.advs forKey:@"advs"];
}

+ (NSString *) mergeToHTMLTemplateFromDictionary:(NSDictionary *)dictionary{
    MGTemplateEngine *engine = [[self class] sharedTemplateEngine];
    [engine setMatcher:[ICUTemplateMatcher matcherWithTemplateEngine:engine]];
    NSString *templatePath = [[NSBundle mainBundle] pathForResource:@"content_template" ofType:@"html"];
    
    // 默认字号从UserDefault获取 small_font,normal_font,big_font
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    NSString *fontClass = [userDefault objectForKey:@"font_class"];
    if(fontClass == nil){
        fontClass = @"normal_font";
        [userDefault setObject:fontClass forKey:@"font_class"];
        [userDefault synchronize];
    }
    
    NSMutableDictionary *variables = [[NSMutableDictionary alloc] init];
    [variables setValue:fontClass forKey:@"font_class"];
    [variables addEntriesFromDictionary:dictionary];
    
    return [engine processTemplateInFileAtPath:templatePath withVariables:variables];
}

//- (NSString *) mergeToHTMLTemplate{
//    MGTemplateEngine *engine = [[self class] sharedTemplateEngine];
//    [engine setDelegate:self];
//    [engine setMatcher:[ICUTemplateMatcher matcherWithTemplateEngine:engine]];
//    NSString *templatePath = [[NSBundle mainBundle] pathForResource:@"news_template" ofType:@"html"];
//    
//    NSMutableDictionary *variables = [[NSMutableDictionary alloc] init];
//    NSDictionary *selfDictionary = @{@"title":self.title,@"content":self.content};
//    [variables addEntriesFromDictionary:selfDictionary];
//    
//    return [engine processTemplateInFileAtPath:templatePath withVariables:variables];
//}

- (void)templateEngine:(MGTemplateEngine *)engine blockStarted:(NSDictionary *)blockInfo
{
	//NSLog(@"Started block %@", [blockInfo objectForKey:BLOCK_NAME_KEY]);
}


- (void)templateEngine:(MGTemplateEngine *)engine blockEnded:(NSDictionary *)blockInfo
{
	//NSLog(@"Ended block %@", [blockInfo objectForKey:BLOCK_NAME_KEY]);
}


- (void)templateEngineFinishedProcessingTemplate:(MGTemplateEngine *)engine
{
	//NSLog(@"Finished processing template.");
}


- (void)templateEngine:(MGTemplateEngine *)engine encounteredError:(NSError *)error isContinuing:(BOOL)continuing;
{
	NSLog(@"Template error: %@", error);
}

@end
