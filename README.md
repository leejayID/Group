# GCD 中的线程组 Group

## 前言
本文主要介绍 GCD 中的线程组 Group，不讲 GCD 基础概念知识。如果对 GCD 的基本知识点不是很清楚的话，建议去补充一下。好了，废话不多说，坐稳了，马上就开车了。

## 正文

### 线程组

GCD 为我们提供了 dispatch_group 方法，他有一个组的概念，可以把多个任务归并到一个组内来执行，通过监听组内所有任务的执行情况来做相应处理。

#### 1.线程组内的任务是同步的。

假设我们现在有两个任务，任务 1 和任务 2，任务 1：for 循环 1000 次，任务 2：for 循环 100 次。等到任务 1 和任务 2 都执行完后再执行回调。

上代码。

```objc
// 创建一个group
dispatch_group_t group = dispatch_group_create();
// 创建一个队列：全局队列
dispatch_queue_t queue = dispatch_get_global_queue(0, 0);

// 将任务1添加到 group 中    
dispatch_group_async(group, queue, ^{
   for (int i = 0; i < 1000; i++) {
       NSLog(@"任务1-----%d",i);
   }
});
 
// 将任务2添加到 group 中    
dispatch_group_async(group, queue, ^{
   for (int i = 0; i < 100; i++) {
       NSLog(@"任务2-----%d",i);
   }
});
    
// 任务1和任务2执行结束，回调
dispatch_group_notify(group, queue, ^{
  dispatch_async(dispatch_get_main_queue(), ^{
      NSLog(@"完成任务");
  });
});
```

打印结果

```objc
2016-12-16 12:31:34.723 Group[12091:514693] 任务1-----0
2016-12-16 12:31:34.723 Group[12091:514681] 任务2-----0
2016-12-16 12:31:34.723 Group[12091:514693] 任务1-----1
2016-12-16 12:31:34.723 Group[12091:514681] 任务2-----1
2016-12-16 12:31:34.723 Group[12091:514693] 任务1-----2
2016-12-16 12:31:34.723 Group[12091:514681] 任务2-----2
····
····
····
2016-12-16 12:31:35.105 Group[12091:514693] 任务1-----997
2016-12-16 12:31:35.105 Group[12091:514693] 任务1-----998
2016-12-16 12:31:35.105 Group[12091:514693] 任务1-----999
2016-12-16 12:31:35.106 Group[12091:514347] 完成任务
```
 从打印结果可以看出：
>先并发执行任务 1 和任务 2，任务 2 首先完成，然后任务 1 还在执行，任务 1 执行结束后，再执行回调。

#### 2.线程组内的任务是异步的。

实际开发中我们可能有这样的需求：并发请求多个网络接口，等到所有的接口请求结束之后，我们再来个回调刷新TableView。
这里面有些同学可能会说把前面例子里的任务 1 和 任务 2 改为网络请求就可以了。那好，那我们来试试。

上代码。

```objc
// 创建一个group
dispatch_group_t group = dispatch_group_create();
// 创建一个队列：全局队列
dispatch_queue_t queue = dispatch_get_global_queue(0, 0);

// 将任务1添加到 group 中    
dispatch_group_async(group, queue, ^{
   // 模拟异步网络请求
   dispatch_async(queue, ^{
       for (int i = 0; i < 1000; i++) {
           NSLog(@"任务1-----%d",i);
       }
   });
});
 
// 将任务2添加到 group 中    
dispatch_group_async(group, queue, ^{
   // 模拟异步网络请求
   dispatch_async(queue, ^{
       for (int i = 0; i < 100; i++) {
           NSLog(@"任务2-----%d",i);
       }
   });
});
    
// 任务1和任务2执行结束，回调
dispatch_group_notify(group, queue, ^{
  dispatch_async(dispatch_get_main_queue(), ^{
      NSLog(@"完成任务");
  });
});

```

打印结果

```objc
2016-12-16 13:12:40.541 Group[12636:545117] 任务1-----0
2016-12-16 13:12:40.541 Group[12636:544738] 完成任务
2016-12-16 13:12:40.541 Group[12636:545118] 任务2-----0
2016-12-16 13:12:40.541 Group[12636:545117] 任务1-----1
2016-12-16 13:12:40.541 Group[12636:545118] 任务2-----1
2016-12-16 13:12:40.542 Group[12636:545117] 任务1-----2
2016-12-16 13:12:40.542 Group[12636:545118] 任务2-----2
····
····
····
2016-12-16 13:12:40.876 Group[12636:545117] 任务1-----997
2016-12-16 13:12:40.876 Group[12636:545117] 任务1-----998
2016-12-16 13:12:40.877 Group[12636:545117] 任务1-----999
```
从打印结果可以看出：
>回调并没有等到任务 1 和任务 2 执行完就打印了，怎么跟我们想得不一样呢？

好，那我下面来解释一下。

1. 第一个例子中，任务 1 是同步的任务，任务 2 也是同步的任务。
* 第二个例子中，任务 1 是异步的任务，任务 2 也是异步的任务。

同步和异步的最大区别是：同步是一个一个的执行，会有一个等待。而异步则不是，它不会等待。

因为 dispatch_group_async 里面的任务是异步的，所以任务在执行的时候，它不会去等待 for 循环执行结束，它会直接跳过 dispatch_async 这 block 执行下一句去了，所以 dispatch_group_notify 也会很快就执行。

下面再看下如何去解决这个问题吧。

这边就用到了 dispatch_group_enter 和 dispatch_group_leave。它们两个是成对出现的。dispatch_group_enter 使 group 里正要执行的任务数递增，dispatch_group_leave 则使之递减。所以调用完 dispatch_group_enter 以后，必须有与之对应的 dispatch_group_leave 才行。如果调用 dispatch_group_enter 之后，没有相应的 dispatch_group_leave 操作，那么这一组任务就永远执行不完。在使用时，可以在向队列中添加任务时调用 dispatch_group_enter，在任务执行完成之后合适的地方调用 dispatch_group_leave。

上代码

```objc
// 创建一个group
dispatch_group_t group = dispatch_group_create();
// 创建一个队列：全局队列
dispatch_queue_t queue = dispatch_get_global_queue(0, 0); 

// 进入group    
dispatch_group_enter(group);

// 模拟异步网络请求
dispatch_async(queue, ^{
   
   for (int i = 0; i < 1000; i++) {
       NSLog(@"任务1-----%d",i);
   }
   // 离开group
   dispatch_group_leave(group);
   
});
    
// 进入group     
dispatch_group_enter(group);
    
// 模拟异步网络请求
dispatch_async(queue, ^{
   
   for (int i = 0; i < 100; i++) {
       NSLog(@"任务2-----%d",i);
   }
   // 离开group
   dispatch_group_leave(group);
   
});
    
    
dispatch_group_notify(group, queue, ^{
   dispatch_async(dispatch_get_main_queue(), ^{
       NSLog(@"完成任务");
   });
});
```

打印结果

```objc
2016-12-16 13:15:17.945 Group[12870:559844] 任务1-----0
2016-12-16 13:15:17.945 Group[12870:559831] 任务2-----0
2016-12-16 13:15:17.945 Group[12870:559844] 任务1-----1
2016-12-16 13:15:17.945 Group[12870:559831] 任务2-----1
2016-12-16 13:15:17.945 Group[12870:559844] 任务1-----2
2016-12-16 13:15:17.946 Group[12870:559831] 任务2-----2
····
····
····
2016-12-16 13:15:18.375 Group[12870:559844] 任务1-----997
2016-12-16 13:15:18.376 Group[12870:559844] 任务1-----998
2016-12-16 13:15:18.376 Group[12870:559844] 任务1-----999
2016-12-16 13:15:18.376 Group[12870:559491] 完成任务
```

从打印结果可以看出：
> 和例子一的打印结果一样，OK，问题解决。

其实还有一个方法也可以解决，信号量 dispatch_semaphore。

**什么是信号量？**

引用网友举的一个例子：

以一个停车场的运作为例。简单起见，假设停车场只有三个车位，一开始三个车位都是空的。这时如果同时来了五辆车，看 门人允许其中三辆直接进入，然后放下车拦，剩下的车则必须在入口等待，此后来的车也都不得不在入口处等待。这时，有一辆车离开停车场，看门人得知后，打开 车拦，放入外面的一辆进去，如果又离开两辆，则又可以放入两辆，如此往复。在这个停车场系统中，车位是公共资源，每辆车好比一个线程，看门人起的就是信号量的作用。

抽象的来讲，信号量的特性如下：信号量是一个非负整数（车位数），所有通过它的线程/进程（车辆）都会将该整数减一（通过它当然是为了使用资源），当该整数值为零时，所有试图通过它的线程都将处于等待状态。在信号量上我们定义两种操作： Wait（等待） 和 Release（释放）。当一个线程调用Wait操作时，它要么得到资源然后将信号量减一，要么一直等下去（指放入阻塞队列），直到信号量大于等于一时。Release（释放）实际上是在信号量上执行加操作，对应于车辆离开停车场，该操作之所以叫做“释放”是因为释放了由信号量守护的资源。

在 GCD 中有三个函数是 semaphore 的操作，分别是：

```objc
// 创建一个semaphore
dispatch_semaphore_create(long value);　　　

// 发送一个信号
dispatch_semaphore_signal(dispatch_semaphore_t dsema);　　

// 等待信号　
dispatch_semaphore_wait(dispatch_semaphore_t dsema, dispatch_time_t timeout);　　
```

上代码

```objc
// 创建一个group
dispatch_group_t group = dispatch_group_create();
// 创建一个队列：全局队列
dispatch_queue_t queue = dispatch_get_global_queue(0, 0);

// 创建信号量，并且设置值为0    
dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

// 将任务1添加到 group 中    
dispatch_group_async(group, queue, ^{
   
   // 模拟异步网络请求
   dispatch_async(queue, ^{
       for (int i = 0; i < 1000; i++) {
           NSLog(@"任务1-----%d",i);
       }

        // 每次发送信号则 semaphore 会 +1
       dispatch_semaphore_signal(semaphore);

   });
   // 由于是异步执行的，当 semaphore 等于 0，则会阻塞当前线程，直到执行了 block 的 dispatch_semaphore_signal，semaphore + 1，才会继续执行。
   dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
   
});
 
// 将任务2添加到 group 中        
dispatch_group_async(group, queue, ^{
   
   // 模拟异步网络请求
   dispatch_async(queue, ^{
       for (int i = 0; i < 100; i++) {
           NSLog(@"任务2-----%d",i);
       }
       
       dispatch_semaphore_signal(semaphore);

   });

   dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
});
    
    
dispatch_group_notify(group, queue, ^{
   dispatch_async(dispatch_get_main_queue(), ^{
       NSLog(@"完成任务");
   });
});

```
由于是异步执行的，当 semaphore 等于 0，则会阻塞当前线程，直到执行了 block 的 dispatch_semaphore_signal，semaphore + 1，才会继续执行。这样很好的解决了这个问题。

```objc
2016-12-16 13:18:11.747 Group[13276:586281] 任务1-----0
2016-12-16 13:18:11.747 Group[13276:586296] 任务2-----0
2016-12-16 13:18:11.747 Group[13276:586281] 任务1-----1
2016-12-16 13:18:11.747 Group[13276:586296] 任务2-----1
2016-12-16 13:18:11.747 Group[13276:586281] 任务1-----2
2016-12-16 13:18:11.748 Group[13276:586296] 任务2-----2
····
····
····
2016-12-16 13:18:12.111 Group[13276:586281] 任务1-----997
2016-12-16 13:18:12.111 Group[13276:586281] 任务1-----998
2016-12-16 13:18:12.111 Group[13276:586281] 任务1-----999
2016-12-16 13:18:12.111 Group[13276:585910] 完成任务
```
从打印结果可以看出：
> 和例子一的打印结果还是一样。

## 最后
由于笔者水平有限，文中如果有错误的地方，还望大神指出。或者有更好的方法和建议，我们可以一起交流。

附上本文的所有 demo 下载链接[【GitHub】](https://git.oschina.net/Lee_Jay/RuntimeDemo)，配合 demo 一起看文章，效果会更佳。


