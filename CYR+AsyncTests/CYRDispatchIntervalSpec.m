//
//  CYRDispatchIntervalSpec.m
//  GCDAsync
//
//  Created by Illya Busigin on 3/15/14.
//  Copyright 2014 Cyrillian, Inc. All rights reserved.
//

#import <Kiwi/Kiwi.h>
#import "CYR+Async.h"

SPEC_BEGIN(CYRDispatchIntervalSpec)

describe(@"dispatch_interval and dispatch_forever", ^{

    context(@"while using dispatch_interval", ^{
        
        __block NSError *theError = nil;
        __block NSArray *theResults = nil;
        __block BOOL completionBlockCalled = NO;
        __block NSInteger counter = 0;
        
        NSTimeInterval testInterval = 0.5;
        
        beforeAll(^{
            CYRTask task1 = dispatch_task_create(^(CYRCallback callback, void *context) {
                static NSError *taskError = nil;
                
                static dispatch_once_t onceToken;
                dispatch_once(&onceToken, ^{
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        taskError = [NSError errorWithDomain:@"kTestDomain" code:100 userInfo:@{}];
                    });
                    
                });
                
                counter++;
                
                return callback(taskError, @"one");
            });
            
            dispatch_interval(task1, testInterval, ^(NSError *error, NSArray *results) {
                theResults = results;
                theError = error;
                completionBlockCalled = YES;
            });
        });
        
        it(@"should have called the the completion block", ^{
            [[expectFutureValue(theValue(completionBlockCalled)) shouldEventuallyBeforeTimingOutAfter(5)] beTrue];
        });
        
        it(@"should have executed the task at least four times", ^{
            [[expectFutureValue(theValue(counter)) shouldEventuallyBeforeTimingOutAfter(5)] beGreaterThanOrEqualTo:theValue(4)];
        });
        
        it(@"should return a results object", ^{
            [[expectFutureValue(theResults) shouldEventuallyBeforeTimingOutAfter(5)] beNonNil];
        });
        
        it(@"should should return an empty results object", ^{
            [[expectFutureValue(theValue(theResults.count)) shouldEventually] equal:theValue(1)];
        });
        
        it(@"should return a vaid error object", ^{
            [[expectFutureValue(theError.class) shouldEventuallyBeforeTimingOutAfter(5)] equal:NSError.class];
        });
        
    });
    
    context(@"while using dispatch_interval_limit", ^{
        
    });
    
    context(@"while using dispatch_forever", ^{
        
    });
});

SPEC_END
