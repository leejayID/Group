//
//  ViewController.m
//  Group
//
//  Created by LeeJay on 2016/12/15.
//  Copyright © 2016年 Mob. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self group];
}

- (void)group
{
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
    
    dispatch_group_async(group, queue, ^{
        for (int i = 0; i < 1000; i++) {
            NSLog(@"任务1-----%d",i);
        }
    });
    
    dispatch_group_async(group, queue, ^{
        for (int i = 0; i < 100; i++) {
            NSLog(@"任务2-----%d",i);
        }
    });
    
    dispatch_group_notify(group, queue, ^{
       dispatch_async(dispatch_get_main_queue(), ^{
           NSLog(@"完成任务");
       });
    });
}

- (void)group1
{
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
    
    dispatch_group_async(group, queue, ^{
        
        // 模拟异步网络请求
        dispatch_async(queue, ^{
            for (int i = 0; i < 1000; i++) {
                NSLog(@"任务1-----%d",i);
            }
            
        });
        
    });
    

    dispatch_group_async(group, queue, ^{
        
        // 模拟异步网络请求
        dispatch_async(queue, ^{
            for (int i = 0; i < 100; i++) {
                NSLog(@"任务2-----%d",i);
            }
            
        });
        
    });
    
    
    dispatch_group_notify(group, queue, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"完成任务");
        });
    });

}

- (void)group2
{
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
    
    dispatch_group_enter(group);
    // 模拟异步网络请求
    dispatch_async(queue, ^{
        
        for (int i = 0; i < 1000; i++) {
            NSLog(@"任务1-----%d",i);
        }
        dispatch_group_leave(group);
        
    });
    
    
    dispatch_group_enter(group);
    
    // 模拟异步网络请求
    dispatch_async(queue, ^{
        
        for (int i = 0; i < 100; i++) {
            NSLog(@"任务2-----%d",i);
        }
        
        dispatch_group_leave(group);
        
    });
    
    
    dispatch_group_notify(group, queue, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"完成任务");
        });
    });
}

- (void)group3
{
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

    dispatch_group_async(group, queue, ^{
        
        // 模拟异步网络请求
        dispatch_async(queue, ^{
            for (int i = 0; i < 1000; i++) {
                NSLog(@"任务1-----%d",i);
            }

            dispatch_semaphore_signal(semaphore);

        });
        
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        
    });
    

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
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
