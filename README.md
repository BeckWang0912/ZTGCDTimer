# ZTGCDTimer

定时器在我们每个人做的iOS项目里面必不可少，如登录页面倒计时、支付期限倒计时等等，一般来说使用NSTimer创建定时器：
+ (NSTimer *)timerWithTimeInterval:(NSTimeInterval)ti target:(id)aTarget selector:(SEL)aSelector userInfo:(nullable id)userInfo repeats:(BOOL)yesOrNo;
+ (NSTimer *)scheduledTimerWithTimeInterval:(NSTimeInterval)ti target:(id)aTarget selector:(SEL)aSelector userInfo:(nullable id)userInfo repeats:(BOOL)yesOrNo;

But 使用NSTimer需要注意一下几点：
    1、必须保证有一个活跃的RunLoop。
      系统框架提供了几种创建NSTimer的方法，其中以scheduled开头的方法会自动把timer加入当前RunLoop，到了设定时间就会触发selector方法，而没有scheduled开头的方法则需要手动添加timer到一个RunLoop中才会有效。程序启动时，会默认启动主线程的RunLoop并在程序运行期内有效，所以把timer放入主线程时不需要启动RunLoop，但现实开发中主线程更多的是处理UI事物，把耗时且耗能的操作放在子线程中，这就需要将子线程的RunLoop激活。
      我们不难知道RunLoop在运行时一般有两个:NSDefaultRunLoopMode、NSEventTrackingRunLoopMode，scheduled生成的timer会默认添加到NSDefaultRunLoopMode，当某些UI事件发生时，如页面滑动RunLoop切换到NSEventTrackingRunLoopMode运行，我们会发现定时器失效，为了解决timer失效的问题，我们需要在scheduled一个定时器的时候，设置它的运行模式为：
     
     [[NSRunLoop currentRunLoop] addTimer:self.progressTimer forMode:NSRunLoopCommonModes];

     注意：NSRunLoopCommonModes并不是一种正在存在的运行状态，这个模式等效于NSDefaultRunLoopMode和NSEventTrackingRunLoopMode的结合，相当于它标记了timer可以在这两种模式下都有效。

     2.NSTimer的创建与撤销必须在同一个线程操作，不能跨越线程操作。

     3.存在内存泄漏的风险（这个问题需要引起重视）

     scheduledTimerWithTimeInterval方法将target设为A对象时，A对象会被这个timer所持有，也就是会被retain一次，timer又会被当前的runloop所持有。使用NSTimer时，timer会保持对target和userInfo参数的强引用。只有当调取了NSTimer的invalidate方法时，NSTimer才会释放target和userInfo。生成timer的方法中如果repeats参数为NO，则定时器触发后会自动调取invalidate方法。如果repeats参数为YES，则需要手动调取invalidate方法才能释放timer对target和userIfo的强引用。

    - (void)cancel{
          [_timer invalidate];
           _timer = nil;
     }

    这里要特别注意的一点是，按照各种资料显示，我们在销毁或者释放对象时，大部分都是在dealloc方法中，然后我们高高兴兴的在dealloc里写上
  
   - (void)dealloc{
         [self cancel];
    }

   以为这样就可以释放timer了，不幸的是，dealloc方法永远不会被调用。因为timer的引用，对象A的引用计数永远不会降到0，这时如果不调用cancel，对象X将永远无法释放，造成内存泄露。所以我建议在使用定时器的事件完成后立即将timer进行cancel，如果是比较长时间的定时器，可以在页面消失事件中调用，如：

   - (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self cancel];
   }

   看到这里，你会不会发现使用NSTimer实现定时器这么麻烦，又是RunLoop，又是线程的，一会儿还得考虑内存泄露，So , 如果在一个页面需要同时显示多个计时器的时候，NSTimer简直就是灾难了。那么有没有高逼格的办法实现呢？答案就是GCD!  以下5点是使用dispatch_source_t创建timer的主要知识点：

   1.获取全局子线程队列 

      dispatch_queue_t  queue ＝ dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

   2.创建timer添加到队列中

      dispatch_source_t  timer =  dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);

    3.设置首次执行事件、执行间隔和精确度

      dispatch_source_set_timer(timer, dispatch_time(DISPATCH_TIME_NOW, interval * NSEC_PER_SEC), interval * NSEC_PER_SEC, 0.1 * NSEC_PER_SEC);

   4.处理事件block

    dispatch_source_set_event_handler(timer, ^{
            // doSomething()
    });

    5.激活timer ／ 取消timer

    dispatch_resume(timer);   ／    dispatch_source_cancel(timer);

demo代码中支撑repeats选项，类似NSTimer的repeats，当repeats = No时，在激活timer并回调block事件后dispatch_source_cancel掉当前dispatch_source_t  timer即可，如果repeats=YES，那么timer会一个周期接一个周期的执行，直到你手动cancel掉这个timer，你可以在dealloc方法里面做cancel，这样timer恰好运行于整个对象的生命周期中。这里不必要担心NSTimer因dealloc始终无法调而产生的内存泄漏问题，
你也可以通过queue参数控制这个timer所添加到的线程，也就是action最终执行的线程。传入nil则会默认放到子线程中执行。UI相关的操作需要传入dispatch_get_main_queue()以放到主线程中执行。

写到这里，基本上可以满足开发要求，然而我们可以更加变态，假设这样的场景，每次开始新一次的计时前，需要取消掉上一次的计时任务 或者 将上一次计时的任务，合并到新的一次计时中，最终一并执行！针对这两种场景，也已经集成到上面的接口scheduleGCDTimerWithName中。具体代码请看demo！

博客地址：http://www.cnblogs.com/beckwang0912/p/7027484.html

 
