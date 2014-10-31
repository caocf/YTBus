//
//  JDOSettingController.m
//  YTBus
//
//  Created by zhang yi on 14-10-29.
//  Copyright (c) 2014年 胶东在线. All rights reserved.
//

#import "JDOSettingController.h"
#import "BMapKit.h"

@interface JDOSettingController ()  {
    int distance;
}

@property (nonatomic,assign) IBOutlet UILabel *distanceLabel;
@property (nonatomic,assign) IBOutlet UISlider *distanceSlider;

-(IBAction)onDistanceChanged:(id)sender;

@end

@implementation JDOSettingController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    distance = [[NSUserDefaults standardUserDefaults] integerForKey:@"nearby_distance"];
    if (distance == 0) {
        distance = 1000;
    }
    self.distanceSlider.value = distance;
    self.distanceLabel.text = [NSString stringWithFormat:@"%d米",distance];
}

-(IBAction)onDistanceChanged:(UISlider *)sender{
    distance = [[NSNumber numberWithFloat:sender.value] intValue];
    self.distanceLabel.text = [NSString stringWithFormat:@"%d米",distance];
    
    [[NSUserDefaults standardUserDefaults] setInteger:distance forKey:@"nearby_distance"];
}

-(IBAction)onDistanceFinished:(UISlider *)sender{
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"nearby_distance_changed" object:nil];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
