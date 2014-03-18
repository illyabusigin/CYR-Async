//
//  CYRDispatchParallelSpecSpec.m
//  GCDAsync
//
//  Created by Illya Busigin on 3/15/14.
//  Copyright 2014 Cyrillian, Inc. All rights reserved.
//

#import <Kiwi/Kiwi.h>
#import "CYR+Async.h"

SPEC_BEGIN(CYRDispatchParallelSpec)

describe(@"dispatch_parallel", ^{

    context(@"while using dispatch_parallel", ^{
        
        context(@"when executing valid tasks", ^{
            
            __block NSError *theError = nil;
            __block NSArray *theResults = nil;
            __block BOOL completionBlockCalled = NO;
            
            beforeAll(^{
                CYRTask task1 = dispatch_task_create(^(CYRCallback callback, void *context) {
                    sleep(2);
                    return callback(nil, @"one");
                });
                
                CYRTask task2 = dispatch_task_create(^(CYRCallback callback, void *context) {
                    sleep(1);
                    return callback(nil, @"two");
                });
                
                CYRTask task3 = dispatch_task_create(^(CYRCallback callback, void *context) {
                    return callback(nil, @"three");
                });
                
                dispatch_parallel(@[task1, task2, task3], ^(NSError *error, NSArray *results) {
                    theError = error;
                    theResults = results;
                    completionBlockCalled = YES;
                });
            });
            
            it(@"should call the completion block", ^{
                [[expectFutureValue(theValue(completionBlockCalled)) shouldEventuallyBeforeTimingOutAfter(5)] equal:theValue(YES)];
            });
            
            it(@"should return a valid results object", ^{
                [[expectFutureValue(theResults) shouldEventuallyBeforeTimingOutAfter(5)] beNonNil];
            });
            
            it(@"should have three result objects", ^{
                [[expectFutureValue(theValue(theResults.count)) shouldEventuallyBeforeTimingOutAfter(5)] equal:theValue(3)];
            });
            
            it(@"the results should be in reverse order due to task processing durations", ^{
                [[expectFutureValue(theResults) shouldEventually] equal:@[@"three", @"two", @"one"]];
            });
        });
    });
    
    context(@"when using dispatch_parallel_limit as a serial queue", ^{
        
       context(@"while executing valid tasks", ^{
           __block NSError *theError = nil;
           __block NSArray *theResults = nil;
           __block BOOL completionBlockCalled = NO;
           
           beforeAll(^{
               CYRTask task1 = dispatch_task_create(^(CYRCallback callback, void *context) {
                   sleep(2);
                   return callback(nil, @"one");
               });
               
               CYRTask task2 = dispatch_task_create(^(CYRCallback callback, void *context) {
                   sleep(1);
                   return callback(nil, @"two");
               });
               
               CYRTask task3 = dispatch_task_create(^(CYRCallback callback, void *context) {
                   return callback(nil, @"three");
               });
               
               dispatch_parallel_limit(@[task1, task2, task3], 1, ^(NSError *error, NSArray *results) {
                   theError = error;
                   theResults = results;
                   completionBlockCalled = YES;
               });
           });
           
           it(@"should call the completion block", ^{
               [[expectFutureValue(theValue(completionBlockCalled)) shouldEventuallyBeforeTimingOutAfter(5)] equal:theValue(YES)];
           });
           
           it(@"should return a valid results object", ^{
               [[expectFutureValue(theResults) shouldEventuallyBeforeTimingOutAfter(5)] beNonNil];
           });
           
           it(@"should have three result objects", ^{
               [[expectFutureValue(theValue(theResults.count)) shouldEventuallyBeforeTimingOutAfter(5)] equal:theValue(3)];
           });
           
           it(@"the results should be in order of task submission", ^{
               [[expectFutureValue(theResults) shouldEventually] equal:@[@"one", @"two", @"three"]];
           });
       });
    });
    
    context(@"when using dispatch_parallel_limit as a concurrent queue", ^{
        
        __block NSError *theError = nil;
        __block NSArray *theResults = nil;
        __block BOOL completionBlockCalled = NO;
        
        beforeAll(^{
            CYRTask task1 = dispatch_task_create(^(CYRCallback callback, void *context) {
                sleep(2);
                return callback(nil, @"one");
            });
            
            CYRTask task2 = dispatch_task_create(^(CYRCallback callback, void *context) {
                sleep(1);
                return callback(nil, @"two");
            });
            
            CYRTask task3 = dispatch_task_create(^(CYRCallback callback, void *context) {
                return callback(nil, @"three");
            });
            
            dispatch_parallel_limit(@[task1, task2, task3], 3, ^(NSError *error, NSArray *results) {
                theError = error;
                theResults = results;
                completionBlockCalled = YES;
            });
        });
        
        it(@"should return the test tasks in the specified order", ^{
            [[expectFutureValue(theResults) shouldEventuallyBeforeTimingOutAfter(5)] equal:@[@"three", @"two", @"one"]];
        });
    });
    
    context(@"when testing a failed task", ^{
        
        __block NSError *theError = nil;
        __block NSArray *theResults = nil;
        __block BOOL completionBlockCalled = NO;
        __block NSInteger completionCallbacks = 0;
        
        CYRTask task1 = dispatch_task_create(^(CYRCallback callback, void *context) {
            sleep(2);
            return callback(nil, @"one");
        });
        
        CYRTask task2 = dispatch_task_create(^(CYRCallback callback, void *context) {
            sleep(1);
            NSError *error = [NSError errorWithDomain:@"kTestDomain" code:100 userInfo:@{}];
            return callback(error, @"two");
        });
        
        CYRTask task3 = dispatch_task_create(^(CYRCallback callback, void *context) {
            return callback(nil, @"three");
        });
        
        dispatch_parallel_limit(@[task1, task2, task3], 3, ^(NSError *error, NSArray *results) {
            theError = error;
            theResults = results;
            completionBlockCalled = YES;
            completionCallbacks++;
        });
        
        it(@"should only return a subset of the input tasks", ^{
            [[expectFutureValue(theResults) shouldEventuallyBeforeTimingOutAfter(5)] equal:@[@"three", @"two"]];
        });
        
        it(@"should only call the completion block once", ^{
            [[expectFutureValue(theValue(completionCallbacks)) shouldEventuallyBeforeTimingOutAfter(5)] equal:theValue(1)];
        });
        
    });
});

SPEC_END
