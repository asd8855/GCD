//
//  ViewController.m
//  GCD
//
//  Created by libo on 2017/1/19.
//  Copyright © 2017年 蝉鸣. All rights reserved.
//

//在实际开发中如何使用GCD更好的实现我们的需求
/*
    Synchronous(同步) Asynchronous(异步)
    Serial Queues(串行) Concurrent Queues(并发)
    Global Queues(全局队列)
    Main Queue(主队列)
    同步的作用
    dispatch_time延迟操作
    线程安全(单例dispatch_once、读写dispatch_barrier_async)
    dispatch_group(调度组)
 */

//我们为什么要用GCD技术
/*
 GCD 能通过推迟昂贵计算任务并在后台运行它们来改善你的应用的响应性能。
 GCD 提供一个易于使用的并发模型而不仅仅只是锁和线程，以帮助我们避开并发陷阱。
 GCD 具有在常见模式（例如单例）上用更高性能的原语优化你的代码的潜在能力。
 GCD旨在替换NSThread等线程技术
 GCD可充分利用设备的多核
 GCD可自动管理线程的生命周期
 */

//开发中常用到的有
/*
    异步
    串行队列异步任务 应用场景:耗时间，有顺序的任务 1.登录--->2.付费--->3.才能看
    并发队列异步任务 应用场景:同时下载多个电影
    全局队列异步任务 应用场景:蜻蜓FM同时下载多个声音
    主队列异步任务  应用场景:当做了耗时操作之后,我们需要回到主线程更新UI的时候,就非它不可
    同步队列异步任务 应用场景:<保证我们任务执行的先后顺序> 1.登录 2.同时下载三部电影
 
    dispatch_group(调度组) 应用场景:比如同时开了是哪个线程下载视频,只有当三个视频完全下载完毕后,我才能做后续的事。这个就需要用到调度组,这个调度组,就能监听它里面的任务是否都执行完毕
 */

#import "ViewController.h"

@interface ViewController ()
@property (nonatomic) NSInteger count;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.count = 0;
}

#pragma mark -- Synchronous & Asynchronous 同步 & 异步
#pragma mark -- 同步方法
//1.同步任务执行方式：在当前线程中执行,必须等待当前语句执行完毕，才会执行下一条语句
//一个执行完才能执行另外一个
- (void) syncTask {
    NSLog(@"begin");
    //1.GCD同步方法
    /*
     参数1: 队列 第一个参数0其实为队列优先级DISPATCH_QUEUE_PRIORITY_DEFAULT，如果要适配 iOS 7.0 & 8.0，则始终为0
     参数2: 任务
     */
    dispatch_sync(dispatch_get_global_queue(0, 0), ^{
        //任务重要执行的代码
        NSLog(@"%@",[NSThread currentThread]);
    });
    NSLog(@"end");
}

#pragma mark -- 异步方法
//2.异步任务执行方式：不在当前线程中执行,不用等待当前语句执行完毕，就可以执行下一条语句
//多个任务同时执行
/**
 异步的打印顺序
 打印 begin
 打印 一般情况下为end，极少数情况下会很快开辟完新的线程，先打印出[NSThread currentThread]
 */
- (void)asyncTask {

    /**
     异步：不会在“当前线程”执行，会首先去开辟新的子线程，开辟线程需要花费时间
     */
    NSLog(@"begin");
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSLog(@"%@",[NSThread currentThread]);
        
    });
    NSLog(@"end");
}

#pragma mark -- Serial Queues & Concurrent Queues 串行 & 并发


//1.串行队列调度同步和异步任务执行
/*
 串行队列特点:
    以先进先出的方式,顺序调度队列中的任务执行
    无论队列中所指定的执行任务函数时同步还是异步,都会等待前一个任务执行完成后,在调度后面的任务
 */

#pragma mark -- 串行队列同步方法
/**
 串行队列，同步方法
 1.打印顺序 : 从上到下，依次打印，因为是串行的
 2.在哪条线程上执行 : 主线程，因为是同步方法，所以在当前线程里面执行，恰好当前线程是主线程，所以它就在主线程上面执行
 
 应用场景：开发中很少用
 */
- (void)serialSync {
    // 1.创建一个串行队列
    /**
     参数1:队列的表示符号，一般是公司的域名倒写
     参数2:队列的类型
     DISPATCH_QUEUE_SERIAL 串行队列
     DISPATCH_QUEUE_CONCURRENT 并发队列
     */
    dispatch_queue_t serialQueue = dispatch_queue_create("com.baidu", DISPATCH_QUEUE_SERIAL);
    
    //创建任务
    void (^task1) () = ^ {
        NSLog(@"task1---%@",[NSThread currentThread]);
    };
    void (^task2) () = ^ {
        NSLog(@"task2---%@",[NSThread currentThread]);
    };
    void (^task3) () = ^ {
        NSLog(@"task3---%@",[NSThread currentThread]);
    };
    //添加任务到队列,同步方法执行
    dispatch_sync(serialQueue, task1);
    dispatch_sync(serialQueue, task2);
    dispatch_sync(serialQueue, task3);
}

#pragma mark -- 串行队列异步方法
/**
 串行队列，异步方法
 1.打印顺序：从上到下，依次执行，它是串行队列
 2.在哪条线程上执行：在子线程，因为它是异步执行，异步就是不在当前线程里面执行
 
 应用场景：耗时间，有顺序的任务
 1.登录--->2.付费--->3.才能看
 
 */
- (void)serialAsync {

    //1.创建一个串行队列
    dispatch_queue_t serialQueue = dispatch_queue_create("com.baidu", DISPATCH_QUEUE_SERIAL);
    //创建任务
    void (^task1) () = ^ {
        NSLog(@"task1---%@",[NSThread currentThread]);
    };
    void (^task2) () = ^ {
        NSLog(@"task2---%@",[NSThread currentThread]);
    };
    void (^task3) () = ^ {
        NSLog(@"task3---%@",[NSThread currentThread]);
    };
    
    dispatch_async(serialQueue, task1);
    dispatch_async(serialQueue, task2);
    dispatch_async(serialQueue, task3);
}

#pragma mark -- 并发队列调度异步任务执行
/*
 并发队列特点：
 　　以先进先出的方式，并发调度队列中的任务执行
 　　如果当前调度的任务是同步执行的，会等待任务执行完成后，再调度后续的任务
 　　如果当前调度的任务是异步执行的，同时底层线程池有可用的线程资源，会再新的线程调度后续任务的执行
 */

#pragma mark -- 并发队列同步任务
/**
 并发队列，同步任务
 1.打印顺序：因为是同步,所以依次执行
 2.在哪条线程上执行：主线程，因为它是同步方法，它就在当前线程里面执行，也就是在主线程里面依次执行
 
 当并发队列遇到同步的时候还是依次执行，所以说方法(同步/异步)的优先级会比队列的优先级高
 
 * 只要是同步方法，都只会在当前线程里面执行，不会开子线程
 
 应用场景：
 开发中几乎不用
 
 */

- (void)concurrentSync {
    
    /**
     参数1:队列的表示符号，一般是公司的域名倒写
     参数2:队列的类型
     DISPATCH_QUEUE_SERIAL 串行队列
     DISPATCH_QUEUE_CONCURRENT 并发队列
     */
    
    //1.创建并发队列
    dispatch_queue_t concurrentSync = dispatch_queue_create("com.baidu", DISPATCH_QUEUE_CONCURRENT);
    //创建任务
    void (^task1) () = ^ {
        NSLog(@"task1---%@",[NSThread currentThread]);
    };
    void (^task2) () = ^ {
        NSLog(@"task2---%@",[NSThread currentThread]);
    };
    void (^task3) () = ^ {
        NSLog(@"task3---%@",[NSThread currentThread]);
    };
    
    //3.添加任务到并发队列
    dispatch_sync(concurrentSync, task1);
    dispatch_sync(concurrentSync, task2);
    dispatch_sync(concurrentSync, task3);
}

#pragma mark -- 并发队列异步任务
/**
 1.打印顺序：无序的
 2.在哪条线程上执行：在子线程上执行，每一个任务都在它自己的线程上执行
 可以创建N条子线程，它是由底层可调度线程池来决定的，可调度线程池它是有一个重用机制
 
 应用场景
 同时下载多个影片
 */
- (void)concurrentAsync {

    //1.创建并发队列
    dispatch_queue_t concurrentAsync = dispatch_queue_create("com.baidu", DISPATCH_QUEUE_CONCURRENT);
    //2.创建任务
    void (^task1) () = ^ {
        NSLog(@"task1---%@",[NSThread currentThread]);
    };
    void (^task2) () = ^ {
        NSLog(@"task2---%@",[NSThread currentThread]);
    };
    void (^task3) () = ^ {
        NSLog(@"task3---%@",[NSThread currentThread]);
    };
    
    //3.将任务添加到并发队列
    dispatch_sync(concurrentAsync, task1);
    dispatch_sync(concurrentAsync, task2);
    dispatch_sync(concurrentAsync, task3);
}

#pragma mark -- 全局队列
//全局队列是系统为了方便程序员开发提供的，其工作表现与并发队列一致
/*
 全局队列 & 并发队列的区别
 
 　　全局队列：没有名称，无论 MRC & ARC 都不需要考虑释放，日常开发中，建议使用"全局队列"
 　　并发队列：有名字，和 NSThread 的 name 属性作用类似，如果在 MRC 开发时，需要使用 dispatch_release(q); 释放相应的对象
 　　dispatch_barrier 必须使用自定义的并发队列
 　　开发第三方框架时，建议使用并发队列
 */

/*
 参数
 　　参数1：服务质量(队列对任务调度的优先级)/iOS 7.0 之前，是优先级
 
 iOS 8.0(新增，暂时不能用，今年年底)
 QOS_CLASS_USER_INTERACTIVE 0x21, 用户交互(希望最快完成－不能用太耗时的操作)
 QOS_CLASS_USER_INITIATED 0x19, 用户期望(希望快，也不能太耗时)
 QOS_CLASS_DEFAULT 0x15, 默认(用来底层重置队列使用的，不是给程序员用的)
 QOS_CLASS_UTILITY 0x11, 实用工具(专门用来处理耗时操作！)
 QOS_CLASS_BACKGROUND 0x09, 后台
 QOS_CLASS_UNSPECIFIED 0x00, 未指定，可以和iOS 7.0 适配
 iOS 7.0
 DISPATCH_QUEUE_PRIORITY_HIGH 2 高优先级
 DISPATCH_QUEUE_PRIORITY_DEFAULT 0 默认优先级
 DISPATCH_QUEUE_PRIORITY_LOW (-2) 低优先级
 DISPATCH_QUEUE_PRIORITY_BACKGROUND INT16_MIN 后台优先级
 
 　　参数2：为未来保留使用的，应该永远传入0
 
 　　结论：如果要适配 iOS 7.0 & 8.0，使用以下代码： dispatch_get_global_queue(0, 0);
 */

#pragma mark -- 全局队列同步任务
/**
 全局队列，同步任务
 1.打印顺序：依次执行，因为它是同步的
 2.在哪条线程上执行:主线程，因为它是同步方法，它就在当前线程里面执行
 
 当它遇到同步的时候，并发队列还是依次执行，所以说，方法的优先级比队列的优先级高
 
 * 只要是同步方法，都只会在当前线程里面执行，不会开子线程
 
 应用场景：开发中几乎不用
 */
- (void)globalSync {

    /**
     参数1：
     IOS7:表示的优先级
     IOS8:服务质量
     为了保证兼容IOS7&IOS8一般传入0
     
     参数2:未来使用，传入0
     */
    NSLog(@"begin");
    //1.创建全局队列
    dispatch_queue_t globalQueue =  dispatch_get_global_queue(0, 0);
    //2.创建任务
    void (^task1) () = ^ {
        NSLog(@"task1---%@",[NSThread currentThread]);
    };
    void (^task2) () = ^ {
        NSLog(@"task2---%@",[NSThread currentThread]);
    };
    void (^task3) () = ^ {
        NSLog(@"task3---%@",[NSThread currentThread]);
    };
    
    //3.添加任务到全局队列
    dispatch_sync(globalQueue, task1);
    dispatch_sync(globalQueue, task2);
    dispatch_sync(globalQueue, task3);
    NSLog(@"end");
}

#pragma mark -- 全局队列异步任务
/**
 全局队列，异步方法
 1.打印顺序:无序的
 2.在子线程上执行，每一个任务都在它自己的线程上执行，线程数由底层可调度线程池来决定的，可调度线程池有一个重用机制
 应用场景：
 蜻蜓FM同时下载多个声音
 */
- (void)globalAsync {
    NSLog(@"begin");
    //1.创建全局队列
    dispatch_queue_t globalQueue =  dispatch_get_global_queue(0, 0);
    //2.创建任务
    void (^task1) () = ^ {
        NSLog(@"task1---%@",[NSThread currentThread]);
    };
    void (^task2) () = ^ {
        NSLog(@"task2---%@",[NSThread currentThread]);
    };
    void (^task3) () = ^ {
        NSLog(@"task3---%@",[NSThread currentThread]);
    };
    //3.添加到队列
    dispatch_async(globalQueue, task1);
    dispatch_async(globalQueue, task2);
    dispatch_async(globalQueue, task3);
    NSLog(@"end");
}


#pragma mark -- 主队列
/*
 特点
 　　专门用来在主线程上调度任务的队列
 　　不会开启线程
 　　以先进先出的方式，在主线程空闲时才会调度队列中的任务在主线程执行
 　　如果当前主线程正在有任务执行，那么无论主队列中当前被添加了什么任务，都不会被调度
 
 队列获取
 　　主队列是负责在主线程调度任务的
 　　会随着程序启动一起创建
 　　主队列只需要获取不用创建
 */
#pragma mark -- 主队列异步任务
/**
 主队列，异步任务
 1.执行顺序:依次执行，因为它在主线程里面执行
 * 似乎与我们的异步任务有所冲突，但是因为它是主队列，所以，只在主线程里面执行
 
 2.是否会开线程：不会，因为它在主线程里面执行
 
 应用场景：
 当做了耗时操作之后，我们需要回到主线程更新UI的时候，就非它不可
 */
- (void)mainAsync {

    NSLog(@"begin");
    //1.创建全局队列
    dispatch_queue_t mainAsync = dispatch_get_main_queue();
    //2.创建任务
    void (^task1) () = ^ {
        NSLog(@"task1---%@",[NSThread currentThread]);
    };
    void (^task2) () = ^ {
        NSLog(@"task2---%@",[NSThread currentThread]);
    };
    void (^task3) () = ^ {
        NSLog(@"task3---%@",[NSThread currentThread]);
    };
    //3.添加到队列
    dispatch_async(mainAsync, task1);
    dispatch_async(mainAsync, task2);
    dispatch_async(mainAsync, task3);
    NSLog(@"end");
}

#pragma mark -- 主队列同步方法有问题,不能用是个奇葩,会造成死锁
/**
 主队列，同步任务有问题，不能用，彼此都在等对方是否执行完了，所以是互相死等
 主队列只有在主线程空闲的时候，才会去调度它里面的任务去执行
 */
- (void)mainSync {

    NSLog(@"begin");
    //1.创建全局队列
    dispatch_queue_t mainSync = dispatch_get_main_queue();
    //2.创建任务
    void (^task1) () = ^ {
        NSLog(@"task1---%@",[NSThread currentThread]);
    };
    void (^task2) () = ^ {
        NSLog(@"task2---%@",[NSThread currentThread]);
    };
    void (^task3) () = ^ {
        NSLog(@"task3---%@",[NSThread currentThread]);
    };
    //3.添加到队列
    dispatch_sync(mainSync, task1);
    dispatch_sync(mainSync, task2);
    dispatch_sync(mainSync, task3);
    NSLog(@"end");
}

#pragma mark -- Deadlock 死锁
/*
 　　两个（有时更多）东西——在大多数情况下，是线程——所谓的死锁是指它们都卡住了，并等待对方完成或执行其它操作。第一个不能完成是因为它在等待第二个的完成。但第二个也不能完成，因为它在等待第一个的完成。
 */

#pragma mark -- 同步的作用
/*
 同步任务,可以让其他异步执行的任务,依赖某一个同步任务,例如:在用户登录之后,才允许异步下载文件！
 */
//模拟登录下载多个电影数据
/**
 同步的作用：保证我们任务执行的先后顺序
 1.登录
 
 2.同时下载三部电影
 */
- (void)loadManyMovie {

    dispatch_async(dispatch_get_global_queue(0, 0), ^{
       
        NSLog(@"还没登录呢---%@",[NSThread currentThread]);
        
        //1.登录
        dispatch_sync(dispatch_get_global_queue(0, 0), ^{
            NSLog(@"登录了---%@",[NSThread currentThread]);
            sleep(3);
        });
        
        //2.同时下载三部电影
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            NSLog(@"正在下载第一个电影---%@",[NSThread currentThread]);
        });
        
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            NSLog(@"正在下载第二个电影---%@",[NSThread currentThread]);
        });
        
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            NSLog(@"正在下载第三个电影---%@",[NSThread currentThread]);
        });
        
        dispatch_sync(dispatch_get_main_queue(), ^{
           
            [NSThread sleepForTimeInterval:1.0];
            NSLog(@"计算机将在三秒后关闭---%@",[NSThread currentThread]);
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                NSLog(@"关机了 ---%@",[NSThread currentThread]);
            });
        });
    });
}

#pragma mark -- dispatch_time 延迟操作
/*
 不知道何时适合使用 dispatch_after ？
 
 自定义串行队列：在一个自定义串行队列上使用 dispatch_after 要小心。你最好坚持使用主队列。
 主队列（串行）：是使用 dispatch_after 的好选择；Xcode 提供了一个不错的自动完成模版。
 并发队列：在并发队列上使用 dispatch_after 也要小心；你会这样做就比较罕见。还是在主队列做这些操作吧。
 */

#pragma mark -- 延迟执行
- (void)delay {

    /**
     从现在开始，经过多少纳秒，由"队列"调度异步执行 block 中的代码
     
     参数
     1. when    从现在开始，经过多少纳秒
     2. queue   队列
     3. block   异步执行的任务
     */
    dispatch_time_t when = dispatch_time(DISPATCH_TIME_NOW, (int64_t) (2.0 * NSEC_PER_SEC));
    void (^task)()= ^ {
        NSLog(@"%@",[NSThread currentThread]);
    };
    
    //主队列
//    dispatch_after(when, dispatch_get_main_queue(), task);
//    //全局队列
//    dispatch_after(when, dispatch_get_global_queue(0, 0), task);
    //串行队列
    dispatch_after(when, dispatch_queue_create("com.baidu", NULL), task);
    NSLog(@"come here");
}

- (void)after {
    [self.view performSelector:@selector(setBackgroundColor:) withObject:[UIColor orangeColor] afterDelay:1.0];
    NSLog(@"come here");
}


#pragma mark -- 线程安全(单例 dispatcg_once、读写dispatch_barrier_async)
/*
 一个常见的担忧是它们常常不是线程安全的。这个担忧十分合理，基于它们的用途：单例常常被多个控制器同时访问。
 
 　　单例的线程担忧范围从初始化开始，到信息的读和写。
 
 　　dispatch_once() 以线程安全的方式执行且仅执行其代码块一次。试图访问临界区（即传递给 dispatch_once 的代码）的不同的线程会在临界区已有一个线程的情况下被阻塞，直到临界区完成为止。
 */
#pragma mark -- 使用 dispatch_once 实现单例
+ (instancetype)sharedSingleton {

    static id instance;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    
    return instance;
}
/*
 线程安全实例不是处理单例时的唯一问题。如果单例属性表示一个可变对象，那么你就需要考虑是否那个对象自身线程安全。
 
 　　如果问题中的这个对象是一个 Foundation 容器类，那么答案是——“很可能不安全”！Apple 维护一个有用且有些心寒的列表，众多的 Foundation 类都不是线程安全的。如：NSMutableArray。
 
 　　虽然许多线程可以同时读取 NSMutableArray 的一个实例而不会产生问题，但当一个线程正在读取时让另外一个线程修改数组就是不安全的。在目前的状况下不能预防这种情况的发生。GCD 通过用 dispatch barriers 创建一个读者写者锁，提供了一个优雅的解决方案。
 */

#pragma mark -- dispatch_group(调度组)
#pragma mark -- 调度组
/**
 调度组的实现原理:类似引用计数器进行+1和-1的操作
 应用场景
 比如同时开了三个线程下载视频，只有当三个视频完全下载完毕后，我才能做后续的事
 这个就需要用到调度组，这个调度组，就能监听它里面的任务是否都执行完毕
 */
- (void)groupDispatch {

    //1.创建调度组
    dispatch_group_t group = dispatch_group_create();
    //2.获取全局队列
    dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
    //3.创建三个下载任务
    void (^task1)() = ^(){
        NSLog(@"下载片头---%@",[NSThread currentThread]);
    };
    
    dispatch_group_enter(group);//引用计数 +1
    void (^task2)() = ^(){
        NSLog(@"下载中间的内容---%@",[NSThread currentThread]);
        
        [NSThread sleepForTimeInterval:3.0];
        
        NSLog(@"--下载中间内容完毕--");
        dispatch_group_leave(group);//引用计数 -1
    };
    
    dispatch_group_enter(group);//引用计数 +1
    void(^task3)() = ^(){
        NSLog(@"下载片尾---%@",[NSThread currentThread]);
        dispatch_group_leave(group); //引用计数 -1
    };
    
    //4.需要将我们的队列和任务,加入到组内去监控
    dispatch_group_async(group, queue, task1);
    dispatch_group_async(group, queue, task2);
    dispatch_group_async(group, queue, task3);

    //5.监听的函数
    /**
     远离：来监听当调度组的引用计数器为0时，才会执行该函数中内容,否则不会执行
     参数1：组
     参数2：决定了参数3在哪个线程里面执行
     参数3：组内完全下载完毕后需要执行的代码
     */
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
       //表示组内的所有内容全部下载完成后会来到这里
        NSLog(@"把下好的视频按照顺序拼接好,然后显示在UI去播放%@",[NSThread currentThread]);
    });
}
/*
 1.因为你在使用的是同步的 dispatch_group_wait ，它会阻塞当前线程，所以你要用 dispatch_async 将整个方法放入后台队列以避免阻塞主线程。
 
 2.创建一个新的 Dispatch Group，它的作用就像一个用于未完成任务的计数器。
 3.dispatch_group_enter 手动通知 Dispatch Group 任务已经开始。你必须保证 dispatch_group_enter 和 dispatch_group_leave 成对出现，否则你可能会遇到诡异的崩溃问题。
 4.手动通知 Group 它的工作已经完成。再次说明，你必须要确保进入 Group 的次数和离开 Group 的次数相等。
 5.dispatch_group_wait 会一直等待，直到任务全部完成或者超时。如果在所有任务完成前超时了，该函数会返回一个非零值。你可以对此返回值做条件判断以确定是否超出等待周期；然而，你在这里用 DISPATCH_TIME_FOREVER 让它永远等待。它的意思，勿庸置疑就是，永－远－等－待！这样很好，因为图片的创建工作总是会完成的。
 6.此时此刻，你已经确保了，要么所有的图片任务都已完成，要么发生了超时。然后，你在主线程上运行 completionBlock 回调。这会将工作放到主线程上，并在稍后执行。
 7.最后，检查 completionBlock 是否为 nil，如果不是，那就运行它。
 编译并运行你的应用，尝试下载多个图片，观察你的应用是在何时运行 completionBlock 的。
 
 注意：如果你是在真机上运行应用，而且网络活动发生得太快以致难以观察 completionBlock 被调用的时刻，那么你可以在 Settings 应用里的开发者相关部分里打开一些网络设置，以确保代码按照我们所期望的那样工作。只需去往 Network Link Conditioner 区，开启它，再选择一个 Profile，“Very Bad Network” 就不错。
 如果你是在模拟器里运行应用，你可以使用 来自 GitHub 的 Network Link Conditioner 来改变网络速度。它会成为你工具箱中的一个好工具，因为它强制你研究你的应用在连接速度并非最佳的情况下会变成什么样。
 */

#pragma mark -- 定时源时间和子线程的运行循环
//- (void)viewDidLoad {
//    [super viewDidLoad];
//    
//    NSTimer *timer = [NSTimer timerWithTimeInterval:1.0 target:self selector:@selector(timeEvent) userInfo:nil repeats:YES];
//    
//    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
//    
//}

- (void)createTimer {

    NSTimer *timer = [NSTimer timerWithTimeInterval:1.0 target:self selector:@selector(timeEvent) userInfo:nil repeats:YES];
    
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self performSelectorInBackground:@selector(subThreadRun) withObject:nil];
}

#pragma mark
#pragma mark - 子线程的运行循环
- (void)subThreadRun {
    
    NSLog(@"%@----%s", [NSThread currentThread], __func__);
    
    // 1.定义一个定时器
    NSTimer *timer = [NSTimer timerWithTimeInterval:1.0 target:self selector:@selector(timeEvent) userInfo:nil repeats:YES];
    
    // 2.将我们的定时器加入到运行循环，只有加入到当前的运行循环里面去，他才知道你这个时候，有一个定时任务
    /**
     NSDefaultRunLoopMode 当拖动的时候，它会停掉
     因为这种模式是互斥的
     forMode:UITrackingRunLoopMode 只有输入的时候，它才会去执行定时器任务
     
     NSRunLoopCommonModes 包含了前面两种
     
     //[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
     //[[NSRunLoop currentRunLoop] addTimer:timer forMode:UITrackingRunLoopMode];
     */
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    
    // 下载、定时源时间、输入源时间，如果放在子线程里面，如果想要它执行任务，就必须开启子线程的运行循环
    CFRunLoopRun();
    
}

- (void)timeEvent {
    
    NSLog(@"%ld----%@", (long)self.count, [NSThread currentThread]);
    
    if (self.count++ == 10) {
        NSLog(@"---挂了----");
        // 停止当前的运行循环
        CFRunLoopStop(CFRunLoopGetCurrent());
    }
    
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
