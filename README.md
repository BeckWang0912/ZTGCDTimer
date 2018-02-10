# [GCD](http://www.cnblogs.com/beckwang0912/p/7027484.html)[实现定时器NSTimer](http://www.cnblogs.com/beckwang0912/p/7027484.html)


定时器在我们每个人做的iOS项目里面必不可少，如登录页面倒计时、支付期限倒计时等等，一般来说使用NSTimer创建定时器：

```Objective-C
+ (NSTimer *)timerWithTimeInterval:(NSTimeInterval)ti target:(id)aTarget selector:(SEL)aSelector userInfo:(nullable id)userInfo repeats:(BOOL)yesOrNo;

+ (NSTimer *)scheduledTimerWithTimeInterval:(NSTimeInterval)ti target:(id)aTarget selector:(SEL)aSelector userInfo:(nullable id)userInfo repeats:(BOOL)yesOrNo;
```

>But使用NSTimer需要注意一下几点：

#### 1、**必须保证有一个活跃的RunLoop**

系统框架提供了几种创建NSTimer的方法，其中以scheduled开头的方法会自动把timer加入当前RunLoop，到了设定时间就会触发selector方法，而没有scheduled开头的方法则需要手动添加timer到一个RunLoop中才会有效。

程序启动时，会默认启动主线程的RunLoop并在程序运行期内有效，所以把timer放入主线程时不需要启动RunLoop，但现实开发中主线程更多的是处理UI事物，把耗时且耗能的操作放在子线程中，这就需要将子线程的RunLoop激活。

RunLoop在运行时一般有两个:NSDefaultRunLoopMode、NSEventTrackingRunLoopMode，scheduled生成的timer会默认添加到NSDefaultRunLoopMode，当某些UI事件发生时，如页面滑动RunLoop切换到NSEventTrackingRunLoopMode运行，我们会发现定时器失效，为了解决timer失效的问题，我们需要在scheduled一个定时器的时候，设置它的运行模式为：

```Objective-C
[[NSRunLoop currentRunLoop] addTimer:self.progressTimer forMode:NSRunLoopCommonModes];
```

注意：NSRunLoopCommonModes并不是一种正在存在的运行状态，这个模式等效于NSDefaultRunLoopMode和NSEventTrackingRunLoopMode的结合，相当于它标记了timer可以在这两种模式下都有效。

有时app进入后台后，timer也会发生失效，设置如下就能解决问题：

```Objective-C
[[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil];
```

#### 2、**NSTimer的创建与撤销必须在同一个线程操作，不能跨越线程操作**

#### 3、**存在内存泄漏的风险。**

scheduledTimerWithTimeInterval方法将target设为A对象时，A对象会被这个timer所持有，也就是会被retain一次，timer又会被当前的runloop所持有。使用NSTimer时，timer会保持对target和userInfo参数的强引用。只有当调取了NSTimer的invalidate方法时，NSTimer才会释放target和userInfo。生成timer的方法中如果repeats参数为NO，则定时器触发后会自动调取invalidate方法。如果repeats参数为YES，则需要手动调取invalidate方法才能释放timer对target和userIfo的\`强引用\`

```Objective-C
- (void)cancel{
      [_timer invalidate];
      _timer = nil;
}
```

这里要特别注意的一点是，很多人喜欢在析构函数（dealloc）中调用timer失效，如：

```Objective-C
- (void)dealloc{
      [self cancel];
}
```

以为这样就可以释放timer了，不幸的是，dealloc方法永远不会被调用。因为timer的引用，对象A的引用计数永远不会降到0，这时如果不调用cancel，对象X将永远无法释放，造成内存泄露。

所以建议在使用定时器的事件完成后立即将timer进行cancel，如果是比较长时间的定时器，可以在页面消失事件中调用，如：

```Objective-C
- (void)viewWillDisappear:(BOOL)animated{
       [super viewWillDisappear:animated];
       [self cancel];
}
```

看到这里，你会不会发现使用NSTimer实现定时器这么麻烦，又是RunLoop，又是线程的，一会儿还得考虑内存泄露，So , 如果在一个页面需要同时显示多个计时器的时候，NSTimer简直就是灾难了。那么有没有高逼格的办法实现呢？答案就是`GCD`!

以下5点是使用dispatch_source_t创建timer的主要知识点：

* **获取全局子线程队列**

```Objective-C
dispatch_queue_t queue ＝ dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
```

* **创建timer添加到队列中**

```Objective-C
dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
```

* **设置首次执行事件、执行间隔和精确度**

```Objective-C
dispatch_source_set_timer(timer, dispatch_time(DISPATCH_TIME_NOW, interval * NSEC_PER_SEC), interval * NSEC_PER_SEC, 0.1 * NSEC_PER_SEC);
```

* **处理事件block**

```Objective-C
dispatch_source_set_event_handler(timer, ^{
// doSomething()
});
```

* **激活timer ／ 取消timer**

```Objective-C
dispatch_resume(timer);

dispatch_source_cancel(timer);
```

写到这里，自然要问如果我只是想执行一次，不需要循环实现定时器那怎么办呢？那也没问题，参考NSTimer,我们可以集成repeats选项，当repeats = No时，在激活timer并回调block事件后dispatch_source_cancel掉当前dispatch_source_t timer即可，如下所示：

```Objective-C
// 创建gcd timer
- (void)scheduledDispatchTimerWithName:(NSString *)timerName
                                       timeInterval:(double)interval
                                       queue:(dispatch_queue_t)queue
                                       repeats:(BOOL)repeats
                                       actionOption:(ActionOption)option
                                       action:(dispatch_block_t)action{
                                          // 具体代码请查阅demo
                                       }

// 撤销指定timer
- (void)cancelTimerWithName:(NSString *)timerName{
        // 具体代码请查阅demo
}
```

上面的代码就创建了一个timer，如果repeats ＝ NO，在一个周期完成后，系统会自动cancel掉这个timer；如果repeats=YES，那么timer会一个周期接一个周期的执行，直到你手动cancel掉这个timer，你可以在dealloc方法里面做cancel，这样timer恰好运行于整个对象的生命周期中。这里不必要担心NSTimer因dealloc始终无法调而产生的内存泄漏问题，你也可以通过queue参数控制这个timer所添加到的线程，也就是action最终执行的线程。传入nil则会默认放到子线程中执行。UI相关的操作需要传入dispatch\_get\_main\_queue\(\)以放到主线程中执行。

单个定时器效果：

![image](https://github.com/BeckWang0912/ZTGCDTimer/blob/master/ZTGCDTimer/singleTimer.png)

写到这里，基本上可以满足开发要求，然而我们可以更加变态，假设这样的场景，每次开始新一次的计时前，需要取消掉上一次的计时任务 或者 将上一次计时的任务，合并到新的一次计时中，最终一并执行！针对这两种场景，也已经集成到上面的接口scheduleGCDTimerWithName中。具体代码请看demo！

多个定时器效果图：

![image](https://github.com/BeckWang0912/ZTGCDTimer/blob/master/ZTGCDTimer/mutiTimer.png)

github地址：[https://github.com/BeckWang0912/ZTGCDTimer](https://github.com/BeckWang0912/ZTGCDTimer) 如果文章对您有帮助的话，请star，谢谢！
