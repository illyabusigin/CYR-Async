//
//  CYR+Async.m
//
//  Created by Illya Busigin on 03/12/2014.
//  Copyright (c) 2014 Cyrillian, Inc.
//
//  Distributed under MIT license.
//  Get the latest version from here:
//
//  https://github.com/illyabusigin/CYR-Async
//
// The MIT License (MIT)
//
// Copyright (c) 2014 Cyrillian, Inc.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
// the Software, and to permit persons to whom the Software is furnished to do so,
// subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "CYR+Async.h"

#pragma mark - Convenience

CYRTask dispatch_task_create(CYRTask task)
{
    return task;
}

#pragma mark - Series

void dispatch_series(NSArray *tasks, CYRCompletion completion)
{
    dispatch_parallel_limit(tasks, 1, completion);
}

#pragma mark - Parallel

void dispatch_parallel(NSArray *tasks, CYRCompletion completion)
{
    dispatch_parallel_limit(tasks, NSIntegerMax, completion);
}

void dispatch_parallel_limit(NSArray *tasks, NSUInteger limit, CYRCompletion completion)
{
    // Setup block variables
    __block NSError *err = nil;
    __block void *ctx = nil;
    __block NSMutableArray *tasksToRun = [NSMutableArray arrayWithArray:tasks];
    __block NSMutableArray *runningTasks = [NSMutableArray arrayWithCapacity:tasks.count];
    __block NSMutableArray *results = [NSMutableArray arrayWithCapacity:tasks.count];
    __block BOOL completionBlockCalled = NO;

    // Create a background processing queue
    dispatch_queue_t taskQueue = dispatch_queue_create("com.cyrillian.dispatch-parallel-limit-task-queue", DISPATCH_QUEUE_CONCURRENT);
    dispatch_queue_t taskProcessingQueue = dispatch_queue_create("com.cyrillian.dispatch-parallel-limit-processing-queue", DISPATCH_QUEUE_CONCURRENT);

    dispatch_async(taskProcessingQueue, ^{
        CYRCallback callback = NULL;
        
        // Instantiate the callback
        callback = ^(NSError *error, void *context)
        {
            // Capture the callback variables
            err = error;
            ctx = context;
            
            if (context && !completionBlockCalled)
            {
                [results addObject:(__bridge id)(context)];
            }
            
            // Decrement the running count
            [runningTasks removeLastObject];
            
            if (runningTasks.count < limit &&
                tasksToRun.count > 0 &&
                err == nil)
            {
                CYRTask task = [tasksToRun firstObject];
                [tasksToRun removeObjectAtIndex:0];
                
                [runningTasks addObject:task];
                
                CYRCallback theCB = (__bridge CYRCallback)(dispatch_queue_get_specific(taskQueue, @"callback"));
                
                dispatch_async(taskQueue, ^{
                    task(theCB, ctx);
                });
            }
            
            if (err || (runningTasks.count == 0 && tasksToRun.count == 0))
            {
                if (completion && !completionBlockCalled)
                {
                    completionBlockCalled = YES;
                    completion(err, results);
                }
            }
        };
        
        dispatch_queue_set_specific(taskQueue, @"callback", (__bridge void *)(callback), NULL);
        
        while (tasksToRun.count > 0 && runningTasks.count < limit && !completionBlockCalled)
        {
            CYRTask task = [tasksToRun firstObject];
            [tasksToRun removeObjectAtIndex:0];
            
            [runningTasks addObject:task];
            dispatch_async(taskQueue, ^{
                task(callback, ctx);
            });
        }
    });
}

#pragma mark - Whilst

void dispatch_whilst(CYRTest test, CYRTask task, CYRCompletion completion)
{
    dispatch_whilst_limit(test, task, NSIntegerMax, completion);
}

void dispatch_whilst_limit(CYRTest test, CYRTask task, NSUInteger limit, CYRCompletion completion)
{
    __block NSError *err = nil;
    __block void *ctx = nil;
    __block NSInteger count = 0;
    __block NSMutableArray *results = [NSMutableArray array];

    // Create a background processing queue
    dispatch_queue_t queue = dispatch_queue_create("com.cyrillian.dispatch-whilst-limit", DISPATCH_QUEUE_CONCURRENT);

    dispatch_async(queue, ^{
        CYRCallback callback = ^(NSError *error, void *context)
        {
            err = error;
            ctx = context;
            
        };
        
        while (test() == YES && count < limit)
        {
            if (err)
            {
                goto Cleanup;
                break;
            }

            
            task(callback, ctx);
            count++;
            
        }
        
    Cleanup:
        if (completion)
        {
            if (ctx)
            {
                [results addObject:(__bridge id)(ctx)];
            }
            
            completion(err, results);
        }
    });
}

#pragma mark - Do Whilst

void dispatch_do_whilst(CYRTask task, CYRTest test, CYRCompletion completion)
{
    dispatch_do_whilst_limit(task, test, NSIntegerMax, completion);
}

void dispatch_do_whilst_limit(CYRTask task, CYRTest test, NSUInteger limit, CYRCompletion completion)
{
    __block NSError *err = nil;
    __block void *ctx = nil;
    __block NSInteger count = 0;
    __block NSMutableArray *results = [NSMutableArray array];

    // Create a background processing queue
    dispatch_queue_t queue = dispatch_queue_create("com.cyrillian.dispatch_do-whilst-limit", DISPATCH_QUEUE_CONCURRENT);

    dispatch_async(queue, ^{
        CYRCallback callback = ^(NSError *error, void *context)
        {
            err = error;
            ctx = context;
            
        };
        
        do {
            if (err)
            {
                goto Cleanup;
                break;
            }
            
            task(callback, ctx);
            count++;
        } while (test() == YES && count < limit);
        
    Cleanup:
        if (completion)
        {
            if (ctx)
            {
                [results addObject:(__bridge id)(ctx)];
            }
            
            completion(err, results);
        }
    });
}

#pragma mark - Until

void dispatch_until(CYRTest test, CYRTask task, CYRCompletion completion)
{
    dispatch_until_limit(test, task, NSIntegerMax, completion);
}

void dispatch_until_limit(CYRTest test, CYRTask task, NSUInteger limit, CYRCompletion completion)
{
    __block NSError *err = nil;
    __block void *ctx = nil;
    __block NSInteger count = 0;
    __block NSMutableArray *results = [NSMutableArray array];

    // Create a background processing queue
    dispatch_queue_t queue = dispatch_queue_create("com.cyrillian.dispatch-whilst-limit", DISPATCH_QUEUE_CONCURRENT);

    dispatch_async(queue, ^{
        CYRCallback callback = ^(NSError *error, void *context)
        {
            err = error;
            ctx = context;
            
        };
        
        while (test() == NO && count < limit)
        {
            if (err)
            {
                goto Cleanup;
                break;
            }
            
            
            task(callback, ctx);
            count++;
            
        }
        
    Cleanup:
        if (completion)
        {
            if (ctx)
            {
                [results addObject:(__bridge id)(ctx)];
            }
            
            completion(err, results);
        }
    });
}

#pragma mark - Do Until

void dispatch_do_until(CYRTask task, CYRTest test, CYRCompletion completion)
{

    dispatch_do_until_limit(task, test, NSIntegerMax, completion);
}

void dispatch_do_until_limit(CYRTask task, CYRTest test, NSUInteger limit, CYRCompletion completion)
{
    __block NSError *err = nil;
    __block void *ctx = nil;
    __block NSInteger count = 0;
    __block NSMutableArray *results = [NSMutableArray array];

    // Create a background processing queue
    dispatch_queue_t queue = dispatch_queue_create("com.cyrillian.dispatch-do-whilst-limit", DISPATCH_QUEUE_CONCURRENT);

    dispatch_async(queue, ^{
        CYRCallback callback = ^(NSError *error, void *context)
        {
            err = error;
            ctx = context;
            
        };
        
        do {
            if (err)
            {
                goto Cleanup;
                break;
            }
            
            task(callback, ctx);
            count++;
        } while (test() == NO && count < limit);
        
    Cleanup:
        if (completion)
        {
            if (ctx)
            {
                [results addObject:(__bridge id)(ctx)];
            }
            
            completion(err, results);
        }
    });
}

#pragma mark - Forever

void dispatch_forever(CYRTask task, CYRCompletion completion)
{
    dispatch_interval_limit(task, 0, NSIntegerMax, completion);
}

#pragma mark - Interval

void dispatch_interval(CYRTask task, NSTimeInterval interval, CYRCompletion completion)
{
    dispatch_interval_limit(task, interval, NSIntegerMax, completion);
}

void dispatch_interval_limit(CYRTask task, NSTimeInterval interval, NSUInteger limit, CYRCompletion completion)
{
    __block NSError *err = nil;
    __block void *ctx = nil;
    __block NSInteger count = 0;
    __block NSMutableArray *results = [NSMutableArray array];

    __block dispatch_semaphore_t semaphore = NULL;
    __block NSDate *lastExecuted = [NSDate date];

    // Create a background processing queue
    dispatch_queue_t queue = dispatch_queue_create("com.cyrillian.dispatch-interval-limit", DISPATCH_QUEUE_CONCURRENT);

    dispatch_async(queue, ^{
        CYRCallback callback = ^(NSError *error, void *context)
        {
            err = error;
            ctx = context;
            
            dispatch_semaphore_signal(semaphore);
        };
        
        while (!err && count < limit)
        {
            NSTimeInterval timeInterval = fabsf([lastExecuted timeIntervalSinceNow]);
            
            if (timeInterval >= interval)
            {
                lastExecuted = [NSDate date];
                
                semaphore = dispatch_semaphore_create(0);
                
                task(callback, ctx);
                count++;
                
                dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            }
        }
        
        if (completion)
        {
            if (ctx)
            {
                [results addObject:(__bridge id)(ctx)];
            }
            
            completion(err, results);
        }
    });
}
