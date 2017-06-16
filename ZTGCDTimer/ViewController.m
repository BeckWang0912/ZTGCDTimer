//
//  ViewController.m
//  ZTGCDTimer
//
//  Created by BY-iMac on 17/6/16.
//  Copyright © 2017年 beck.wang. All rights reserved.
//

#import "ViewController.h"
#import "ZTGCDTimerManager.h"
#import "MutiGCDTimerViewController.h"

@interface ViewController ()

@property (nonatomic,strong) UILabel    *singleTimerText;
@property (nonatomic,assign) NSInteger   curCountDown;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    UIButton *singleBtn = [[UIButton alloc] initWithFrame:CGRectMake((KS_Width - 200)/2, 120, 200, 30)];
    [singleBtn setTitle:@"启动单个定时器" forState:UIControlStateNormal];
    [singleBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    singleBtn.backgroundColor = [UIColor lightGrayColor];
    [singleBtn addTarget:self action:@selector(clickSingle:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:singleBtn];
    
    [self.view addSubview:self.singleTimerText];
    
    UIButton *MutiBtn = [[UIButton alloc] initWithFrame:CGRectMake((KS_Width - 200)/2, KS_Heigth/2, 200, 30)];
    [MutiBtn setTitle:@"启动多个定时器" forState:UIControlStateNormal];
    [MutiBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    MutiBtn.backgroundColor = [UIColor lightGrayColor];
    [MutiBtn addTarget:self action:@selector(clickMuti:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:MutiBtn];
}

- (void)clickSingle:(id)sender{

    BIWeakObj(self)
    [[ZTGCDTimerManager sharedInstance] scheduleGCDTimerWithName:@"beck.wang.singleTimer" interval:1 queue:dispatch_get_main_queue() repeats:YES option:CancelPreviousTimerAction action:^{
       
        [selfWeak clickCountDown];
    }];
    
    _curCountDown = 60;
}

// 倒计时
- (void)clickCountDown{
    _curCountDown -= 1;
    if (_curCountDown < 0) {
        [[ZTGCDTimerManager sharedInstance] cancelTimerWithName:@"beck.wang.singleTimer"];
        return ;
    }
    else{
        self.singleTimerText.text = [NSString stringWithFormat:@"%@(%ld)S",@"倒计时",(long)_curCountDown];
    }
}

- (void)clickMuti:(id)sender{
    MutiGCDTimerViewController *push = [[MutiGCDTimerViewController alloc] init];
    [self.navigationController pushViewController:push animated:YES];
}

- (UILabel*)singleTimerText{
    if (!_singleTimerText) {
        _singleTimerText = [[UILabel alloc] initWithFrame:CGRectMake((KS_Width - 120)/2, 180, 120, 30)];
        _singleTimerText.textColor = [UIColor blueColor];
    }
    return _singleTimerText;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
