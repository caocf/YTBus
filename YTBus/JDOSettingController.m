//
//  JDOSettingController.m
//  YTBus
//
//  Created by zhang yi on 14-10-29.
//  Copyright (c) 2014年 胶东在线. All rights reserved.
//

#import "JDOSettingController.h"
#import "V8HorizontalPickerView.h"

@interface JDOSettingController () <V8HorizontalPickerViewDataSource,V8HorizontalPickerViewDelegate>

@property (nonatomic,assign) IBOutlet UISegmentedControl *distanceSegment;
@property (nonatomic,assign) IBOutlet UISegmentedControl *intervalSegment;
@property (nonatomic,assign) IBOutlet V8HorizontalPickerView *pickerView;

-(IBAction)onDistanceChanged:(id)sender;

@end

@implementation JDOSettingController{
    int distance;
    int hintNumber;
    UILabel *indicatorLabel;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.bounces = false;
    
    distance = [[NSUserDefaults standardUserDefaults] integerForKey:@"nearby_distance"]?:1000;
    hintNumber = [[NSUserDefaults standardUserDefaults] integerForKey:@"station_hint_number"]?:3;
    
//    self.distanceSlider.value = distance;
    
    UIImageView *background = [[UIImageView alloc] initWithFrame:self.pickerView.bounds];
    background.image = [UIImage imageNamed:@"setting_count_bg"];
    [self.pickerView addSubview:background];
    
    self.pickerView.selectedTextColor = [UIColor whiteColor];
    self.pickerView.textColor   = [UIColor grayColor];
    self.pickerView.delegate    = self;
    self.pickerView.dataSource  = self;
    self.pickerView.elementFont = [UIFont boldSystemFontOfSize:14.0f];
    self.pickerView.selectionPoint = CGPointMake(60, 0);
    [self.pickerView setIndicatorPosition:V8HorizontalPickerIndicatorCenter];
    [self.pickerView scrollToElement:hintNumber-1 animated:NO];
    
    UIImageView *indicator = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 36.0f, 36.0f)];
    indicator.image = [UIImage imageNamed:@"setting_count_indicator"];
    indicatorLabel = [[UILabel alloc] initWithFrame:CGRectMake(6.0f, 6.0f, 24.0f, 24.0f)];
    [indicatorLabel setBackgroundColor:[UIColor clearColor]];
    [indicatorLabel setFont:[UIFont boldSystemFontOfSize:16.0f]];
    [indicatorLabel setTextColor:[UIColor whiteColor]];
    [indicatorLabel setTextAlignment:NSTextAlignmentCenter];
    [indicatorLabel setText:[NSString stringWithFormat:@"%d", hintNumber]];
    [indicator addSubview:indicatorLabel];
    
    self.pickerView.selectionIndicatorView = indicator;
}

-(IBAction)onDistanceChanged:(UISegmentedControl *)sender{
//    distance = [[NSNumber numberWithFloat:sender.value] intValue];
//    self.distanceLabel.text = [NSString stringWithFormat:@"%d米",distance];
    
    [[NSUserDefaults standardUserDefaults] setInteger:distance forKey:@"nearby_distance"];
}

-(IBAction)onDistanceFinished:(UISegmentedControl *)sender{
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"nearby_distance_changed" object:nil];
    
}

- (NSInteger)numberOfElementsInHorizontalPickerView:(V8HorizontalPickerView *)picker{
    return 10;
}

- (NSInteger)horizontalPickerView:(V8HorizontalPickerView *)picker widthForElementAtIndex:(NSInteger)index{
    return 24.0f;
}

- (UIView *)horizontalPickerView:(V8HorizontalPickerView *)picker viewForElementAtIndex:(NSInteger)index{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(3, 3, 18.0f, 18.0f)];
    [label setBackgroundColor:[UIColor clearColor]];
    [label setText:[NSString stringWithFormat:@"%d", index+1]];
    [label setTextColor:[UIColor grayColor]];
    [label setTextAlignment:NSTextAlignmentCenter];
    [label setFont:[UIFont boldSystemFontOfSize:13.0]];
    
    return label;
}

- (void)horizontalPickerView:(V8HorizontalPickerView *)picker currentSelectingElementAtIndex:(NSInteger)index{
    [[NSUserDefaults standardUserDefaults] setInteger:index+1 forKey:@"station_hint_number"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [indicatorLabel setText:[NSString stringWithFormat:@"%d", index+1]];
}

- (void)horizontalPickerView:(V8HorizontalPickerView *)picker didSelectElementAtIndex:(NSInteger)index{
//    self.currentSelectedCount = index;
    [indicatorLabel setText:[NSString stringWithFormat:@"%d", index+1]];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
