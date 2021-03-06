//
//  CYRDispatchUntilSpec.m
//  GCDAsync
//
//  Created by Illya Busigin on 3/15/14.
//  Copyright 2014 Cyrillian, Inc. All rights reserved.
//

#import <Kiwi/Kiwi.h>
#import "CYR+Async.h"

SPEC_BEGIN(CYRDispatchUntilSpec)

describe(@"dispatch_until", ^{
    
    context(@"while using dispatch_until", ^{
        
        context(@"when executing a valid task with no error", ^{
            
            __block NSError *theError = nil;
            __block NSArray *theResults = nil;
            __block BOOL completionBlockCalled = NO;
            
            NSTimeInterval testLength = 1;
            __block NSTimeInterval start = [NSDate date].timeIntervalSince1970;
            __block NSTimeInterval duration = 0;
            
            beforeAll(^{
                CYRTask task1 = dispatch_task_create(^(CYRCallback callback, void *context) {
                    return callback(nil, @"one");
                });
                
                dispatch_until(^BOOL{
                    static BOOL pass = NO;
                    static dispatch_once_t onceToken;
                    dispatch_once(&onceToken, ^{
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(testLength * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            pass = YES;
                        });
                        
                    });
                    
                    return pass;
                }, task1, ^(NSError *error, NSArray *results) {
                    completionBlockCalled = YES;
                    theError = error;
                    theResults = results;
                    duration = [NSDate date].timeIntervalSince1970 - start;
                });
            });
            
            it(@"should call the completion block", ^{
                [[expectFutureValue(theValue(completionBlockCalled)) shouldEventuallyBeforeTimingOutAfter(5)] equal:theValue(YES)];
            });
            
            it(@"duration should be greater tha or equal to the test length", ^{
                [[expectFutureValue(theValue(duration)) shouldEventuallyBeforeTimingOutAfter(5)] beGreaterThanOrEqualTo:theValue(1)];
            });
            
            it(@"should have one item in the results array", ^{
                [[expectFutureValue(theValue(theResults.count)) shouldEventuallyBeforeTimingOutAfter(5)] equal:theValue(1)];
            });
        });
        
        context(@"when executing a valid task that throws an error", ^{
            
            __block NSError *theError = nil;
            __block NSArray *theResults = nil;
            __block BOOL completionBlockCalled = NO;
            
            __block NSError *error = [NSError errorWithDomain:@"kTestDomain" code:100 userInfo:@{}];
            
            beforeAll(^{
                CYRTask task1 = dispatch_task_create(^(CYRCallback callback, void *context) {
                    
                    return callback(error, @"one");
                });
                
                dispatch_until(^BOOL{
                    static BOOL pass = NO;
                    
                    return pass;
                }, task1, ^(NSError *error, NSArray *results) {
                    completionBlockCalled = YES;
                    theError = error;
                    theResults = results;
                });
            });
            
            it(@"should call the completion block", ^{
                [[expectFutureValue(theValue(completionBlockCalled)) shouldEventuallyBeforeTimingOutAfter(5)] equal:theValue(YES)];
            });
            
            it(@"should have a valid error object", ^{
                [[expectFutureValue(theError) shouldEventually] equal:error];
            });
            
            it(@"should have one item in the results array", ^{
                [[expectFutureValue(theValue(theResults.count)) shouldEventuallyBeforeTimingOutAfter(5)] equal:theValue(1)];
            });
        });
    });
});

SPEC_END
