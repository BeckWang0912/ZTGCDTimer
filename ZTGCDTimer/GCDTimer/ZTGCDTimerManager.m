//
//  ZTGCDTimerManager.m
//  ZTGCDTimer
//
//  Created by BY-iMac on 17/6/16.
//  Copyright © 2017年 beck.wang. All rights reserved.
//

#import "ZTGCDTimerManager.h"

@interface ZTGCDTimerManager ()

@property (nonatomic, strong) NSMutableDictionary *timerArry;
@property (nonatomic, strong) NSMutableDictionary *timerActionBlockCacheArry;

@end

@implementation ZTGCDTimerManager

#pragma mark - Public Method

// 单例
+ (ZTGCDTimerManager *)sharedInstance
{
    static ZTGCDTimerManager *_ztGCDTimerManager = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken,^{
        _ztGCDTimerManager = [[ZTGCDTimerManager alloc] init];
    });
    
    return _ztGCDTimerManager;
}

// 创建GCDTimer
- (void)scheduleGCDTimerWithName:(NSString *)timerName
                        interval:(double)interval
                           queue:(dispatch_queue_t)queue
                         repeats:(BOOL)repeats
                          option:(TimerActionOption)option
                          action:(dispatch_block_t)action
{
    if (kStringIsEmpty(timerName))
        return;
    
    // timer将被放入的队列queue，也就是最终action执行的队列。传入nil将自动放到一个全局子线程队列中
    if (nil == queue)
    {
        queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    }
    
    // 创建dispatch_source_t的timer
    dispatch_source_t timer = [self.timerArry objectForKey:timerName];
    
    if (nil == timer)
    {
        timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
        dispatch_resume(timer);
        [self.timerArry setObject:timer forKey:timerName];
    }
    
    // 设置首次执行事件、执行间隔和精确度(默认为0.1s)
    dispatch_source_set_timer(timer, dispatch_time(DISPATCH_TIME_NOW, interval * NSEC_PER_SEC), interval * NSEC_PER_SEC, 0.1 * NSEC_PER_SEC);
    
    BIWeakObj(self)
    if(option == CancelPreviousTimerAction) // 取消上一次timer任务
    {
        // 移除上一次任务
        [self removeActionCacheForTimer:timerName];
        
        // 时间间隔到点时执行block
        dispatch_source_set_event_handler(timer, ^{
            
            action();
            
            if (!repeats) {
                [selfWeak cancelTimerWithName:timerName];
            }
        });
        
    }
    else if (option == MergePreviousTimerAction) // 合并上一次timer任务
    {
        // 缓存本次timer任务
        [self cacheAction:action forTimer:timerName];
        
        // 时间间隔到点时执行block
        dispatch_source_set_event_handler(timer, ^{
            
            NSMutableArray *actionArray = [self.timerActionBlockCacheArry objectForKey:timerName];
            
            [actionArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                dispatch_block_t actionBlock = obj;
                actionBlock();
            }];
            
            [selfWeak removeActionCacheForTimer:timerName];
            
            if (!repeats) {
                [selfWeak cancelTimerWithName:timerName];
            }
        });
    }
}

// 取消timer
- (void)cancelTimerWithName:(NSString *)timerName
{
    dispatch_source_t timer = [self.timerArry objectForKey:timerName];
    
    if (!timer)
        return;
    
    [self.timerArry removeObjectForKey:timerName];
    [self.timerActionBlockCacheArry removeObjectForKey:timerName];
    dispatch_source_cancel(timer);
}

#pragma mark - getter & setter
- (NSMutableDictionary *)timerArry
{
    if (!_timerArry) {
        _timerArry = [[NSMutableDictionary alloc] init];
    }
    return _timerArry;
}

- (NSMutableDictionary *)timerActionBlockCacheArry
{
    if (!_timerActionBlockCacheArry) {
        _timerActionBlockCacheArry = [[NSMutableDictionary alloc] init];
    }
    return _timerActionBlockCacheArry;
}

#pragma mark - private method
- (void)cacheAction:(dispatch_block_t)action forTimer:(NSString *)timerName
{
    id actionArray = [self.timerActionBlockCacheArry objectForKey:timerName];
    
    if (actionArray && [actionArray isKindOfClass:[NSMutableArray class]])
    {
        [(NSMutableArray *)actionArray addObject:action];
    }
    else
    {
        NSMutableArray *array = [NSMutableArray arrayWithObject:action];
        [self.timerActionBlockCacheArry setObject:array forKey:timerName];
    }
}

- (void)removeActionCacheForTimer:(NSString *)timerName
{
    if (![self.timerActionBlockCacheArry objectForKey:timerName])
        return;
    
    [self.timerActionBlockCacheArry removeObjectForKey:timerName];
}

@end
