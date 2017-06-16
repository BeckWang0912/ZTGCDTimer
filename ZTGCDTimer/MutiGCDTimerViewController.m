//
//  MutiGCDTimerViewController.m
//  ZTGCDTimer
//
//  Created by BY-iMac on 17/6/16.
//  Copyright © 2017年 beck.wang. All rights reserved.
//

#import "MutiGCDTimerViewController.h"
#import "ZTGCDTimerManager.h"

@interface MutiGCDTimerViewController ()

@property (nonatomic,strong) UITableView *tableView;
@property (nonatomic,strong) NSMutableDictionary    *addtimerArray;

@end

@implementation MutiGCDTimerViewController

- (instancetype)init{
    self = [super init];
    
    if(self){
        _addtimerArray = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.tableView];
    [self addGCDTimerArry];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc{
    NSLog(@"当所有timer周期结束时调用dealloc销毁,如果计时器生命周期比较长，建议在页面消失时取消timer");
    [self.addtimerArray enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [[ZTGCDTimerManager sharedInstance] cancelTimerWithName:key];
    }];
}

#pragma mark - UITableViewDelegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 44;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 10;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"defaultType"];
    
    if(self.addtimerArray.count > 0 && self.addtimerArray.count >= indexPath.row)
    {
        NSString *timerKey = [NSString stringWithFormat:@"beck.wang.timer_%ld",(long)indexPath.row];
        if(!kStringIsEmpty((NSString*)[self.addtimerArray objectForKey:timerKey])){
            cell.textLabel.text = (NSString*)[self.addtimerArray objectForKey:timerKey];
        }
    }
    
    return  cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    return;
}

#pragma mark - getter & setter
- (UITableView*)tableView{
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, KS_Width, KS_Heigth) style:UITableViewStyleGrouped];
        _tableView.delegate = (id)self;
        _tableView.dataSource = (id)self;
        [_tableView setSectionHeaderHeight:0];
        _tableView.separatorColor = [UIColor groupTableViewBackgroundColor];
        _tableView.showsVerticalScrollIndicator = NO;
    }
    return _tableView;
}

#pragma mark - private method
- (void)addGCDTimerArry{
    
    NSMutableDictionary *dict = [NSMutableDictionary new];
    
    BIWeakObj(self)
    
    for (int i = 0; i<10; i++) {
        
        NSString *timerKey = [NSString stringWithFormat:@"beck.wang.timer_%ld",(long)i];
        
        __block int totalSeconds = 30;
        
        [dict setValue:[NSString stringWithFormat:@"%ld",(long)totalSeconds] forKey:timerKey];
        
        [[ZTGCDTimerManager sharedInstance] scheduleGCDTimerWithName:timerKey interval:1 queue:dispatch_get_main_queue() repeats:YES option:CancelPreviousTimerAction  action:^{
            
            int totalCount = [[dict objectForKey:timerKey] intValue];
            
            totalCount -= 1;
            
            [dict setValue:[NSString stringWithFormat:@"%ld",(long)totalCount] forKey:timerKey];
            
            [selfWeak.addtimerArray setValue:[NSString stringWithFormat:@"剩%@,订单将自动关闭",[self timeFormatted:totalCount]] forKey:timerKey];
            
            if(totalCount < 0)
            {
                [[ZTGCDTimerManager sharedInstance] cancelTimerWithName:timerKey];
                [selfWeak.addtimerArray setValue:@"" forKey:timerKey];
            }
            NSIndexPath *path = [NSIndexPath indexPathForRow:i inSection:0];
            [selfWeak.tableView reloadRowsAtIndexPaths:@[path] withRowAnimation:UITableViewRowAnimationNone];
        }];
        
    }
}

// 转换成时天分秒
- (NSString *)timeFormatted:(int)totalSeconds
{
    
    int day = (int)totalSeconds / (24 * 3600);
    int hours =  (int)totalSeconds / 3600 % 24;
    int minutes =  (int)(totalSeconds - day * 24 * 3600 - hours * 3600) / 60;
    int seconds = (int)(totalSeconds - day * 24 * 3600 - hours * 3600 - minutes*60);
    
    NSString *str;
    if (day != 0) {
        str = [NSString stringWithFormat:@"%02d天%02d时%02d分%02d秒",day,hours,minutes,seconds];
    }else if (day==0 && hours != 0) {
        str = [NSString stringWithFormat:@"%02d时%02d分%02d秒",hours,minutes,seconds];
    }else if (day== 0 && hours == 0 && minutes!=0) {
        str = [NSString stringWithFormat:@"%02d分%02d秒",minutes,seconds];
    }else{
        str = [NSString stringWithFormat:@"%02d秒",seconds];
    }
    
    return str;
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
